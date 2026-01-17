//
//  RecordingFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RecordingFeature {
    
    @ObservableState
    struct State: Equatable {
        var isRecording = false
        var isPlaying = false
        var recordingURL: URL?
        var permissionGranted: Bool?
        var errorMessage: String?
    }
    
    enum Action {
        case onAppear
        case permissionResponse(Bool)
        case recordButtonTapped
        case recordingStarted
        case recordingStopped(URL?)
        case playButtonTapped
        case playbackFinished
        case errorOccurred(String)
    }
    
    @Dependency(\.audioClient) var audioClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let granted = await audioClient.requestPermission()
                    await send(.permissionResponse(granted))
                }
                
            case let .permissionResponse(granted):
                state.permissionGranted = granted
                if !granted {
                    state.errorMessage = "마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요."
                }
                return .none
                
            case .recordButtonTapped:
                // 권한 확인
                guard state.permissionGranted == true else {
                    state.errorMessage = "마이크 권한이 필요합니다."
                    return .none
                }
                
                if state.isRecording {
                    // 녹음 중지
                    return .run { send in
                        let url = await audioClient.stopRecording()
                        await send(.recordingStopped(url))
                    }
                } else {
                    return .run { send in
                        do {
                            let url = try await makeRecordingURL()
                            try await audioClient.startRecording(to: url)
                            await send(.recordingStarted)
                        } catch {
                            await send(.errorOccurred("녹음을 시작할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                }
                
            case .recordingStarted:
                state.isRecording = true
                state.errorMessage = nil
                return .none
                
            case let .recordingStopped(url):
                state.isRecording = false
                state.recordingURL = url
                return .none
                
            case .playButtonTapped:
                guard let url = state.recordingURL else {
                    return .none
                }
                
                if state.isPlaying {
                    // 재생 중지
                    state.isPlaying = false
                    return .run { _ in
                        await audioClient.stopPlayback()
                    }
                } else {
                    // 재생 시작
                    state.isPlaying = true
                    return .run { send in
                        do {
                            try await audioClient.startPlayback(url: url)
                            // TODO: 재생 완료 감지 (Phase 2에서 구현)
                        } catch {
                            await send(.errorOccurred("재생할 수 없습니다: \(error.localizedDescription)"))
                        }
                    }
                }
                
            case .playbackFinished:
                state.isPlaying = false
                return .none
                
            case let .errorOccurred(message):
                state.errorMessage = message
                state.isRecording = false
                state.isPlaying = false
                return .none
            }
        }
    }
    
    // MARK: - Helpers
    
    private func makeRecordingURL() throws-> URL {
        guard let documentsPath = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first
            else {
                throw NSError(domain: "Recording", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
            }
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "recording_\(timestamp).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
}
