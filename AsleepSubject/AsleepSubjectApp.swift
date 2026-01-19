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
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
