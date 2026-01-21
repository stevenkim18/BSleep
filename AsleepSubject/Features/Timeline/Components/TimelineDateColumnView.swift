//
//  TimelineDateColumnView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

struct TimelineDateColumnView: View {
    let config: TimelineConfig
    let dates: [Date]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: config.dateColumnWidth, height: config.rowHeight)
                    .background(AppColors.background)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("TimelineDateColumnView") {
    let config = TimelineConfig()
    let dates = (0..<14).compactMap { offset in
        Calendar.current.date(byAdding: .day, value: -offset, to: Date())
    }
    
    TimelineDateColumnView(config: config, dates: dates)
        .background(AppColors.background)
}
#endif
