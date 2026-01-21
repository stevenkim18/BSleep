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

protocol LiveActivityClientProtocol: Sendable {
    func startActivity(recordingName: String) async throws
    func endActivity() async
    func endAllExistingActivities() async
}

// MARK: - Live Implementation

actor LiveLiveActivityClient: LiveActivityClientProtocol {
    
    private var currentActivity: Activity<RecordingActivityAttributes>?
    
    func startActivity(recordingName: String) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
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
