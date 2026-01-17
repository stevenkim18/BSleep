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
            RecordingView(
                store: Store(initialState: RecordingFeature.State()) {
                    RecordingFeature()
                }
            )
        }
    }
}
