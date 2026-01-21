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
    
    // MARK: - Screen
    
    enum Screen: Equatable {
        case splash
        case onboarding
        case permissionDenied
        case main
    }
    
    // MARK: - State
    
    @ObservableState
    struct State {
        var screen: Screen = .splash
        var permissionStatus: PermissionStatus = .notDetermined
        var isSplashComplete = false
        var path = StackState<Path.State>()
        var recording = RecordingFeature.State()
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case scenePhaseChanged(isActive: Bool)
        case splashCompleted
        case determineScreen
        case permissionChecked(PermissionStatus)
        case requestPermissionTapped
        case permissionRequestResult(Bool)
        case openSettingsTapped
        case path(StackActionOf<Path>)
        case navigateToRecordingList
        case navigateToTimeline
        case recording(RecordingFeature.Action)
    }
    
    // MARK: - Path
    
    @Reducer
    enum Path {
        case recordingList(RecordingListFeature)
        case timeline(TimelineFeature)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.liveActivityClient) var liveActivityClient
    @Dependency(\.permissionClient) var permissionClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Body
    
    var body: some ReducerOf<Self> {
        Scope(state: \.recording, action: \.recording) {
            RecordingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { send in
                        await liveActivityClient.endAllExistingActivities()
                        let status = permissionClient.checkMicrophonePermission()
                        await send(.permissionChecked(status))
                    },
                    .run { send in
                        try? await clock.sleep(for: .seconds(1.5))
                        await send(.splashCompleted)
                    }
                )
                
            case .splashCompleted:
                state.isSplashComplete = true
                return .send(.determineScreen)
                
            case .permissionChecked(let status):
                state.permissionStatus = status
                return state.isSplashComplete ? .send(.determineScreen) : .none
                
            case .determineScreen:
                guard state.isSplashComplete else { return .none }
                switch state.permissionStatus {
                case .authorized:
                    state.screen = .main
                case .notDetermined:
                    state.screen = .onboarding
                case .denied:
                    state.screen = .permissionDenied
                }
                return .none
                
            case .scenePhaseChanged(let isActive):
                guard isActive else { return .none }
                if case .permissionDenied = state.screen {
                    return .run { send in
                        let status = permissionClient.checkMicrophonePermission()
                        await send(.permissionChecked(status))
                        await send(.determineScreen)
                    }
                }
                return .none
                
            case .requestPermissionTapped:
                return .run { send in
                    let granted = await permissionClient.requestMicrophonePermission()
                    await send(.permissionRequestResult(granted))
                }
                
            case .permissionRequestResult(let granted):
                if granted {
                    state.screen = .main
                } else {
                    state.screen = .permissionDenied
                }
                return .none
                
            case .openSettingsTapped:
                permissionClient.openSettings()
                return .none
                
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
