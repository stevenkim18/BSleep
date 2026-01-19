//
//  AppFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    
    @ObservableState
    struct State {
        /// 네비게이션 경로
        var path = StackState<Path.State>()
        
        /// 녹음 피처 상태
        var recording = RecordingFeature.State()
    }
    
    enum Action {
        // 네비게이션
        case path(StackActionOf<Path>)
        case navigateToRecordingList
        case navigateToTimeline
        
        // 자식 피처
        case recording(RecordingFeature.Action)
    }
    
    @Reducer
    enum Path {
        case recordingList(RecordingListFeature)
        case timeline(TimelineFeature)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.recording, action: \.recording) {
            RecordingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .navigateToRecordingList:
                state.path.append(.recordingList(RecordingListFeature.State()))
                return .none
                
            case .navigateToTimeline:
                state.path.append(.timeline(TimelineFeature.State()))
                return .none
                
            case .path:
                return .none
                
            case .recording:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
