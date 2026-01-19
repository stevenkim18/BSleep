//
//  TimelineHeaderAxisView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 시간 헤더 축 뷰 (가로 스크롤과 동기화)
struct TimelineHeaderAxisView: View {
    let config: TimelineConfig
    let scrollOffset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<config.totalHours, id: \.self) { hourOffset in
                    let hour = (config.startHour + hourOffset) % 24
                    
                    // 2시간 간격으로 라벨 표시
                    if hourOffset % 2 == 0 {
                        Text(String(format: "%02d:00", hour))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: config.hourWidth * 2, alignment: .leading)
                    }
                }
            }
            .frame(width: config.totalTimeWidth, height: config.headerHeight)
            .offset(x: -scrollOffset)
        }
        .frame(height: config.headerHeight)
        .clipped()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineHeaderAxisView - 다양한 스크롤 위치") {
    let config = TimelineConfig()
    
    VStack(spacing: 20) {
        VStack(alignment: .leading) {
            Text("스크롤 오프셋: 0 (21:00 시작)")
                .font(.caption)
                .foregroundStyle(.gray)
            TimelineHeaderAxisView(config: config, scrollOffset: 0)
                .border(Color.gray.opacity(0.3))
        }
        
        VStack(alignment: .leading) {
            Text("스크롤 오프셋: 90 (00:00 근처)")
                .font(.caption)
                .foregroundStyle(.gray)
            TimelineHeaderAxisView(config: config, scrollOffset: 90)
                .border(Color.gray.opacity(0.3))
        }
        
        VStack(alignment: .leading) {
            Text("스크롤 오프셋: 300 (06:00 근처)")
                .font(.caption)
                .foregroundStyle(.gray)
            TimelineHeaderAxisView(config: config, scrollOffset: 300)
                .border(Color.gray.opacity(0.3))
        }
    }
    .padding()
    .background(AppColors.background)
}
#endif
