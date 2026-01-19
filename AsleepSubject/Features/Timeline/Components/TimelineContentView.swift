//
//  TimelineContentView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 타임라인 데이터 영역 (가로 스크롤 내부)
struct TimelineContentView: View {
    let config: TimelineConfig
    let dates: [Date]
    let recordingsByDate: [Date: [RecordingEntity]]
    let onRecordingTapped: (RecordingEntity) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
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
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineContentView") {
    let config = TimelineConfig()
    let mockRecordings = RecordingEntity.mockRecordings
    let recordingsByDate = Dictionary(grouping: mockRecordings, by: { $0.sleepDate })
    
    let dates = (0..<14).compactMap { offset in
        Calendar.current.date(byAdding: .day, value: -offset, to: Date())?.startOfDay
    }
    
    ScrollView(.horizontal) {
        TimelineContentView(
            config: config,
            dates: dates,
            recordingsByDate: recordingsByDate,
            onRecordingTapped: { print("Tapped: \($0.fileName)") }
        )
    }
    .background(AppColors.background)
}
#endif
