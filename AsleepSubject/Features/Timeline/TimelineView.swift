//
//  TimelineView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

/// 타임라인 메인 뷰
struct TimelineView: View {
    @Bindable var store: StoreOf<TimelineFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 다크 배경 그라데이션
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                // 콘텐츠
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let errorMessage = store.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    TimelineGraphView(
                        config: store.config,
                        dateRange: store.dateRange,
                        recordingsByDate: store.recordingsByDate,
                        onRecordingTapped: { recording in
                            store.send(.recordingTapped(recording))
                        }
                    )
                }
            }
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $store.selectedRecording) { recording in
                // TODO: 재생 화면으로 이동 (PlaybackView)
                Text("재생 화면: \(recording.fileName)")
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("다시 시도") {
                store.send(.onAppear)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primaryAccent)
        }
        .padding()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineView - Full") {
    TimelineView(
        store: Store(initialState: TimelineFeature.State()) {
            TimelineFeature()
        } withDependencies: {
            $0.recordingStorageClient = MockRecordingStorageClient(
                recordings: RecordingEntity.mockRecordings
            )
        }
    )
}

#Preview("TimelineView - Empty") {
    TimelineView(
        store: Store(initialState: TimelineFeature.State()) {
            TimelineFeature()
        } withDependencies: {
            $0.recordingStorageClient = MockRecordingStorageClient(recordings: [])
        }
    )
}

#Preview("TimelineView - Loading") {
    TimelineView(
        store: Store(
            initialState: TimelineFeature.State(isLoading: true)
        ) {
            // Reducer를 빈 Reduce로 대체하여 onAppear 무시
            EmptyReducer()
        }
    )
}

#Preview("TimelineView - Error") {
    TimelineView(
        store: Store(initialState: TimelineFeature.State()) {
            TimelineFeature()
        } withDependencies: {
            $0.recordingStorageClient = MockRecordingStorageClient(shouldFail: true)
        }
    )
}
#endif

