//
//  RecordingFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import ComposableArchitecture
import Foundation

// MARK: - Cancel ID

private enum RecordingCancelID: Hashable, Sendable {
    case playback
    case stateUpdates
    case interruptionStream
}

@Reducer
struct RecordingFeature {
    
    @ObservableState
    struct State: Equatable {
        // 녹음 상태
        var isRecording = false
        var isPlaying = false
        var isPaused = false
        var permissionGranted: Bool?
        var errorMessage: String?
        
        // 인터럽션 상태
        var isInterrupted = false
        
        // 재생 상태
        var playbackState: PlaybackState?
        
        // 녹음 목록
        var recordings: [RecordingEntity] = []
        var currentlyPlayingID: UUID?
        var isLoadingRecordings = false
    }
    
    enum Action {
        // 라이프사이클
        case onAppear
        case permissionResponse(Bool)
        
        // 녹음
        case recordButtonTapped
        case recordingStarted
        case recordingStopped(URL?)
        
        // 인터럽션
        case interruptionReceived(RecorderInterruptionEvent)
        case autoResumeRecording
        
        // 재생
        case playRecording(RecordingEntity)
        case pauseTapped
        case resumeTapped
        case stopTapped
        case seekTo(TimeInterval)
        case playbackStateUpdated(PlaybackState)
        case playbackFinished
        
        // 녹음 목록
        case loadRecordings
        case recordingsLoaded([RecordingEntity])
        
        // 에러
        case errorOccurred(String)
    }
    
    @Dependency(\.recorderClient) var recorderClient
    @Dependency(\.playerClient) var playerClient
    @Dependency(\.recordingStorageClient) var storageClient
    @Dependency(\.liveActivityClient) var liveActivityClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    // 앱 재시작 시 기존 Live Activity 정리
                    await liveActivityClient.endAllExistingActivities()
                    
                    let granted = await recorderClient.requestPermission()
                    await send(.permissionResponse(granted))
                    await send(.loadRecordings)
                }
                
            case let .permissionResponse(granted):
                state.permissionGranted = granted
                if !granted {
                    state.errorMessage = "마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요."
                }
                return .none
                
            // MARK: - Recording
                
            case .recordButtonTapped:
                guard state.permissionGranted == true else {
                    state.errorMessage = "마이크 권한이 필요합니다."
                    return .none
                }
                
                if state.isRecording {
                    // 녹음 중지
                    return .merge(
                        .cancel(id: RecordingCancelID.interruptionStream),
                        .run { send in
                            let url = await recorderClient.stopRecording()
                            await send(.recordingStopped(url))
                        }
                    )
                } else {
                    // 재생 중이면 먼저 정지
                    let wasPlaying = state.isPlaying
                    state.isPlaying = false
                    state.isPaused = false
                    state.currentlyPlayingID = nil
                    state.playbackState = nil
                    
                    return .run { send in
                        if wasPlaying {
                            await playerClient.stop()
                        }
                        do {
                            let url = try await makeRecordingURL()
                            try await recorderClient.startRecording(to: url)
                            await send(.recordingStarted)
                        } catch {
                            await send(.errorOccurred("녹음을 시작할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                    .cancellable(id: RecordingCancelID.playback, cancelInFlight: true)
                }
                
            case .recordingStarted:
                state.isRecording = true
                state.isInterrupted = false
                state.errorMessage = nil
                // Live Activity 시작 + 인터럽션 스트림 구독
                return .merge(
                    .run { _ in
                        try? await liveActivityClient.startActivity(recordingName: "수면 녹음")
                    },
                    .run { send in
                        for await event in recorderClient.interruptionEventStream() {
                            await send(.interruptionReceived(event))
                        }
                    }
                    .cancellable(id: RecordingCancelID.interruptionStream, cancelInFlight: true)
                )
                
            case .recordingStopped:
                state.isRecording = false
                state.isInterrupted = false
                // Live Activity 종료 + 녹음 목록 갱신
                return .merge(
                    .run { _ in
                        await liveActivityClient.endActivity()
                    },
                    .send(.loadRecordings)
                )
                
            // MARK: - Interruption
                
            case .interruptionReceived(.began):
                guard state.isRecording else { return .none }
                state.isInterrupted = true
                state.isRecording = false
                // 현재 녹음 저장
                return .run { send in
                    _ = await recorderClient.stopRecording()
                    await send(.loadRecordings)
                }
                
            case .interruptionReceived(.ended):
                guard state.isInterrupted else { return .none }
                // 자동으로 새 녹음 시작
                return .send(.autoResumeRecording)
                
            case .autoResumeRecording:
                state.isInterrupted = false
                return .run { send in
                    do {
                        let url = try await makeRecordingURL()
                        try await recorderClient.startRecording(to: url)
                        await send(.recordingStarted)
                    } catch {
                        await send(.errorOccurred("녹음 재개 실패: \(error.localizedDescription)"))
                    }
                }
                
            // MARK: - Playback
                
            case let .playRecording(recording):
                // 이미 재생 중인 파일을 탭하면 정지
                if state.currentlyPlayingID == recording.id {
                    return .send(.stopTapped)
                }
                
                // 다른 파일 재생 시작
                state.isPlaying = true
                state.isPaused = false
                state.currentlyPlayingID = recording.id
                
                return .merge(
                    // 재생 시작 및 완료 감지
                    .run { send in
                        do {
                            await playerClient.stop()
                            try await playerClient.play(url: recording.url)
                            
                            for await event in playerClient.eventStream() {
                                switch event {
                                case .finished, .interrupted:
                                    await send(.playbackFinished)
                                    return
                                }
                            }
                        } catch {
                            await send(.errorOccurred("재생할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                    .cancellable(id: RecordingCancelID.playback, cancelInFlight: true),
                    
                    // 상태 업데이트 구독
                    .run { send in
                        for await playbackState in playerClient.stateStream() {
                            await send(.playbackStateUpdated(playbackState))
                        }
                    }
                    .cancellable(id: RecordingCancelID.stateUpdates, cancelInFlight: true)
                )
                
            case .pauseTapped:
                state.isPaused = true
                return .run { _ in
                    await playerClient.pause()
                }
                
            case .resumeTapped:
                state.isPaused = false
                return .run { _ in
                    await playerClient.resume()
                }
                
            case .stopTapped:
                state.isPlaying = false
                state.isPaused = false
                state.currentlyPlayingID = nil
                state.playbackState = nil
                return .merge(
                    .cancel(id: RecordingCancelID.playback),
                    .cancel(id: RecordingCancelID.stateUpdates),
                    .run { _ in
                        await playerClient.stop()
                    }
                )
                
            case let .seekTo(time):
                return .run { _ in
                    await playerClient.seek(to: time)
                }
                
            case let .playbackStateUpdated(playbackState):
                state.playbackState = playbackState
                state.isPaused = !playbackState.isPlaying && state.isPlaying
                return .none
                
            case .playbackFinished:
                state.isPlaying = false
                state.isPaused = false
                state.currentlyPlayingID = nil
                state.playbackState = nil
                return .merge(
                    .cancel(id: RecordingCancelID.stateUpdates)
                )
                
            // MARK: - Recordings List
                
            case .loadRecordings:
                state.isLoadingRecordings = true
                return .run { send in
                    do {
                        let recordings = try await storageClient.fetchRecordings()
                        await send(.recordingsLoaded(recordings))
                    } catch {
                        await send(.errorOccurred("녹음 목록을 불러올 수 없습니다."))
                    }
                }
                
            case let .recordingsLoaded(recordings):
                state.recordings = recordings
                state.isLoadingRecordings = false
                return .none
                
            // MARK: - Error
                
            case let .errorOccurred(message):
                state.errorMessage = message
                state.isRecording = false
                state.isPlaying = false
                state.isPaused = false
                state.isInterrupted = false
                state.currentlyPlayingID = nil
                state.playbackState = nil
                state.isLoadingRecordings = false
                return .merge(
                    .cancel(id: RecordingCancelID.interruptionStream)
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func makeRecordingURL() throws -> URL {
        guard let documentsPath = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first
        else {
            throw NSError(domain: "Recording", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "recording_\(timestamp).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
}

