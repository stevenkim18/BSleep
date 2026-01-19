//
//  Recording.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import Foundation

/// 녹음 파일 정보를 담는 모델
struct Recording: Equatable, Identifiable {
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
    
    /// 포맷된 재생 시간 문자열 (h:mm:ss 또는 mm:ss)
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Date Extension

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension Recording {
    /// 다양한 케이스의 Mock 녹음 데이터
    static var mockRecordings: [Recording] {
        [
            // Case 1: 일반적인 밤 수면 (7시간)
            .mock(
                daysAgo: 0,
                startHour: 23, startMinute: 30,
                endHour: 6, endMinute: 30
            ),
            
            // Case 2: 늦은 취침 (8시간)
            .mock(
                daysAgo: 1,
                startHour: 22, startMinute: 0,
                endHour: 1, endMinute: 0
            ),
            
            // Case 3: 이른 취침 + 낮잠
            .mock(
                daysAgo: 2,
                startHour: 23, startMinute: 0,
                endHour: 1, endMinute: 30
            ),
            .mock(  // 낮잠
                daysAgo: 2,
                startHour: 14, startMinute: 0,
                endHour: 15, endMinute: 30
            ),
            
            // Case 4: 짧은 수면 (4시간)
            .mock(
                daysAgo: 3,
                startHour: 18, startMinute: 0,
                endHour: 21, endMinute: 0
            ),
            
            // Case 5: 긴 수면 (10시간)
            .mock(
                daysAgo: 4,
                startHour: 22, startMinute: 30,
                endHour: 8, endMinute: 30
            ),
            
            // Case 6: 자정 전후 수면
            .mock(
                daysAgo: 5,
                startHour: 23, startMinute: 45,
                endHour: 7, endMinute: 15
            ),
            
            // Case 7: 새벽 취침
            .mock(
                daysAgo: 6,
                startHour: 3, startMinute: 0,
                endHour: 10, endMinute: 0
            ),
            
            // Case 8-13: 일부 날짜는 녹음 없음 (빈 행 테스트)
            // daysAgo 7, 8, 9, 10, 11, 12 는 데이터 없음
            
            // Case 14: 아주 짧은 낮잠만 (30분)
            .mock(
                daysAgo: 13,
                startHour: 15, startMinute: 0,
                endHour: 15, endMinute: 30
            ),
        ]
    }
    
    /// Mock 녹음 생성 헬퍼
    static func mock(
        daysAgo: Int,
        startHour: Int, startMinute: Int,
        endHour: Int, endMinute: Int
    ) -> Recording {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let baseDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
            fatalError("Failed to calculate base date")
        }
        
        // 시작 시간 계산 (21시 이후면 전날 기준)
        guard var startDate = calendar.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: baseDate
        ) else {
            fatalError("Failed to create start date")
        }
        
        if startHour >= 21 {
            startDate = calendar.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        
        // 종료 시간 계산
        guard var endDate = calendar.date(
            bySettingHour: endHour,
            minute: endMinute,
            second: 0,
            of: baseDate
        ) else {
            fatalError("Failed to create end date")
        }
        
        // 종료가 시작보다 이전이면 다음날
        if endDate <= startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }
        
        return Recording(
            id: UUID(),
            url: URL(fileURLWithPath: "/mock/recording_\(daysAgo).m4a"),
            startedAt: startDate,
            endedAt: endDate
        )
    }
}
#endif
