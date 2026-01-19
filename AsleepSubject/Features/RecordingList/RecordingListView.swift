//
//  RecordingListView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

/// 녹음 목록 화면
struct RecordingListView: View {
    @Bindable var store: StoreOf<RecordingListFeature>
    
    var body: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if let errorMessage = store.errorMessage {
                errorView(message: errorMessage)
            } else if store.recordings.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .navigationTitle("녹음 목록")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.playback, action: \.playback)) { playbackStore in
            PlaybackView(store: playbackStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ProgressView("녹음 목록 불러오는 중...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        ContentUnavailableView(
            "녹음 파일 없음",
            systemImage: "waveform",
            description: Text("녹음 버튼을 눌러 첫 녹음을 시작하세요")
        )
    }
    
    // MARK: - List View
    
    private var listView: some View {
        List(store.recordings) { recording in
            RecordingRow(
                recording: recording,
                isPlaying: false
            ) {
                store.send(.recordingTapped(recording))
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("오류 발생", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("다시 시도") {
                store.send(.onAppear)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - RecordingRow (copied for now, will be moved later)

/// 녹음 파일 목록의 각 행을 표시하는 컴포넌트
struct RecordingRow: View {
    let recording: Recording
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 재생 아이콘
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                // 파일 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.formattedDate)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(recording.fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 재생 시간
                Text(recording.formattedDuration)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With Recordings") {
    NavigationStack {
        RecordingListView(
            store: Store(initialState: RecordingListFeature.State()) {
                RecordingListFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(
                    recordings: Recording.mockRecordings
                )
            }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        RecordingListView(
            store: Store(initialState: RecordingListFeature.State()) {
                RecordingListFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(recordings: [])
            }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        RecordingListView(
            store: Store(
                initialState: RecordingListFeature.State(isLoading: true)
            ) {
                EmptyReducer()
            }
        )
    }
}
#endif
