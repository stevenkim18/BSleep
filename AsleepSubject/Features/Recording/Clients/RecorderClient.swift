//
//  RecorderClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies

// MARK: - Protocol

/// 녹음 전용 프로토콜
protocol RecorderClientProtocol: Sendable {
    /// 마이크 권한 요청
    func requestPermission() async -> Bool
    
    /// 녹음 시작
    func startRecording(to url: URL) async throws
    
    /// 녹음 중지 및 파일 URL 반환
    func stopRecording() async -> URL?
    
    /// 현재 녹음 중인지 확인
    var isRecording: Bool { get async }
}

// MARK: - Live Implementation

/// RecorderClientProtocol의 실제 구현체
actor LiveRecorderClient: RecorderClientProtocol {
    
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    // MARK: - Properties
    
    nonisolated var isRecording: Bool {
        get async {
            await _isRecording
        }
    }
    
    private var _isRecording: Bool {
        recorder?.isRecording ?? false
    }
    
    // MARK: - Permission
    
    nonisolated func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
    
    // MARK: - Recording
    
    func startRecording(to url: URL) async throws {
        // 오디오 세션 설정
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        }
        
        // 녹음 설정
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 레코더 생성 및 시작
        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.record()
        
        self.recorder = newRecorder
        self.recordingURL = url
    }
    
    func stopRecording() async -> URL? {
        let currentRecorder = recorder
        let currentURL = recordingURL
        
        recorder = nil
        recordingURL = nil
        
        await MainActor.run {
            currentRecorder?.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
        
        return currentURL
    }
}

// MARK: - Dependency Key

private enum RecorderClientKey: DependencyKey {
    static let liveValue: any RecorderClientProtocol = LiveRecorderClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var recorderClient: any RecorderClientProtocol {
        get { self[RecorderClientKey.self] }
        set { self[RecorderClientKey.self] = newValue }
    }
}
