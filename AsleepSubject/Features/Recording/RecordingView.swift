//
//  RecordingView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import ComposableArchitecture
import SwiftUI

/// 전체화면 녹음 메인 화면
struct RecordingView: View {
    @Bindable var store: StoreOf<RecordingFeature>
    
    /// 네비게이션 콜백
    var onNavigateToList: (() -> Void)?
    var onNavigateToTimeline: (() -> Void)?
    
    var body: some View {
        ZStack {
            // 배경
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // 녹음 중일 때 은은한 붉은 빛 배경 효과
            if store.isRecording {
                RadialGradient(
                    colors: [Color.red.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
            
            VStack(spacing: 0) {
                // 상단 네비게이션 버튼
                navigationButtons
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                Spacer()
                
                // 중앙: 녹음 상태 표시
                recordingStatusView
                
                Spacer()
                
                // 하단: 녹음 버튼
                recordButton
                    .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(
            item: $store.scope(state: \.destination?.conversion, action: \.destination.conversion)
        ) { conversionStore in
            ConversionView(store: conversionStore)
        }
        .alert(
            "수면 녹음 시작",
            isPresented: Binding(
                get: { store.showStartConfirmation },
                set: { _ in store.send(.startCancelled) }
            )
        ) {
            Button("시작") {
                store.send(.startConfirmed)
            }
            Button("취소", role: .cancel) {
                store.send(.startCancelled)
            }
        } message: {
            Text("녹음 중에는 앱을 종료하지 마세요.\n백그라운드에서도 녹음이 계속됩니다.")
        }
        .alert(
            "저장 공간 부족",
            isPresented: Binding(
                get: { store.showInsufficientStorageAlert },
                set: { _ in store.send(.dismissStorageAlert) }
            )
        ) {
            Button("설정으로 이동") {
                store.send(.openStorageSettingsTapped)
            }
            Button("취소", role: .cancel) {
                store.send(.dismissStorageAlert)
            }
        } message: {
            Text("녹음을 위해 최소 5GB의 저장 공간이 필요합니다.\n설정에서 저장 공간을 확보해주세요.")
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // 목록 버튼
            Button {
                onNavigateToList?()
            } label: {
                Label("목록", systemImage: "list.bullet")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .disabled(store.isRecording)
            .opacity(store.isRecording ? 0.3 : 1)
            
            // 타임라인 버튼
            Button {
                onNavigateToTimeline?()
            } label: {
                Label("타임라인", systemImage: "chart.bar.xaxis")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .disabled(store.isRecording)
            .opacity(store.isRecording ? 0.3 : 1)
            
            Spacer()
        }
    }
    
    // MARK: - Recording Status View
    
    private var recordingStatusView: some View {
        VStack(spacing: 32) {
            // 상태 아이콘
            ZStack {
                // 외부 링
                Circle()
                    .stroke(
                        store.isInterrupted ? Color.orange.opacity(0.3) :
                        store.isRecording ? Color.red.opacity(0.3) :
                        AppColors.primaryAccent.opacity(0.2),
                        lineWidth: 4
                    )
                    .frame(width: 200, height: 200)
                
                // 펄스 애니메이션 (녹음 중, 인터럽트 시 멈춤)
                if store.isRecording && !store.isInterrupted {
                    PulseView()
                } else if store.isInterrupted {
                    // 인터럽트 상태일 때 오렌지 원
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 180, height: 180)
                } else {
                    // 대기 상태일 때 은은한 숨쉬기 효과
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.05))
                        .frame(width: 180, height: 180)
                }
                
                // 중앙 아이콘
                Image(systemName: store.isInterrupted ? "pause.fill" :
                      store.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        store.isInterrupted ? .orange :
                        store.isRecording ? .red :
                        AppColors.primaryAccent
                    )
                    .symbolEffect(.variableColor.iterative, isActive: store.isRecording && !store.isInterrupted)
                    .shadow(color: (store.isInterrupted ? Color.orange :
                                    store.isRecording ? Color.red :
                                    AppColors.primaryAccent).opacity(0.5), radius: 20)
            }
            
            // 상태 텍스트
            VStack(spacing: 12) {
                if store.isInterrupted {
                    Text("인터럽션 발생")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                    
                    Text("잠시 후 자동으로 재개됩니다")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                } else if store.isRecording {
                    Text("녹음 중")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                    
                    // 녹음 시간
                    Text(formatDuration(store.recordingDuration))
                        .font(.system(size: 64, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // 경고 문구
                    Text("녹음 중에는 앱을 종료하지 마세요")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("수면 녹음")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("버튼을 눌러 녹음을 시작하세요")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .animation(.spring(duration: 0.4), value: store.isRecording)
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button {
            store.send(.recordButtonTapped)
        } label: {
            ZStack {
                // 외부 원 (블러 효과 포함)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // 버튼 내부
                if store.isRecording {
                    // 정지 버튼 (사각형)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.gradient)
                        .frame(width: 36, height: 36)
                        .shadow(color: .red.opacity(0.4), radius: 8)
                } else {
                    // 녹음 버튼 (원)
                    Circle()
                        .fill(Color.red.gradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: .red.opacity(0.3), radius: 8)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: store.isRecording)
        .accessibilityLabel(store.isRecording ? "녹음 정지" : "녹음 시작")
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Idle") {
    RecordingView(
        store: Store(initialState: RecordingFeature.State()) {
            EmptyReducer()
        },
        onNavigateToList: {},
        onNavigateToTimeline: {}
    )
}

#Preview("Recording") {
    RecordingView(
        store: Store(
            initialState: RecordingFeature.State(
                isRecording: true,
                recordingDuration: 3723
            )
        ) {
            EmptyReducer()
        },
        onNavigateToList: {},
        onNavigateToTimeline: {}
    )
}

#Preview("Interrupted") {
    RecordingView(
        store: Store(
            initialState: RecordingFeature.State(
                isRecording: true,
                recordingDuration: 1800,
                isInterrupted: true
            )
        ) {
            EmptyReducer()
        },
        onNavigateToList: {},
        onNavigateToTimeline: {}
    )
}
#endif
