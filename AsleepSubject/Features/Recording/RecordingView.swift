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
            backgroundGradient
            
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
        .onAppear {
            store.send(.onAppear)
        }
        .overlay {
            // 에러 메시지
            if let errorMessage = store.errorMessage {
                errorOverlay(message: errorMessage)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: store.isRecording 
                ? [Color.red.opacity(0.1), Color(.systemBackground)]
                : [Color.blue.opacity(0.05), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: store.isRecording)
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
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            .disabled(store.isRecording)
            .opacity(store.isRecording ? 0.5 : 1)
            
            // 타임라인 버튼
            Button {
                onNavigateToTimeline?()
            } label: {
                Label("타임라인", systemImage: "chart.bar.xaxis")
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            .disabled(store.isRecording)
            .opacity(store.isRecording ? 0.5 : 1)
            
            Spacer()
        }
    }
    
    // MARK: - Recording Status View
    
    private var recordingStatusView: some View {
        VStack(spacing: 24) {
            // 상태 아이콘
            ZStack {
                // 외부 링
                Circle()
                    .stroke(store.isRecording ? Color.red.opacity(0.3) : Color.blue.opacity(0.1), lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                // 펄스 애니메이션 (녹음 중)
                if store.isRecording {
                    PulseView()
                }
                
                // 중앙 아이콘
                Image(systemName: store.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(store.isRecording ? .red : .blue)
                    .symbolEffect(.variableColor.iterative, isActive: store.isRecording)
            }
            
            // 상태 텍스트
            VStack(spacing: 8) {
                if store.isRecording {
                    Text("녹음 중")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                    
                    // 녹음 시간
                    Text(formatDuration(store.recordingDuration))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)
                } else if store.isInterrupted {
                    Text("인터럽션 발생")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                    
                    Text("잠시 후 자동으로 재개됩니다")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text("수면 녹음")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("버튼을 눌러 녹음을 시작하세요")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .animation(.easeInOut, value: store.isRecording)
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button {
            store.send(.recordButtonTapped)
        } label: {
            ZStack {
                // 외부 원
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 4)
                    .frame(width: 88, height: 88)
                
                // 내부 버튼
                if store.isRecording {
                    // 정지 버튼 (사각형)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                        .frame(width: 32, height: 32)
                } else {
                    // 녹음 버튼 (원)
                    Circle()
                        .fill(.red)
                        .frame(width: 72, height: 72)
                }
            }
        }
        .disabled(store.permissionGranted == false)
        .opacity(store.permissionGranted == false ? 0.5 : 1)
        .accessibilityLabel(store.isRecording ? "녹음 정지" : "녹음 시작")
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                if store.permissionGranted == false {
                    Button("설정 열기") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                }
                
                Button("닫기") {
                    store.send(.clearError)
                }
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .background(.red.opacity(0.9))
            .cornerRadius(12)
            .padding()
            .padding(.bottom, 100)
        }
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

// MARK: - Pulse Animation View

private struct PulseView: View {
    @State private var animate = false
    
    var body: some View {
        Circle()
            .stroke(Color.red.opacity(0.5), lineWidth: 2)
            .frame(width: 180, height: 180)
            .scaleEffect(animate ? 1.3 : 1.0)
            .opacity(animate ? 0 : 0.8)
            .animation(
                .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Idle") {
    RecordingView(
        store: Store(initialState: RecordingFeature.State(permissionGranted: true)) {
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
                permissionGranted: true,
                recordingDuration: 3723
            )
        ) {
            EmptyReducer()
        },
        onNavigateToList: {},
        onNavigateToTimeline: {}
    )
}

#Preview("No Permission") {
    RecordingView(
        store: Store(
            initialState: RecordingFeature.State(
                permissionGranted: false,
                errorMessage: "마이크 권한이 필요합니다."
            )
        ) {
            EmptyReducer()
        },
        onNavigateToList: {},
        onNavigateToTimeline: {}
    )
}
#endif
