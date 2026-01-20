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
        /// 변환 진행률 (0.0 ~ 1.0)
        var progress: Float = 0
        /// 에러 메시지 (nil이면 에러 없음)
        var error: String? = nil
        /// 변환 완료 여부
        var isCompleted: Bool = false
    }
    
    enum Action: Equatable {
        /// 변환 시작
        case startConversion
        /// 진행률 업데이트
        case progressUpdated(Float)
        /// 변환 완료
        case completed
        /// 변환 실패
        case failed(String)
        /// 재시도 버튼 탭
        case retryTapped
        /// 확인 버튼 탭 (완료 화면에서)
        case confirmTapped
        /// 닫기 버튼 탭 (에러 화면에서)
        case closeTapped
        /// Delegate 액션
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            /// 변환 완료 (M4A URL 전달)
            case conversionCompleted(URL)
            /// 취소됨
            case dismissed
        }
    }
    
    @Dependency(\.audioConverterClient) var audioConverterClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startConversion:
                state.error = nil
                state.progress = 0
                state.isCompleted = false
                
                // 최소 프로그래스 표시 시간 (1.5초)
                let minimumDuration: TimeInterval = 1.5
                
                return .run { [source = state.sourceURL, dest = state.destinationURL] send in
                    let startTime = Date()
                    
                    do {
                        let progressStream = try await audioConverterClient.convert(
                            from: source,
                            to: dest
                        )
                        
                        for await progress in progressStream {
                            await send(.progressUpdated(progress))
                        }
                        
                        // 최소 시간 확보
                        let elapsed = Date().timeIntervalSince(startTime)
                        if elapsed < minimumDuration {
                            let remaining = minimumDuration - elapsed
                            try? await Task.sleep(for: .seconds(remaining))
                        }
                        
                        // 파일 존재 여부로 성공/실패 판단
                        if FileManager.default.fileExists(atPath: dest.path) {
                            // 성공: WAV 파일 삭제
                            try? FileManager.default.removeItem(at: source)
                            await send(.completed)
                        } else {
                            await send(.failed("변환된 파일을 찾을 수 없습니다."))
                        }
                    } catch {
                        await send(.failed(error.localizedDescription))
                    }
                }
                .cancellable(id: ConversionCancelID.conversion, cancelInFlight: true)
                
            case .progressUpdated(let value):
                state.progress = value
                return .none
                
            case .completed:
                state.isCompleted = true
                state.progress = 1.0
                // 완료 화면 표시 (delegate는 confirmTapped에서 전송)
                // 파일 삭제는 Effect에서 이미 처리됨
                return .none
                
            case .failed(let message):
                state.error = message
                return .none
                
            case .retryTapped:
                return .send(.startConversion)
                
            case .confirmTapped:
                // 확인 버튼 탭 → delegate 전송
                return .send(.delegate(.conversionCompleted(state.destinationURL)))
                
            case .closeTapped:
                // 닫기 버튼 탭 → dismissed delegate 전송
                return .send(.delegate(.dismissed))
                
            case .delegate:
                return .none
            }
        }
    }
}
