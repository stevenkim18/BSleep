//
//  RecordingListFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RecordingListFeature {
    
    @ObservableState
    struct State: Equatable {
        /// 녹음 목록
        var recordings: [Recording] = []
        
        /// 로딩 상태
        var isLoading = false
        
        /// 에러 메시지
        var errorMessage: String?
        
        /// 선택된 녹음 (재생 sheet용)
        @Presents var playback: PlaybackFeature.State?
    }
    
    enum Action {
        // 라이프사이클
        case onAppear
        
        // 녹음 목록
        case recordingsLoaded([Recording])
        case recordingTapped(Recording)
        
        // 자식 피처
        case playback(PresentationAction<PlaybackFeature.Action>)
        
        // 에러
        case errorOccurred(String)
    }
    
    @Dependency(\.recordingStorageClient) var recordingStorageClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let recordings = try await recordingStorageClient.fetchRecordings()
                        await send(.recordingsLoaded(recordings))
                    } catch {
                        await send(.errorOccurred("녹음 목록을 불러올 수 없습니다."))
                    }
                }
                
            case let .recordingsLoaded(recordings):
                state.isLoading = false
                state.recordings = recordings
                return .none
                
            case let .recordingTapped(recording):
                state.playback = PlaybackFeature.State(recording: recording)
                return .none
                
            case .playback(.presented(.delegate(.dismiss))):
                state.playback = nil
                return .none
                
            case .playback:
                return .none
                
            case let .errorOccurred(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
        .ifLet(\.$playback, action: \.playback) {
            PlaybackFeature()
        }
    }
}
