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
        
        // 디버그
        #if DEBUG
        case createEmptyWavTapped
        case createIncompleteWavTapped
        case copyBigWavTapped
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
                return .run { _ in
                    await playerClient.stop()
                }
                
            case .playback(.dismiss):
                // Interactive dismiss (swipe down, tap outside) 처리
                // 시트가 닫힐 때 재생 중지
                return .run { _ in
                    await playerClient.stop()
                }
                
            case .playback:
                return .none
                
            case .conversion(.presented(.delegate(.conversionCompleted))):
                state.conversion = nil
                // 목록 새로고침
                return .send(.onAppear)
                
            case .conversion(.presented(.delegate(.fileDeleted))):
                state.conversion = nil
                // 파일 삭제 후 목록 새로고침
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
                
            case .copyBigWavTapped:
                return .run { send in
                    // 프로젝트 루트의 big.wav (시뮬레이터에서만 동작)
                    // 실 기기에서는 Bundle에 포함해야 함
                    #if targetEnvironment(simulator)
                    let projectPath = "/Users/seungwookim/Code/subject/AsleepSubject/AsleepSubject/big.wav"
                    let sourceURL = URL(fileURLWithPath: projectPath)
                    #else
                    guard let sourceURL = Bundle.main.url(forResource: "big", withExtension: "wav") else {
                        print("❌ big.wav not found in bundle")
                        return
                    }
                    #endif
                    
                    guard sourceURL.fileExists else {
                        print("❌ big.wav not found at: \(sourceURL.path)")
                        return
                    }
                    
                    guard let documentsURL = URL.documentsDirectory else {
                        return
                    }
                    
                    let destURL = documentsURL.appendingPathComponent("big_\(Date().timeIntervalSince1970).wav")
                    
                    do {
                        try sourceURL.copyFile(to: destURL)
                        print("✅ Copied big.wav to: \(destURL.path)")
                    } catch {
                        print("❌ Copy failed: \(error)")
                    }
                    
                    await send(.debugFileCreated)
                }
                
            case .debugFileCreated:
                // 목록 새로고침
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

