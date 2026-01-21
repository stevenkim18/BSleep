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
        var isRecording = false
        var recordingDuration: TimeInterval = 0
        var isInterrupted = false
        var meteringSamples: [Float] = []
        var currentRecordingURL: URL? = nil
        var showStartConfirmation = false
        var showInsufficientStorageAlert = false
        @Presents var destination: Destination.State?
    }
    
    // MARK: - Action
    
    enum Action {
        case recordButtonTapped
        case startConfirmed
        case startCancelled
        case recordingStarted(URL)
        case recordingStopped(URL?)
        case storageChecked(Result<Bool, Error>)
        case openStorageSettingsTapped
        case dismissStorageAlert
        case recordingDurationUpdated(TimeInterval)
        case meteringUpdated(Float)
        case interruptionReceived(RecorderInterruptionEvent)
        case autoResumeRecording
        case errorOccurred(String)
        case destination(PresentationAction<Destination.Action>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.recorderClient) var recorderClient
    @Dependency(\.liveActivityClient) var liveActivityClient
    @Dependency(\.appStorageClient) var appStorageClient
    @Dependency(\.permissionClient) var permissionClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Constants
    
    private let minimumRequiredStorage: Int64 = 5 * 1024 * 1024 * 1024
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Recording
                
            case .recordButtonTapped:
                if state.isRecording {
                    return .merge(
                        .cancel(id: RecordingCancelID.interruptionStream),
                        .cancel(id: RecordingCancelID.meteringUpdates),
                        .run { send in
                            let url = await recorderClient.stopRecording()
                            await send(.recordingStopped(url))
                        }
                    )
                } else {
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
                state.showStartConfirmation = true
                return .none
                
            case .storageChecked(.success(false)):
                state.showInsufficientStorageAlert = true
                return .none
                
            case .storageChecked(.failure):
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
                return .run { send in
                    do {
                        let url = try URL.makeRecordingURL()
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
                
                let endActivityEffect: Effect<Action> = .run { _ in
                    await liveActivityClient.endActivity()
                }
                
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
                return .merge(
                    .cancel(id: RecordingCancelID.meteringUpdates),
                    .run { send in
                        _ = await recorderClient.stopRecording()
                    }
                )
                
            case .interruptionReceived(.ended):
                guard state.isInterrupted else { return .none }
                return .send(.autoResumeRecording)
                
            case .autoResumeRecording:
                state.isInterrupted = false
                return .run { send in
                    do {
                        let url = try URL.makeRecordingURL()
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
}
