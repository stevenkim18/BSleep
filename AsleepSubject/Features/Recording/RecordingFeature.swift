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
    case interruptionStream
    case meteringUpdates
}

@Reducer
struct RecordingFeature {
    
    @ObservableState
    struct State: Equatable {
        // 녹음 상태
        var isRecording = false
        var permissionGranted: Bool?
        var errorMessage: String?
        
        // 녹음 시간
        var recordingDuration: TimeInterval = 0
        
        // 인터럽션 상태
        var isInterrupted = false
        
        // 웨이브폼 샘플 (미터링)
        var meteringSamples: [Float] = []
    }
    
    enum Action {
        // 라이프사이클
        case onAppear
        case permissionResponse(Bool)
        
        // 녹음
        case recordButtonTapped
        case recordingStarted
        case recordingStopped(URL?)
        
        // 녹음 시간 업데이트
        case recordingDurationUpdated(TimeInterval)
        case meteringUpdated(Float)
        
        // 인터럽션
        case interruptionReceived(RecorderInterruptionEvent)
        case autoResumeRecording
        
        // 에러
        case errorOccurred(String)
        case clearError
    }
    
    @Dependency(\.recorderClient) var recorderClient
    @Dependency(\.liveActivityClient) var liveActivityClient
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    // 앱 재시작 시 기존 Live Activity 정리
                    await liveActivityClient.endAllExistingActivities()
                    
                    let granted = await recorderClient.requestPermission()
                    await send(.permissionResponse(granted))
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
                        .cancel(id: RecordingCancelID.meteringUpdates),
                        .run { send in
                            let url = await recorderClient.stopRecording()
                            await send(.recordingStopped(url))
                        }
                    )
                } else {
                    // 녹음 시작
                    return .run { send in
                        do {
                            let url = try await makeRecordingURL()
                            try await recorderClient.startRecording(to: url)
                            await send(.recordingStarted)
                        } catch {
                            await send(.errorOccurred("녹음을 시작할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                }
                
            case .recordingStarted:
                state.isRecording = true
                state.isInterrupted = false
                state.errorMessage = nil
                state.recordingDuration = 0
                state.meteringSamples = []
                
                // Live Activity 시작 + 인터럽션 스트림 구독 + 타이머 시작
                return .merge(
                    .run { _ in
                        try? await liveActivityClient.startActivity(recordingName: "수면 녹음")
                    },
                    .run { send in
                        for await event in recorderClient.interruptionEventStream() {
                            await send(.interruptionReceived(event))
                        }
                    }
                    .cancellable(id: RecordingCancelID.interruptionStream, cancelInFlight: true),
                    // 녹음 시간 업데이트 (1초마다)
                    .run { send in
                        var elapsed: TimeInterval = 0
                        for await _ in clock.timer(interval: .seconds(1)) {
                            elapsed += 1
                            await send(.recordingDurationUpdated(elapsed))
                        }
                    }
                    .cancellable(id: RecordingCancelID.meteringUpdates, cancelInFlight: true)
                )
                
            case .recordingStopped:
                state.isRecording = false
                state.isInterrupted = false
                state.recordingDuration = 0
                state.meteringSamples = []
                // Live Activity 종료
                return .run { _ in
                    await liveActivityClient.endActivity()
                }
                
            case let .recordingDurationUpdated(duration):
                state.recordingDuration = duration
                return .none
                
            case let .meteringUpdated(level):
                // 최근 50개 샘플만 유지
                state.meteringSamples.append(level)
                if state.meteringSamples.count > 50 {
                    state.meteringSamples.removeFirst()
                }
                return .none
                
            // MARK: - Interruption
                
            case .interruptionReceived(.began):
                guard state.isRecording else { return .none }
                state.isInterrupted = true
                state.isRecording = false
                // 현재 녹음 저장
                return .merge(
                    .cancel(id: RecordingCancelID.meteringUpdates),
                    .run { send in
                        _ = await recorderClient.stopRecording()
                    }
                )
                
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
                
            // MARK: - Error
                
            case let .errorOccurred(message):
                state.errorMessage = message
                state.isRecording = false
                state.isInterrupted = false
                state.recordingDuration = 0
                state.meteringSamples = []
                return .cancel(id: RecordingCancelID.interruptionStream)
                
            case .clearError:
                state.errorMessage = nil
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
