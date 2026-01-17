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
    let createdAt: Date
    let duration: TimeInterval
    
    /// 파일명 (확장자 포함)
    var fileName: String {
        url.lastPathComponent
    }
    
    /// 포맷된 날짜 문자열
    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// 포맷된 재생 시간 문자열 (mm:ss)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
