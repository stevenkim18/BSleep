//
//  AsleepSubjectApp.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct AsleepSubjectApp: App {
    var body: some Scene {
        WindowGroup {
            TimelineView(
                store: Store(initialState: TimelineFeature.State()) {
                    TimelineFeature()
                } withDependencies: {
                    $0.recordingStorageClient = MockRecordingStorageClient(
                        recordings: RecordingEntity.mockRecordings
                    )
                }
            )
        }
    }
}
