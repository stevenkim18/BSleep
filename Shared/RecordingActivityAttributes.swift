//
//  RecordingActivityAttributes.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/18/26.
//

import ActivityKit
import Foundation

/// Live Activity에서 사용할 녹음 상태 속성
struct RecordingActivityAttributes: ActivityAttributes {
    
    /// 동적으로 변하는 상태 (업데이트 가능)
    public struct ContentState: Codable, Hashable {
        /// 녹음 시작 시간 (타이머 표시용)
        var startedAt: Date
    }
    
    /// 고정 속성 (Activity 생성 시 설정, 변경 불가)
    var recordingName: String
}
