//
//  TimelineHeaderView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 상단 시간 축 헤더 뷰
/// - 2시간 간격으로 시간 레이블 표시 (설정 가능)
/// - 각 레이블은 labelSpacing 너비 안에서 중앙 정렬
struct TimelineHeaderView: View {
    let config: TimelineConfig
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(config.timeLabels.enumerated()), id: \.offset) { _, hour in
                Text(String(format: "%02d:00", hour))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: config.labelSpacing, alignment: .center)
            }
        }
        .frame(width: config.totalTimeWidth, height: config.headerHeight)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineHeaderView") {
    TimelineHeaderView(config: TimelineConfig())
        .background(AppColors.background)
}

#Preview("TimelineHeaderView - 1시간 간격") {
    var config = TimelineConfig()
    config.hourInterval = 1
    
    return TimelineHeaderView(config: config)
        .background(AppColors.background)
}
#endif
