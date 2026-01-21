//
//  PlaybackState.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import Foundation

struct PlaybackState: Equatable, Sendable {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        currentTime.formattedAsMinutesSeconds
    }
    
    var formattedDuration: String {
        duration.formattedAsMinutesSeconds
    }
}

enum PlaybackEvent: Sendable {
    case finished
    case interrupted
}
