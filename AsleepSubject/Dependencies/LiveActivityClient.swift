//
//  LiveActivityClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/18/26.
//

import ActivityKit
import Dependencies
import Foundation

// MARK: - Protocol

/// Live Activity 관리 프로토콜
protocol LiveActivityClientProtocol: Sendable {
    /// Live Activity 시작
    func startActivity(recordingName: String) async throws
    
    /// Live Activity 종료
    func endActivity() async
    
    /// 모든 기존 Live Activity 종료 (앱 재시작 시 정리용)
    func endAllExistingActivities() async
}

// MARK: - Live Implementation

/// LiveActivityClientProtocol의 실제 구현체
actor LiveLiveActivityClient: LiveActivityClientProtocol {
    
    private var currentActivity: Activity<RecordingActivityAttributes>?
    
    func startActivity(recordingName: String) async throws {
        // Live Activity 권한 확인
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        // 기존 Activity 종료
        await endAllExistingActivities()
        
        let attributes = RecordingActivityAttributes(recordingName: recordingName)
        let state = RecordingActivityAttributes.ContentState(startedAt: Date())
        
        let content = ActivityContent(state: state, staleDate: nil)
        
        currentActivity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }
    
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let state = activity.content.state
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        
        currentActivity = nil
    }
    
    func endAllExistingActivities() async {
        // 시스템에 등록된 모든 Live Activity 종료
        for activity in Activity<RecordingActivityAttributes>.activities {
            let state = activity.content.state
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}

// MARK: - Dependency Key

private enum LiveActivityClientKey: DependencyKey {
    static let liveValue: any LiveActivityClientProtocol = LiveLiveActivityClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var liveActivityClient: any LiveActivityClientProtocol {
        get { self[LiveActivityClientKey.self] }
        set { self[LiveActivityClientKey.self] = newValue }
    }
}

