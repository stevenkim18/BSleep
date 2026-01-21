//
//  PlaybackState.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import Foundation

/// 재생 상태 정보
struct PlaybackState: Equatable, Sendable {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    
    /// 진행률 (0.0 ~ 1.0)
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    /// 포맷된 현재 시간 (mm:ss)
    var formattedCurrentTime: String {
        currentTime.formattedAsMinutesSeconds
    }
    
    /// 포맷된 전체 시간 (mm:ss)
    var formattedDuration: String {
        duration.formattedAsMinutesSeconds
    }
}

/// 재생 이벤트 타입
enum PlaybackEvent: Sendable {
    case finished
    case interrupted
}
