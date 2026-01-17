//
//  RecordingView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import ComposableArchitecture
import SwiftUI

struct RecordingView: View {
    @Bindable var store: StoreOf<RecordingFeature>
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 상태 표시
            statusView
            
            // 녹음 버튼
            recordButton
            
            // 재생 버튼
            playButton
            
            Spacer()
            
            // 에러 메시지
            if let errorMessage = store.errorMessage {
                errorView(message: errorMessage)
            }
        }
        .padding()
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Subviews
    
    private var statusView: some View {
        VStack(spacing: 8) {
            if store.isRecording {
                Circle()
                    .fill(.red)
                    .frame(width: 16, height: 16)
                Text("녹음 중...")
                    .font(.headline)
            } else if store.isPlaying {
                Image(systemName: "waveform")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                Text("재생 중...")
                    .font(.headline)
            } else if store.recordingURL != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("녹음 완료")
                    .font(.headline)
            } else {
                Image(systemName: "mic.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("녹음을 시작하세요")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.default, value: store.isRecording)
        .animation(.default, value: store.isPlaying)
    }
    
    private var recordButton: some View {
        Button {
            store.send(.recordButtonTapped)
        } label: {
            ZStack {
                Circle()
                    .fill(store.isRecording ? .red : .gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if store.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 28, height: 28)
                } else {
                    Circle()
                        .fill(.red)
                        .frame(width: 60, height: 60)
                }
            }
        }
        .disabled(store.permissionGranted == false)
    }
    
    private var playButton: some View {
        Button {
            store.send(.playButtonTapped)
        } label: {
            Image(systemName: store.isPlaying ? "stop.fill" : "play.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(store.recordingURL != nil ? .blue : .gray)
                .clipShape(Circle())
        }
        .disabled(store.recordingURL == nil)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.callout)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            
            if store.permissionGranted == false {
                Button("설정 열기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.callout.bold())
            }
        }
        .padding()
        .background(.red.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    RecordingView(
        store: Store(initialState: RecordingFeature.State()) {
            RecordingFeature()
        }
    )
}
