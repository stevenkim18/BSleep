//
//  TimelineHeaderView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

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
