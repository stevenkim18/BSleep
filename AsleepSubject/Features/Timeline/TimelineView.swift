//
//  TimelineView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

struct TimelineView: View {
    @Bindable var store: StoreOf<TimelineFeature>
    
    @State private var horizontalScrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            if store.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let errorMessage = store.errorMessage {
                errorView(message: errorMessage)
            } else {
                timelineContent
            }
        }
        .navigationTitle("타임 라인")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.playback, action: \.playback)) { playbackStore in
            PlaybackView(store: playbackStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            headerRow
            
            Rectangle()
                .fill(AppColors.timelineGridLine)
                .frame(height: 0.5)
            
            bodyContent
        }
    }
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: store.config.dateColumnWidth, height: store.config.headerHeight)
            
            Rectangle()
                .fill(AppColors.timelineGridLine)
                .frame(width: 0.5, height: store.config.headerHeight)
            
            GeometryReader { _ in
                TimelineHeaderView(config: store.config)
                    .offset(x: -horizontalScrollOffset)
            }
            .frame(height: store.config.headerHeight)
            .clipped()
        }
    }
    
    private var bodyContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                TimelineDateColumnView(
                    config: store.config,
                    dates: store.dateRange
                )
                
                Rectangle()
                    .fill(AppColors.timelineGridLine)
                    .frame(width: 0.5)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    TimelineContentView(
                        config: store.config,
                        dates: store.dateRange,
                        recordingsByDate: store.recordingsByDate,
                        onRecordingTapped: { recording in
                            store.send(.recordingTapped(recording))
                        }
                    )
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.x
                } action: { _, newValue in
                    horizontalScrollOffset = newValue
                }
            }
        }
    }
    
    // MARK: - Error View
    
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
    NavigationStack {
        TimelineView(
            store: Store(initialState: TimelineFeature.State()) {
                TimelineFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(
                    recordings: Recording.mockRecordings
                )
            }
        )
    }
}

#Preview("TimelineView - Empty") {
    NavigationStack {
        TimelineView(
            store: Store(initialState: TimelineFeature.State()) {
                TimelineFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(recordings: [])
            }
        )
    }
}

#Preview("TimelineView - Loading") {
    NavigationStack {
        TimelineView(
            store: Store(
                initialState: TimelineFeature.State(isLoading: true)
            ) {
                EmptyReducer()
            }
        )
    }
}

#Preview("TimelineView - Error") {
    NavigationStack {
        TimelineView(
            store: Store(initialState: TimelineFeature.State()) {
                TimelineFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(shouldFail: true)
            }
        )
    }
}
#endif
