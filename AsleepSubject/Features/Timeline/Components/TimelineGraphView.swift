//
//  TimelineGraphView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 타임라인 그래프 뷰
/// - 세로 스크롤: 14일 날짜 목록
/// - 가로 스크롤: 24시간 시간축
/// - 날짜 컬럼: 가로 스크롤 시 고정 (sticky)
/// - 시간 헤더: 상단 고정, 가로 스크롤과 동기화
struct TimelineGraphView: View {
    let config: TimelineConfig
    let dateRange: [Date]
    let recordingsByDate: [Date: [RecordingEntity]]
    let onRecordingTapped: (RecordingEntity) -> Void
    
    @State private var horizontalScrollOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단: 시간 헤더 (상단 고정 + 가로 스크롤 동기화)
            HStack(spacing: 0) {
                // 빈 공간 (날짜 컬럼 위치)
                Color.clear
                    .frame(width: config.dateColumnWidth, height: config.headerHeight)
                
                // 구분선
                Rectangle()
                    .fill(AppColors.timelineGridLine)
                    .frame(width: 0.5, height: config.headerHeight)
                
                // 시간 헤더 (가로 스크롤 동기화)
                TimelineHeaderAxisView(config: config, scrollOffset: horizontalScrollOffset)
            }
            
            // 구분선
            Rectangle()
                .fill(AppColors.timelineGridLine)
                .frame(height: 0.5)
            
            // 중앙: 세로 스크롤 영역
            ScrollView(.vertical, showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // 날짜 컬럼 (가로 고정, 세로는 함께 스크롤)
                    VStack(spacing: 0) {
                        ForEach(dateRange, id: \.self) { date in
                            Text(formatDate(date))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(width: config.dateColumnWidth, height: config.rowHeight)
                                .background(AppColors.background)
                        }
                    }
                    
                    // 구분선
                    Rectangle()
                        .fill(AppColors.timelineGridLine)
                        .frame(width: 0.5)
                    
                    // 바 영역 (가로 스크롤)
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(dateRange, id: \.self) { date in
                                TimelineRowView(
                                    config: config,
                                    date: date,
                                    recordings: recordingsByDate[date] ?? [],
                                    onRecordingTapped: onRecordingTapped
                                )
                            }
                        }
                        .frame(width: config.totalTimeWidth)
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.x
                    } action: { oldValue, newValue in
                        horizontalScrollOffset = newValue
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 날짜 포맷팅 (요일 월/일)
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E M/d"  // "월 1/19"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineGraphView - 14일 데이터") {
    let config = TimelineConfig()
    let mockRecordings = RecordingEntity.mockRecordings
    
    // 날짜별 그룹핑
    let recordingsByDate = Dictionary(grouping: mockRecordings, by: { $0.sleepDate })
    
    // 14일 범위
    let dateRange = (0..<14).map { offset in
        Calendar.current.date(byAdding: .day, value: -offset, to: Date())!.startOfDay
    }
    
    TimelineGraphView(
        config: config,
        dateRange: dateRange,
        recordingsByDate: recordingsByDate,
        onRecordingTapped: { recording in
            print("Tapped: \(recording.fileName)")
        }
    )
    .frame(height: 600)
    .background(AppColors.background)
}

#Preview("TimelineGraphView - 빈 데이터") {
    let config = TimelineConfig()
    
    let dateRange = (0..<14).map { offset in
        Calendar.current.date(byAdding: .day, value: -offset, to: Date())!.startOfDay
    }
    
    TimelineGraphView(
        config: config,
        dateRange: dateRange,
        recordingsByDate: [:],
        onRecordingTapped: { _ in }
    )
    .frame(height: 600)
    .background(AppColors.background)
}
#endif
