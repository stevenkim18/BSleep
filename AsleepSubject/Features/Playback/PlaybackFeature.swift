//
//  PlaybackFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import Foundation

// MARK: - Cancel ID

private enum PlaybackCancelID: Hashable, Sendable {
    case playback
    case stateUpdates
}

@Reducer
struct PlaybackFeature {
    
    @ObservableState
    struct State {
        /// 재생할 녹음 파일
        let recording: Recording
        
        /// 재생 상태
        var isPlaying = false
        var isPaused = false
        var playbackState: PlaybackState?
        
        /// 에러 메시지
        var errorMessage: String?
    }
    
    enum Action {
        // 라이프사이클
        case onAppear
        case onDisappear
        
        // 재생 컨트롤
        case playTapped
        case pauseTapped
        case resumeTapped
        case stopTapped
        case seekTo(TimeInterval)
        
        // 상태 업데이트
        case playbackStateUpdated(PlaybackState)
        case playbackFinished
        
        // 에러
        case errorOccurred(String)
        
        // Dismiss
        case dismissTapped
        case delegate(Delegate)
        
        enum Delegate {
            case dismiss
        }
    }
    
    @Dependency(\.playerClient) var playerClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 자동 재생 시작
                return .send(.playTapped)
                
            case .onDisappear:
                // 화면 사라질 때 재생 정지
                return .merge(
                    .cancel(id: PlaybackCancelID.playback),
                    .cancel(id: PlaybackCancelID.stateUpdates),
                    .run { _ in
                        await playerClient.stop()
                    }
                )
                
            case .playTapped:
                guard !state.isPlaying else { return .none }
                
                state.isPlaying = true
                state.isPaused = false
                state.errorMessage = nil
                
                let url = state.recording.url
                
                return .merge(
                    // 재생 시작 및 완료 감지
                    .run { send in
                        do {
                            await playerClient.stop()
                            try await playerClient.play(url: url)
                            
                            for await event in playerClient.eventStream() {
                                switch event {
                                case .finished, .interrupted:
                                    await send(.playbackFinished)
                                    return
                                }
                            }
                        } catch {
                            await send(.errorOccurred("재생할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                    .cancellable(id: PlaybackCancelID.playback, cancelInFlight: true),
                    
                    // 상태 업데이트 구독
                    .run { send in
                        for await playbackState in playerClient.stateStream() {
                            await send(.playbackStateUpdated(playbackState))
                        }
                    }
                    .cancellable(id: PlaybackCancelID.stateUpdates, cancelInFlight: true)
                )
                
            case .pauseTapped:
                state.isPaused = true
                return .run { _ in
                    await playerClient.pause()
                }
                
            case .resumeTapped:
                state.isPaused = false
                return .run { _ in
                    await playerClient.resume()
                }
                
            case .stopTapped:
                state.isPlaying = false
                state.isPaused = false
                state.playbackState = nil
                return .merge(
                    .cancel(id: PlaybackCancelID.playback),
                    .cancel(id: PlaybackCancelID.stateUpdates),
                    .run { _ in
                        await playerClient.stop()
                    }
                )
                
            case let .seekTo(time):
                return .run { _ in
                    await playerClient.seek(to: time)
                }
                
            case let .playbackStateUpdated(playbackState):
                state.playbackState = playbackState
                state.isPaused = !playbackState.isPlaying && state.isPlaying
                return .none
                
            case .playbackFinished:
                state.isPlaying = false
                state.isPaused = false
                state.playbackState = nil
                return .cancel(id: PlaybackCancelID.stateUpdates)
                
            case let .errorOccurred(message):
                state.errorMessage = message
                state.isPlaying = false
                state.isPaused = false
                state.playbackState = nil
                return .merge(
                    .cancel(id: PlaybackCancelID.playback),
                    .cancel(id: PlaybackCancelID.stateUpdates)
                )
                
            case .dismissTapped:
                return .send(.delegate(.dismiss))
                
            case .delegate:
                return .none
            }
        }
    }
}
