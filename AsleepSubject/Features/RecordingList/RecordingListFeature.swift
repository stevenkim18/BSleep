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
        /// 녹음 목록
        var recordings: [Recording] = []
        
        /// 로딩 상태
        var isLoading = false
        
        /// 에러 메시지
        var errorMessage: String?
        
        /// 변환 확인 Alert용 (선택된 WAV 파일)
        var wavConversionAlert: Recording? = nil
        
        /// 선택된 녹음 (재생 sheet용)
        @Presents var playback: PlaybackFeature.State?
        
        /// 변환 화면
        @Presents var conversion: ConversionFeature.State?
    }
    
    enum Action {
        // 라이프사이클
        case onAppear
        
        // 녹음 목록
        case recordingsLoaded([Recording])
        case recordingTapped(Recording)
        
        // WAV 변환 Alert
        case confirmConversion
        case cancelConversion
        
        // 자식 피처
        case playback(PresentationAction<PlaybackFeature.Action>)
        case conversion(PresentationAction<ConversionFeature.Action>)
        
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
                if recording.format == .wav {
                    // WAV → Alert 표시
                    state.wavConversionAlert = recording
                    return .none
                } else {
                    // M4A → 재생
                    state.playback = PlaybackFeature.State(recording: recording)
                    return .none
                }
                
            case .confirmConversion:
                guard let recording = state.wavConversionAlert else { return .none }
                state.wavConversionAlert = nil
                
                // 변환 시작
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
                return .none
                
            case .playback:
                return .none
                
            case .conversion(.presented(.delegate(.conversionCompleted))):
                state.conversion = nil
                // 목록 새로고침
                return .send(.onAppear)
                
            case .conversion(.presented(.delegate(.dismissed))):
                state.conversion = nil
                // 목록 새로고침 (변환 실패 후 닫기 시에도)
                return .send(.onAppear)
                
            case .conversion:
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
        .ifLet(\.$conversion, action: \.conversion) {
            ConversionFeature()
        }
    }
}

