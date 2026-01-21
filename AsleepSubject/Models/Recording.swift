//
//  Recording.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import Foundation

// MARK: - Recording Model

struct Recording: Equatable, Identifiable, Sendable {
    
    // MARK: - Format
    
    enum Format: String, Codable, Equatable {
        case wav
        case m4a
    }
    
    // MARK: - Properties
    
    let id: UUID
    let url: URL
    let startedAt: Date
    let endedAt: Date
    let format: Format
    
    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
    
    var sleepDate: Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startedAt)
        if hour >= 21 {
            return calendar.date(byAdding: .day, value: 1, to: startedAt)!.startOfDay
        }
        return startedAt.startOfDay
    }
    
    var fileName: String {
        url.lastPathComponent
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd h:mm a"
        return formatter.string(from: startedAt)
    }
    
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
    
    var fileSize: Int64? {
        guard url.fileExists else { return nil }
        return url.fileSize.map { Int64($0) }
    }
    
    var formattedFileSize: String {
        guard let size = fileSize else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
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
    static var mockRecordings: [Recording] {
        [
            .mock(
                daysAgo: 0,
                startHour: 23, startMinute: 30,
                endHour: 6, endMinute: 30
            ),
            
            .mock(
                daysAgo: 1,
                startHour: 22, startMinute: 0,
                endHour: 1, endMinute: 0
            ),
            
            .mock(
                daysAgo: 2,
                startHour: 23, startMinute: 0,
                endHour: 1, endMinute: 30
            ),
            .mock(
                daysAgo: 2,
                startHour: 14, startMinute: 0,
                endHour: 15, endMinute: 30
            ),
            
            .mock(
                daysAgo: 3,
                startHour: 18, startMinute: 0,
                endHour: 21, endMinute: 0
            ),
            
            .mock(
                daysAgo: 4,
                startHour: 22, startMinute: 30,
                endHour: 8, endMinute: 30
            ),
            
            .mock(
                daysAgo: 5,
                startHour: 23, startMinute: 45,
                endHour: 7, endMinute: 15
            ),
            
            .mock(
                daysAgo: 6,
                startHour: 3, startMinute: 0,
                endHour: 10, endMinute: 0
            ),
            
            .mock(
                daysAgo: 13,
                startHour: 15, startMinute: 0,
                endHour: 15, endMinute: 30
            ),
        ]
    }
    
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
        
        guard var endDate = calendar.date(
            bySettingHour: endHour,
            minute: endMinute,
            second: 0,
            of: baseDate
        ) else {
            fatalError("Failed to create end date")
        }
        
        if endDate <= startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }
        
        return Recording(
            id: UUID(),
            url: URL(fileURLWithPath: "/mock/recording_\(daysAgo).m4a"),
            startedAt: startDate,
            endedAt: endDate,
            format: .m4a
        )
    }
}
#endif
