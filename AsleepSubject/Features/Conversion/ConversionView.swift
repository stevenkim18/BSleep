//
//  ConversionView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import ComposableArchitecture
import SwiftUI

/// 오디오 변환 진행 상태를 보여주는 전체 화면 View
struct ConversionView: View {
    @Bindable var store: StoreOf<ConversionFeature>
    
    var body: some View {
        ZStack {
            // 배경
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Phase에 따른 UI
            switch store.phase {
            case .converting(let progress):
                ConvertingLoadingView(progress: progress)
                
            case .conversionFailed(let message):
                ConversionErrorView(
                    message: message,
                    onRecovery: { store.send(.recoveryTapped) },
                    onRetry: { store.send(.retryTapped) },
                    onClose: { store.send(.closeTapped) }
                )
                
            case .recovering:
                RecoveringLoadingView()
                
            case .recoveryCompleted:
                RecoveryCompletedView(
                    onContinue: { store.send(.continueConversionTapped) }
                )
                
            case .recoveryFailed(let message):
                RecoveryErrorView(
                    message: message,
                    onDelete: { store.send(.deleteTapped) },
                    onClose: { store.send(.closeTapped) }
                )
                
            case .completed:
                ConversionCompletedView(
                    onConfirm: { store.send(.confirmTapped) }
                )
            }
        }
        .onAppear {
            store.send(.startConversion)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Converting") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                phase: .converting(progress: 0.45)
            )
        ) {
            EmptyReducer()
        }
    )
}

#Preview("Completed") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                phase: .completed
            )
        ) {
            EmptyReducer()
        }
    )
}
#endif
