//
//  RecordingEntity.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import Foundation

/// 녹음 파일 정보를 담는 엔티티
struct RecordingEntity: Equatable, Identifiable {
    let id: UUID
    let url: URL
    let startedAt: Date
    let endedAt: Date
    
    /// 녹음 길이 (초)
    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
    
    /// 수면 날짜 (21시 기준)
    /// - 21시 이후 시작 → 다음 날로 표시
    /// - 21시 이전 시작 → 당일로 표시
    var sleepDate: Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startedAt)
        if hour >= 21 {
            return calendar.date(byAdding: .day, value: 1, to: startedAt)!.startOfDay
        }
        return startedAt.startOfDay
    }
    
    /// 파일명 (확장자 포함)
    var fileName: String {
        url.lastPathComponent
    }
    
    /// 포맷된 날짜 문자열
    var formattedDate: String {
        startedAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// 포맷된 재생 시간 문자열 (mm:ss)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Date Extension

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
