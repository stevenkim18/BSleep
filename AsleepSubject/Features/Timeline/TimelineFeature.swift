//
//  TimelineFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TimelineFeature {
    
    @ObservableState
    struct State: Equatable {
        // MARK: - Data
        
        var recordings: [Recording] = []
        var isLoading = false
        var errorMessage: String?
        @Presents var playback: PlaybackFeature.State?
        
        // MARK: - Config
        
        var config = TimelineConfig()
        
        // MARK: - Computed
        
        var dateRange: [Date] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            return (0..<config.numberOfDays).compactMap { offset in
                calendar.date(byAdding: .day, value: -offset, to: today)
            }
        }
        
        var recordingsByDate: [Date: [Recording]] {
            Dictionary(grouping: recordings, by: { $0.sleepDate })
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case recordingsLoaded([Recording])
        case recordingTapped(Recording)
        case playback(PresentationAction<PlaybackFeature.Action>)
        case errorOccurred(String)
    }
    
    @Dependency(\.recordingStorageClient) var recordingStorageClient
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
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
