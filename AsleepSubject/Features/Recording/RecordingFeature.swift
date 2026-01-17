//
//  RecordingFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RecordingFeature {
    
    @ObservableState
    struct State: Equatable {
        // 녹음 상태
        var isRecording = false
        var isPlaying = false
        var permissionGranted: Bool?
        var errorMessage: String?
        
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
        
        // 재생
        case playRecording(RecordingEntity)
        case stopPlayback
        case playbackFinished
        
        // 녹음 목록
        case loadRecordings
        case recordingsLoaded([RecordingEntity])
        
        // 에러
        case errorOccurred(String)
    }
    
    @Dependency(\.audioClient) var audioClient
    @Dependency(\.recordingStorageClient) var storageClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let granted = await audioClient.requestPermission()
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
                    return .run { send in
                        let url = await audioClient.stopRecording()
                        await send(.recordingStopped(url))
                    }
                } else {
                    // 재생 중이면 먼저 정지
                    let wasPlaying = state.isPlaying
                    state.isPlaying = false
                    state.currentlyPlayingID = nil
                    
                    return .run { send in
                        if wasPlaying {
                            await audioClient.stopPlayback()
                        }
                        do {
                            let url = try await makeRecordingURL()
                            try await audioClient.startRecording(to: url)
                            await send(.recordingStarted)
                        } catch {
                            await send(.errorOccurred("녹음을 시작할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                }
                
            case .recordingStarted:
                state.isRecording = true
                state.errorMessage = nil
                return .none
                
            case .recordingStopped:
                state.isRecording = false
                // 녹음 완료 후 목록 갱신
                return .send(.loadRecordings)
                
            // MARK: - Playback
                
            case let .playRecording(recording):
                // 이미 재생 중인 파일을 탭하면 정지
                if state.currentlyPlayingID == recording.id {
                    return .send(.stopPlayback)
                }
                
                // 다른 파일 재생 시작
                state.isPlaying = true
                state.currentlyPlayingID = recording.id
                
                return .run { send in
                    do {
                        // 기존 재생 정지
                        await audioClient.stopPlayback()
                        try await audioClient.startPlayback(url: recording.url)
                        // TODO: 재생 완료 감지 (Phase 2에서 구현)
                    } catch {
                        await send(.errorOccurred("재생할 수 없습니다: \(error.localizedDescription)"))
                    }
                }
                
            case .stopPlayback:
                state.isPlaying = false
                state.currentlyPlayingID = nil
                return .run { _ in
                    await audioClient.stopPlayback()
                }
                
            case .playbackFinished:
                state.isPlaying = false
                state.currentlyPlayingID = nil
                return .none
                
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
                state.currentlyPlayingID = nil
                state.isLoadingRecordings = false
                return .none
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
