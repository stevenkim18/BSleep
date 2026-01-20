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
            
            if store.isCompleted {
                // 완료 화면
                completedView
            } else if let error = store.error {
                // 에러 화면
                errorView(message: error)
            } else {
                // 진행률 화면
                progressView
            }
        }
        .onAppear {
            store.send(.startConversion)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 원형 진행률
            CircularProgressView(progress: CGFloat(store.progress))
                .frame(width: 180, height: 180)
            
            // 텍스트
            VStack(spacing: 12) {
                Text("저장 중...")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("\(Int(store.progress * 100))%")
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundStyle(AppColors.primaryAccent)
            }
            
            Spacer()
            
            // 안내 문구
            Text("녹음 파일을 변환하고 있습니다.\n잠시만 기다려주세요.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.bottom, 60)
        }
    }
    
    // MARK: - Completed View
    
    private var completedView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 완료 아이콘
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            
            // 텍스트
            VStack(spacing: 12) {
                Text("변환 완료!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("녹음 파일이 M4A로 변환되었습니다.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            // 확인 버튼
            Button {
                store.send(.confirmTapped)
            } label: {
                Text("확인")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 에러 아이콘
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
            }
            
            // 에러 메시지
            VStack(spacing: 12) {
                Text("변환 실패")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // 버튼들
            VStack(spacing: 12) {
                // 재시도 버튼
                Button {
                    store.send(.retryTapped)
                } label: {
                    Label("다시 시도", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 닫기 버튼
                Button {
                    store.send(.closeTapped)
                } label: {
                    Text("닫기")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Circular Progress View

private struct CircularProgressView: View {
    let progress: CGFloat
    
    private let lineWidth: CGFloat = 12
    
    var body: some View {
        ZStack {
            // 배경 원
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: lineWidth
                )
            
            // 진행률 원
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColors.primaryAccent,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
            
            // 중앙 아이콘
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.primaryAccent)
                .symbolEffect(.variableColor.iterative, isActive: progress < 1.0)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Progress 0%") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                progress: 0
            )
        ) {
            EmptyReducer()
        }
    )
}

#Preview("Progress 45%") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                progress: 0.45
            )
        ) {
            EmptyReducer()
        }
    )
}

#Preview("Progress 100%") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                progress: 1.0,
                isCompleted: true
            )
        ) {
            EmptyReducer()
        }
    )
}

#Preview("Error") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                error: "저장 공간이 부족합니다."
            )
        ) {
            EmptyReducer()
        }
    )
}

/// 진행률 0% → 100% 애니메이션 Preview
/// Reducer에서 타이머로 progressUpdated 액션을 전송
#Preview("Animated 0% → 100%") {
    ConversionView(
        store: Store(
            initialState: ConversionFeature.State(
                sourceURL: URL(fileURLWithPath: "/mock/recording.wav"),
                destinationURL: URL(fileURLWithPath: "/mock/recording.m4a"),
                progress: 0
            )
        ) {
            Reduce { state, action in
                switch action {
                case .startConversion:
                    // 0.1초마다 5%씩 증가하는 Effect 반환
                    return .run { send in
                        for i in 1...20 {
                            try? await Task.sleep(for: .milliseconds(250))
                            await send(.progressUpdated(Float(i) * 0.05))
                        }
                        await send(.completed)
                    }
                case .progressUpdated(let value):
                    state.progress = value
                    return .none
                case .completed:
                    state.isCompleted = true
                    return .none
                default:
                    return .none
                }
            }
        }
    )
}
#endif
