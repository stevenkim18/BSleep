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
        /// WAV 파일 경로
        let sourceURL: URL
        /// M4A 파일 경로
        let destinationURL: URL
        
        /// 현재 진행 단계
        enum Phase: Equatable {
            case converting(progress: Float)    // 변환 중
            case conversionFailed(String)       // 변환 실패
            case recovering                     // 복구 중
            case recoveryCompleted              // 복구 성공 (사용자 확인 대기)
            case recoveryFailed(String)         // 복구 실패
            case completed                      // 완료
        }
        
        var phase: Phase = .converting(progress: 0)
        
        // MARK: - Computed Properties
        
        /// 변환 진행률 (Phase가 converting일 때만 의미 있음)
        var progress: Float {
            if case .converting(let progress) = phase {
                return progress
            }
            return 0
        }
        
        /// 에러 메시지 (변환/복구 실패 시)
        var errorMessage: String? {
            switch phase {
            case .conversionFailed(let message), .recoveryFailed(let message):
                return message
            default:
                return nil
            }
        }
        
        /// 변환 완료 여부
        var isCompleted: Bool {
            phase == .completed
        }
        
        /// 복구 실패 여부
        var isRecoveryFailed: Bool {
            if case .recoveryFailed = phase {
                return true
            }
            return false
        }
    }
    
    enum Action: Equatable {
        // 변환 관련
        case startConversion
        case progressUpdated(Float)
        case conversionCompleted
        case conversionFailed(String)
        case retryTapped
        
        // 복구 관련
        case recoveryTapped
        case recoveryCompleted
        case recoveryFailed(String)
        case continueConversionTapped   // 복구 성공 화면에서 변환 계속
        
        // UI 액션
        case confirmTapped          // 완료 화면에서 확인
        case closeTapped            // 에러 화면에서 닫기
        case deleteTapped           // 복구 실패 시 삭제
        
        // Delegate
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case conversionCompleted(URL)   // 변환 완료 (M4A URL)
            case fileDeleted                // 파일 삭제됨
            case dismissed                  // 취소됨
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
                        
                        // 파일 존재 여부로 성공/실패 판단
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
                // 복구 성공 → 사용자에게 확인 화면 표시
                state.phase = .recoveryCompleted
                return .none
                
            case .continueConversionTapped:
                // 복구 성공 화면에서 변환 계속 버튼 탭
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
                // 파일 삭제
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
    
    /// 로딩 화면 최소 표시 시간
    private static let minimumLoadingDuration: TimeInterval = 1.5
    
    // MARK: - Helper
    
    /// 최소 시간을 보장하면서 작업 수행
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
