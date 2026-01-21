//
//  TimelineBarView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

struct TimelineBarView: View {
    let config: TimelineConfig
    let recording: Recording
    
    // MARK: - Constants
    
    private let fullTextMinWidth: CGFloat = 100
    private let startOnlyMinWidth: CGFloat = 60
    private let minimumBarWidth: CGFloat = 20
    
    var body: some View {
        let xPosition = calculateXPosition()
        let barWidth = calculateBarWidth()
        let displayWidth = max(barWidth, minimumBarWidth)
        
        RoundedRectangle(cornerRadius: 8)
            .fill(AppColors.timelineBarGradient)
            .frame(width: displayWidth, height: config.rowHeight - 8)
            .overlay {
                timeLabel(for: barWidth)
            }
            .offset(x: xPosition)
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func timeLabel(for width: CGFloat) -> some View {
        if width >= fullTextMinWidth {
            HStack {
                Text(formatTime(recording.startedAt))
                Spacer()
                Text(formatTime(recording.endedAt))
            }
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
        } else if width >= startOnlyMinWidth {
            Text(formatTime(recording.startedAt))
                .font(.caption2)
                .foregroundStyle(.white)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateXPosition() -> CGFloat {
        let hoursFromStart = hoursFrom(date: recording.startedAt)
        return CGFloat(hoursFromStart) * config.hourWidth + config.labelSpacing / 2
    }
    
    private func calculateBarWidth() -> CGFloat {
        let durationHours = recording.duration / 3600.0
        return CGFloat(durationHours) * config.hourWidth
    }
    
    private func hoursFrom(date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        var hoursFromStart = Double(hour - config.startHour)
        if hoursFromStart < 0 {
            hoursFromStart += 24
        }
        return hoursFromStart + Double(minute) / 60.0
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineBarView - 다양한 너비") {
    let config = TimelineConfig()
    
    ScrollView(.horizontal) {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("넓은 바 (10시간) → 시작-종료 표시")
                    .font(.caption)
                    .foregroundStyle(.gray)
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear)
                    TimelineBarView(
                        config: config,
                        recording: .mock(daysAgo: 0, startHour: 22, startMinute: 0, endHour: 8, endMinute: 0)
                    )
                }
                .frame(width: config.totalTimeWidth, height: config.rowHeight)
            }
            
            Group {
                Text("중간 바 (2.5시간)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear)
                    TimelineBarView(
                        config: config,
                        recording: .mock(daysAgo: 0, startHour: 0, startMinute: 0, endHour: 2, endMinute: 30)
                    )
                }
                .frame(width: config.totalTimeWidth, height: config.rowHeight)
            }
            
            Group {
                Text("중간 바 (1.5시간)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear)
                    TimelineBarView(
                        config: config,
                        recording: .mock(daysAgo: 0, startHour: 1, startMinute: 0, endHour: 2, endMinute: 30)
                    )
                }
                .frame(width: config.totalTimeWidth, height: config.rowHeight)
            }
            
            Group {
                Text("좁은 바 (1시간) → 텍스트 없음")
                    .font(.caption)
                    .foregroundStyle(.gray)
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear)
                    TimelineBarView(
                        config: config,
                        recording: .mock(daysAgo: 0, startHour: 2, startMinute: 0, endHour: 3, endMinute: 0)
                    )
                }
                .frame(width: config.totalTimeWidth, height: config.rowHeight)
            }
        }
        .padding()
    }
    .background(AppColors.background)
}
#endif
