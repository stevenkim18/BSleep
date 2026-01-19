//
//  TimelineRowView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 한 날짜의 행 뷰 (바 영역만, 날짜 레이블 제외)
struct TimelineRowView: View {
    let config: TimelineConfig
    let date: Date
    let recordings: [RecordingEntity]
    let onRecordingTapped: (RecordingEntity) -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 배경 (그리드 라인)
            Rectangle()
                .fill(Color.clear)
                .frame(height: config.rowHeight)
                .overlay(
                    Rectangle()
                        .stroke(AppColors.timelineGridLine, lineWidth: 0.5)
                )
            
            // 녹음 바들
            ForEach(recordings) { recording in
                TimelineBarView(
                    config: config,
                    recording: recording
                )
                .onTapGesture {
                    onRecordingTapped(recording)
                }
            }
        }
        .frame(width: config.totalTimeWidth, height: config.rowHeight)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineRowView - 빈 행") {
    let config = TimelineConfig()
    
    ScrollView(.horizontal) {
        TimelineRowView(
            config: config,
            date: Date(),
            recordings: [],
            onRecordingTapped: { _ in }
        )
    }
    .background(AppColors.background)
}

#Preview("TimelineRowView - 단일 녹음") {
    let config = TimelineConfig()
    
    ScrollView(.horizontal) {
        TimelineRowView(
            config: config,
            date: Date(),
            recordings: [
                .mock(daysAgo: 0, startHour: 23, startMinute: 30, endHour: 6, endMinute: 30)
            ],
            onRecordingTapped: { recording in
                print("Tapped: \(recording.fileName)")
            }
        )
    }
    .background(AppColors.background)
}

#Preview("TimelineRowView - 밤 + 낮잠") {
    let config = TimelineConfig()
    
    ScrollView(.horizontal) {
        TimelineRowView(
            config: config,
            date: Date(),
            recordings: [
                .mock(daysAgo: 0, startHour: 23, startMinute: 0, endHour: 6, endMinute: 0),
                .mock(daysAgo: 0, startHour: 14, startMinute: 0, endHour: 15, endMinute: 30)
            ],
            onRecordingTapped: { _ in }
        )
    }
    .background(AppColors.background)
}
#endif
