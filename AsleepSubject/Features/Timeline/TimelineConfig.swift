//
//  TimelineConfig.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import Foundation

struct TimelineConfig: Equatable {
    // MARK: - Time Axis
    
    let startHour: Int = 21
    let totalHours: Int = 25
    var hourWidth: CGFloat = 40
    var hourInterval: Int = 1
    
    // MARK: - Layout
    
    let rowHeight: CGFloat = 44
    let dateColumnWidth: CGFloat = 70
    let headerHeight: CGFloat = 32
    
    // MARK: - Days
    
    let numberOfDays: Int = 14
    
    // MARK: - Computed
    
    var totalTimeWidth: CGFloat {
        CGFloat(totalHours) * hourWidth
    }
    
    var labelSpacing: CGFloat {
        CGFloat(hourInterval) * hourWidth
    }
    
    var timeLabels: [Int] {
        stride(from: 0, to: totalHours, by: hourInterval)
            .map { (startHour + $0) % 24 }
    }
}
