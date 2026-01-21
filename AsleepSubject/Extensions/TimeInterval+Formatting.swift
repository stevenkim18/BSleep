//
//  TimeInterval+Formatting.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/22/26.
//

import Foundation

extension TimeInterval {
    
    /// 포맷: "m:ss" (예: "1:05", "45:30")
    var formattedAsMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// 포맷: "mm:ss" (예: "01:05", "45:30")
    var formattedAsPaddedMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 포맷: "h:mm:ss" 또는 "mm:ss" (1시간 미만일 경우)
    /// 녹음 시간 등 긴 시간 표시용
    var formattedAsDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
