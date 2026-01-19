//
//  TimelineBarView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 개별 녹음을 나타내는 바 뷰
/// - 시간 레이블 중앙을 기준으로 위치 계산
struct TimelineBarView: View {
    let config: TimelineConfig
    let recording: RecordingEntity
    
    // MARK: - 텍스트 표시 임계값
    
    /// 시작/종료 시간 모두 표시할 최소 너비
    private let fullTextMinWidth: CGFloat = 100
    /// 시작 시간만 표시할 최소 너비
    private let startOnlyMinWidth: CGFloat = 60
    /// 바 최소 너비
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
    
    /// 바 너비에 따라 적절한 시간 라벨 반환
    @ViewBuilder
    private func timeLabel(for width: CGFloat) -> some View {
        if width >= fullTextMinWidth {
            // 넓은 바: 시작-종료 시간 모두 표시
            HStack {
                Text(formatTime(recording.startedAt))
                Spacer()
                Text(formatTime(recording.endedAt))
            }
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
        } else if width >= startOnlyMinWidth {
            // 중간 바: 시작 시간만 표시
            Text(formatTime(recording.startedAt))
                .font(.caption2)
                .foregroundStyle(.white)
        } else {
            // 좁은 바: 텍스트 없음
            EmptyView()
        }
    }
    
    // MARK: - Private Methods
    
    /// 시작 시간을 X 좌표로 변환
    /// - 시간 레이블의 중앙을 기준으로 계산
    /// - 첫 번째 레이블 "21:00"이 labelSpacing/2 위치에 중앙 정렬되므로 오프셋 추가
    private func calculateXPosition() -> CGFloat {
        let hoursFromStart = hoursFrom(date: recording.startedAt)
        // labelSpacing/2 = 첫 번째 시간 텍스트 중앙 위치
        return CGFloat(hoursFromStart) * config.hourWidth + config.labelSpacing / 2
    }
    
    /// 녹음 시간을 바 너비로 변환
    private func calculateBarWidth() -> CGFloat {
        let durationHours = recording.duration / 3600.0
        return CGFloat(durationHours) * config.hourWidth
    }
    
    /// startHour 기준 경과 시간 계산
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
    
    /// 시간 포맷팅 (HH:mm)
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
            // 넓은 바 (10시간)
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
            
            // 중간 바 (2.5시간)
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
            
            // 중간 바 (1.5시간)
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
            
            // 좁은 바 (1시간)
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
