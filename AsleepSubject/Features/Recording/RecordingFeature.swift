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
    
    // MARK: - Destination
    
    @Reducer
    enum Destination {
        case conversion(ConversionFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    struct State {
        // 녹음 상태
        var isRecording = false
        
        // 녹음 시간
        var recordingDuration: TimeInterval = 0
        
        // 인터럽션 상태
        var isInterrupted = false
        
        // 웨이브폼 샘플 (미터링)
        var meteringSamples: [Float] = []
        
        // 현재 녹음 중인 파일 URL (변환을 위해 저장)
        var currentRecordingURL: URL? = nil
        
        // 녹음 시작 확인 Alert
        var showStartConfirmation = false
        
        // 저장 공간 부족 Alert
        var showInsufficientStorageAlert = false
        
        // Destination
        @Presents var destination: Destination.State?
    }
    
    // MARK: - Action
    
    enum Action {
        // 녹음
        case recordButtonTapped
        case startConfirmed
        case startCancelled
        case recordingStarted(URL)
        case recordingStopped(URL?)
        
        // 저장 공간 확인
        case storageChecked(Result<Bool, Error>)  // true = 충분함
        case openStorageSettingsTapped
        case dismissStorageAlert
        
        // 녹음 시간 업데이트
        case recordingDurationUpdated(TimeInterval)
        case meteringUpdated(Float)
        
        // 인터럽션
        case interruptionReceived(RecorderInterruptionEvent)
        case autoResumeRecording
        
        // 에러
        case errorOccurred(String)
        
        // Destination
        case destination(PresentationAction<Destination.Action>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.recorderClient) var recorderClient
    @Dependency(\.liveActivityClient) var liveActivityClient
    @Dependency(\.appStorageClient) var appStorageClient
    @Dependency(\.permissionClient) var permissionClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Constants
    
    private let minimumRequiredStorage: Int64 = 5 * 1024 * 1024 * 1024  // 5GB
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Recording
                
            case .recordButtonTapped:
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
                    // 저장 공간 확인 후 시작 확인 Alert 표시
                    let minStorage = minimumRequiredStorage
                    return .run { send in
                        do {
                            let available = try await appStorageClient.availableCapacity()
                            let hasSufficientStorage = available >= minStorage
                            await send(.storageChecked(.success(hasSufficientStorage)))
                        } catch {
                            await send(.storageChecked(.failure(error)))
                        }
                    }
                }
                
            case .storageChecked(.success(true)):
                // 저장 공간 충분 → 시작 확인 Alert 표시
                state.showStartConfirmation = true
                return .none
                
            case .storageChecked(.success(false)):
                // 저장 공간 부족 → 부족 Alert 표시
                state.showInsufficientStorageAlert = true
                return .none
                
            case .storageChecked(.failure):
                // 저장 공간 확인 실패 → 그냥 진행 (원활한 UX 위해)
                state.showStartConfirmation = true
                return .none
                
            case .openStorageSettingsTapped:
                state.showInsufficientStorageAlert = false
                return .run { _ in
                    permissionClient.openSettings()
                }
                
            case .dismissStorageAlert:
                state.showInsufficientStorageAlert = false
                return .none
                
            case .startConfirmed:
                state.showStartConfirmation = false
                // 녹음 시작
                return .run { send in
                    do {
                        let url = try await makeRecordingURL()
                        try await recorderClient.startRecording(to: url)
                        await send(.recordingStarted(url))
                    } catch {
                        await send(.errorOccurred("녹음을 시작할 수 없습니다: \(error.localizedDescription)"))
                    }
                }
                
            case .startCancelled:
                state.showStartConfirmation = false
                return .none
                
            case .recordingStarted(let url):
                state.isRecording = true
                state.isInterrupted = false
                state.recordingDuration = 0
                state.meteringSamples = []
                state.currentRecordingURL = url
                
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
                
            case .recordingStopped(let wavURL):
                state.isRecording = false
                state.isInterrupted = false
                state.recordingDuration = 0
                state.meteringSamples = []
                state.currentRecordingURL = nil
                
                // Live Activity 종료
                let endActivityEffect: Effect<Action> = .run { _ in
                    await liveActivityClient.endActivity()
                }
                
                // WAV 파일이 있으면 M4A 변환 시작
                guard let url = wavURL else {
                    return endActivityEffect
                }
                
                let m4aURL = url.deletingPathExtension().appendingPathExtension("m4a")
                state.destination = .conversion(
                    ConversionFeature.State(
                        sourceURL: url,
                        destinationURL: m4aURL
                    )
                )
                
                return endActivityEffect
                
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
                        await send(.recordingStarted(url))
                    } catch {
                        await send(.errorOccurred("녹음 재개 실패: \(error.localizedDescription)"))
                    }
                }
                
            // MARK: - Error
                
            case .errorOccurred:
                state.isRecording = false
                state.isInterrupted = false
                state.recordingDuration = 0
                state.meteringSamples = []
                state.currentRecordingURL = nil
                return .cancel(id: RecordingCancelID.interruptionStream)
                
            // MARK: - Destination
                
            case .destination(.presented(.conversion(.delegate(.conversionCompleted)))):
                // 변환 완료 → destination dismiss
                state.destination = nil
                return .none
                
            case .destination(.presented(.conversion(.delegate(.dismissed)))):
                state.destination = nil
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    // MARK: - Helpers
    
    private func makeRecordingURL() throws -> URL {
        guard let documentsPath = URL.documentsDirectory else {
            throw NSError(domain: "Recording", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "recording_\(timestamp).wav"
        return documentsPath.appendingPathComponent(fileName)
    }
}
