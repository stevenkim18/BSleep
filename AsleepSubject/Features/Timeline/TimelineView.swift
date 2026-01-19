//
//  TimelineView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

/// 타임라인 메인 뷰
/// - 왼쪽 날짜 컬럼: 고정
/// - 오른쪽 데이터 영역: 가로 스크롤
/// - 상단 시간 헤더: 가로 스크롤과 동기화
struct TimelineView: View {
    @Bindable var store: StoreOf<TimelineFeature>
    
    /// 가로 스크롤 오프셋 (헤더 동기화용)
    @State private var horizontalScrollOffset: CGFloat = 0
    
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
                    timelineContent
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
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            // 상단: 시간 헤더
            headerRow
            
            // 구분선
            Rectangle()
                .fill(AppColors.timelineGridLine)
                .frame(height: 0.5)
            
            // 본문: 세로 스크롤
            bodyContent
        }
    }
    
    /// 상단 헤더 행 (빈 공간 + 시간 헤더)
    private var headerRow: some View {
        HStack(spacing: 0) {
            // 빈 공간 (날짜 컬럼 위치)
            Color.clear
                .frame(width: store.config.dateColumnWidth, height: store.config.headerHeight)
            
            // 구분선
            Rectangle()
                .fill(AppColors.timelineGridLine)
                .frame(width: 0.5, height: store.config.headerHeight)
            
            // 시간 헤더 (가로 스크롤 동기화)
            GeometryReader { _ in
                TimelineHeaderView(config: store.config)
                    .offset(x: -horizontalScrollOffset)
            }
            .frame(height: store.config.headerHeight)
            .clipped()
        }
    }
    
    /// 본문 영역 (날짜 컬럼 + 데이터 영역)
    private var bodyContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                // 날짜 컬럼 (고정)
                TimelineDateColumnView(
                    config: store.config,
                    dates: store.dateRange
                )
                
                // 구분선
                Rectangle()
                    .fill(AppColors.timelineGridLine)
                    .frame(width: 0.5)
                
                // 데이터 영역 (가로 스크롤)
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
