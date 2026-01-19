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
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            // 루트: 녹음 화면
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
#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
#endif
