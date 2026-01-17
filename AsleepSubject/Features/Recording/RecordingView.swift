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
        VStack(spacing: 0) {
            // 상단: 녹음 컨트롤
            VStack(spacing: 24) {
                statusView
                recordButton
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // 하단: 녹음 목록
            recordingListView
        }
        .onAppear {
            store.send(.onAppear)
        }
        .overlay {
            // 에러 메시지
            if let errorMessage = store.errorMessage {
                VStack {
                    Spacer()
                    errorView(message: errorMessage)
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Status View
    
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
            } else {
                Image(systemName: "mic.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("녹음을 시작하세요")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.default, value: store.isRecording)
        .animation(.default, value: store.isPlaying)
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button {
            store.send(.recordButtonTapped)
        } label: {
            ZStack {
                Circle()
                    .fill(store.isRecording ? .red : .gray.opacity(0.2))
                    .frame(width: 72, height: 72)
                
                if store.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(.red)
                        .frame(width: 56, height: 56)
                }
            }
        }
        .disabled(store.permissionGranted == false)
    }
    
    // MARK: - Recording List
    
    private var recordingListView: some View {
        Group {
            if store.isLoadingRecordings {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.recordings.isEmpty {
                ContentUnavailableView(
                    "녹음 파일 없음",
                    systemImage: "waveform",
                    description: Text("녹음 버튼을 눌러 첫 녹음을 시작하세요")
                )
            } else {
                List(store.recordings) { recording in
                    RecordingRow(
                        recording: recording,
                        isPlaying: store.currentlyPlayingID == recording.id
                    ) {
                        store.send(.playRecording(recording))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
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
        }
        .padding()
        .background(.red.opacity(0.9))
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
