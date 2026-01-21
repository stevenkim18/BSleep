//
//  ConversionFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import ComposableArchitecture
import Foundation

// MARK: - Cancel ID

private enum ConversionCancelID: Hashable {
    case conversion
    case recovery
}

// MARK: - Feature

@Reducer
struct ConversionFeature {

    @ObservableState
    struct State: Equatable {
        let sourceURL: URL
        let destinationURL: URL
        
        enum Phase: Equatable {
            case converting(progress: Float)
            case conversionFailed(String)
            case recovering
            case recoveryCompleted
            case recoveryFailed(String)
            case completed
        }
        
        var phase: Phase = .converting(progress: 0)
        
        // MARK: - Computed Properties
        
        var progress: Float {
            if case .converting(let progress) = phase {
                return progress
            }
            return 0
        }
        
        var errorMessage: String? {
            switch phase {
            case .conversionFailed(let message), .recoveryFailed(let message):
                return message
            default:
                return nil
            }
        }
        
        var isCompleted: Bool {
            phase == .completed
        }
        
        var isRecoveryFailed: Bool {
            if case .recoveryFailed = phase {
                return true
            }
            return false
        }
    }
    
    enum Action: Equatable {
        case startConversion
        case progressUpdated(Float)
        case conversionCompleted
        case conversionFailed(String)
        case retryTapped
        case recoveryTapped
        case recoveryCompleted
        case recoveryFailed(String)
        case continueConversionTapped
        case confirmTapped
        case closeTapped
        case deleteTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case conversionCompleted(URL)
            case fileDeleted
            case dismissed
        }
    }
    
    @Dependency(\.audioConverterClient) var audioConverterClient
    @Dependency(\.wavRecoveryClient) var wavRecoveryClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            // MARK: - Conversion
                
            case .startConversion:
                state.phase = .converting(progress: 0)
                
                return .run { [source = state.sourceURL, dest = state.destinationURL] send in
                    do {
                        try await Self.withMinimumDuration {
                            let progressStream = try await audioConverterClient.convert(
                                from: source,
                                to: dest
                            )
                            
                            for await progress in progressStream {
                                await send(.progressUpdated(progress))
                            }
                        }
                        
                        if dest.fileExists {
                            source.removeFileIfExists()
                            await send(.conversionCompleted)
                        } else {
                            await send(.conversionFailed("변환된 파일을 찾을 수 없습니다."))
                        }
                    } catch {
                        await send(.conversionFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: ConversionCancelID.conversion, cancelInFlight: true)
                
            case .progressUpdated(let value):
                state.phase = .converting(progress: value)
                return .none
                
            case .conversionCompleted:
                state.phase = .completed
                return .none
                
            case .conversionFailed(let message):
                state.phase = .conversionFailed(message)
                return .none
                
            case .retryTapped:
                return .send(.startConversion)
                
            // MARK: - Recovery
                
            case .recoveryTapped:
                state.phase = .recovering
                
                return .run { [source = state.sourceURL] send in
                    do {
                        let success = try await Self.withMinimumDuration {
                            try await wavRecoveryClient.recover(fileURL: source)
                        }
                        
                        if success {
                            await send(.recoveryCompleted)
                        } else {
                            await send(.recoveryFailed("복구할 수 없는 파일입니다."))
                        }
                    } catch {
                        await send(.recoveryFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: ConversionCancelID.recovery, cancelInFlight: true)
                
            case .recoveryCompleted:
                state.phase = .recoveryCompleted
                return .none
                
            case .continueConversionTapped:
                return .send(.startConversion)
                
            case .recoveryFailed(let message):
                state.phase = .recoveryFailed(message)
                return .none
                
            // MARK: - UI Actions
                
            case .confirmTapped:
                return .send(.delegate(.conversionCompleted(state.destinationURL)))
                
            case .closeTapped:
                return .send(.delegate(.dismissed))
                
            case .deleteTapped:
                return .run { [source = state.sourceURL] send in
                    source.removeFileIfExists()
                    await send(.delegate(.fileDeleted))
                }
                
            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Constants
    
    private static let minimumLoadingDuration: TimeInterval = 1.5
    
    // MARK: - Helper
    
    private static func withMinimumDuration<T>(
        _ duration: TimeInterval = minimumLoadingDuration,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let startTime = Date()
        let result = try await operation()
        
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < duration {
            let remaining = duration - elapsed
            try? await Task.sleep(for: .seconds(remaining))
        }
        
        return result
    }
}
