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
    struct State {
        var recordings: [Recording] = []
        var isLoading = false
        var errorMessage: String?
        var wavConversionAlert: Recording? = nil
        @Presents var playback: PlaybackFeature.State?
        @Presents var conversion: ConversionFeature.State?
    }
    
    enum Action {
        case onAppear
        case recordingsLoaded([Recording])
        case recordingTapped(Recording)
        case confirmConversion
        case cancelConversion
        case playback(PresentationAction<PlaybackFeature.Action>)
        case conversion(PresentationAction<ConversionFeature.Action>)
        case errorOccurred(String)
        
        #if DEBUG
        case createEmptyWavTapped
        case createIncompleteWavTapped
        case debugFileCreated
        #endif
    }
    
    @Dependency(\.recordingStorageClient) var recordingStorageClient
    @Dependency(\.playerClient) var playerClient
    
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
                if recording.format == .wav {
                    state.wavConversionAlert = recording
                    return .none
                } else {
                    state.playback = PlaybackFeature.State(recording: recording)
                    return .none
                }
                
            case .confirmConversion:
                guard let recording = state.wavConversionAlert else { return .none }
                state.wavConversionAlert = nil
                
                let m4aURL = recording.url.deletingPathExtension().appendingPathExtension("m4a")
                state.conversion = ConversionFeature.State(
                    sourceURL: recording.url,
                    destinationURL: m4aURL
                )
                return .none
                
            case .cancelConversion:
                state.wavConversionAlert = nil
                return .none
                
            case .playback(.presented(.delegate(.dismiss))):
                state.playback = nil
                return .run { _ in
                    await playerClient.stop()
                }
                
            case .playback(.dismiss):
                return .run { _ in
                    await playerClient.stop()
                }
                
            case .playback:
                return .none
                
            case .conversion(.presented(.delegate(.conversionCompleted))):
                state.conversion = nil
                return .send(.onAppear)
                
            case .conversion(.presented(.delegate(.fileDeleted))):
                state.conversion = nil
                return .send(.onAppear)
                
            case .conversion(.presented(.delegate(.dismissed))):
                state.conversion = nil
                return .send(.onAppear)
                
            case .conversion:
                return .none
                
            case let .errorOccurred(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            #if DEBUG
            case .createEmptyWavTapped:
                return .run { send in
                    let client = LiveWavRecoveryClient()
                    _ = try? await client.createEmptyWavForTesting()
                    await send(.debugFileCreated)
                }
                
            case .createIncompleteWavTapped:
                return .run { send in
                    let client = LiveWavRecoveryClient()
                    _ = try? await client.createIncompleteWavForTesting()
                    await send(.debugFileCreated)
                }
                

                
            case .debugFileCreated:
                return .send(.onAppear)
            #endif
            }
        }
        .ifLet(\.$playback, action: \.playback) {
            PlaybackFeature()
        }
        .ifLet(\.$conversion, action: \.conversion) {
            ConversionFeature()
        }
    }
}
