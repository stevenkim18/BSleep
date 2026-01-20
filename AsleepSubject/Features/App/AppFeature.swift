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
    struct State: Equatable {
        var screen: Screen = .splash
        var permissionStatus: PermissionStatus = .notDetermined
        var isSplashComplete = false
        
        /// 네비게이션 경로
        var path = StackState<Path.State>()
        
        /// 녹음 피처 상태
        var recording = RecordingFeature.State()
    }
    
    // MARK: - Action
    
    enum Action {
        // 라이프사이클
        case onAppear
        case scenePhaseChanged(isActive: Bool)
        
        // 스플래시
        case splashCompleted
        case determineScreen
        
        // 권한 관련
        case permissionChecked(PermissionStatus)
        case requestPermissionTapped
        case permissionRequestResult(Bool)
        case openSettingsTapped
        
        // 네비게이션
        case path(StackActionOf<Path>)
        case navigateToRecordingList
        case navigateToTimeline
        
        // 자식 피처
        case recording(RecordingFeature.Action)
    }
    
    // MARK: - Path
    
    @Reducer(state: .equatable)
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
                // 스플래시 중 권한 확인 + 타이머 병렬 실행
                return .merge(
                    // Live Activity 정리 + 권한 확인
                    .run { send in
                        await liveActivityClient.endAllExistingActivities()
                        let status = permissionClient.checkMicrophonePermission()
                        await send(.permissionChecked(status))
                    },
                    // 1.5초 타이머
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
                // 스플래시가 이미 완료된 경우에만 화면 결정
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
                // 설정에서 돌아왔을 때 권한 재확인
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
