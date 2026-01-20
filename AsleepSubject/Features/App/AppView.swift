//
//  AppView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

/// 앱 루트 뷰 (NavigationStack 컨테이너)
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            switch store.screen {
            case .splash:
                SplashView()
                    .transition(.opacity)
                
            case .onboarding:
                OnboardingView {
                    store.send(.requestPermissionTapped)
                }
                .transition(.opacity)
                
            case .permissionDenied:
                PermissionDeniedView {
                    store.send(.openSettingsTapped)
                }
                .transition(.opacity)
                
            case .main:
                mainView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: store.screen)
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(isActive: newPhase == .active))
        }
    }
    
    // MARK: - Main View
    
    private var mainView: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            RecordingView(
                store: store.scope(state: \.recording, action: \.recording),
                onNavigateToList: { store.send(.navigateToRecordingList) },
                onNavigateToTimeline: { store.send(.navigateToTimeline) }
            )
        } destination: { store in
            switch store.case {
            case let .recordingList(recordingListStore):
                RecordingListView(store: recordingListStore)
                
            case let .timeline(timelineStore):
                TimelineView(store: timelineStore)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Splash") {
    AppView(
        store: Store(initialState: AppFeature.State(screen: .splash)) {
            AppFeature()
        }
    )
}

#Preview("Onboarding") {
    AppView(
        store: Store(initialState: AppFeature.State(screen: .onboarding)) {
            AppFeature()
        }
    )
}

#Preview("Permission Denied") {
    AppView(
        store: Store(initialState: AppFeature.State(screen: .permissionDenied)) {
            AppFeature()
        }
    )
}

#Preview("Main") {
    AppView(
        store: Store(initialState: AppFeature.State(screen: .main)) {
            AppFeature()
        }
    )
}
#endif

