//
//  AudioClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies

// MARK: - Protocol

/// 오디오 녹음/재생을 위한 프로토콜
protocol AudioClientProtocol: Sendable {
    /// 마이크 권한 요청
    func requestPermission() async -> Bool
    
    /// 녹음 시작
    func startRecording(to url: URL) async throws
    
    /// 녹음 중지 및 파일 URL 반환
    func stopRecording() async -> URL?
    
    /// 재생 시작
    func startPlayback(url: URL) async throws
    
    /// 재생 중지
    func stopPlayback() async
    
    /// 현재 녹음 중인지 확인
    var isRecording: Bool { get async }
    
    /// 현재 재생 중인지 확인
    var isPlaying: Bool { get async }
}

// MARK: - Live Implementation

/// AudioClientProtocol의 실제 구현체
/// Actor를 사용하여 Thread-safe하게 오디오 상태 관리
actor LiveAudioClient: AudioClientProtocol {
    
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordingURL: URL?
    
    // MARK: - Protocol Properties
    
    nonisolated var isRecording: Bool {
        get async {
            await _isRecording
        }
    }
    
    nonisolated var isPlaying: Bool {
        get async {
            await _isPlaying
        }
    }
    
    // MARK: - Private Computed Properties
    
    private var _isRecording: Bool {
        recorder?.isRecording ?? false
    }
    
    private var _isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    // MARK: - Permission
    
    nonisolated func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
    
    // MARK: - Recording
    
    func startRecording(to url: URL) async throws {
        // MainActor에서 오디오 세션 설정
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
    
    // MARK: - Playback
    
    func startPlayback(url: URL) async throws {
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        }
        
        let newPlayer = try AVAudioPlayer(contentsOf: url)
        newPlayer.play()
        
        self.player = newPlayer
    }
    
    func stopPlayback() async {
        let currentPlayer = player
        player = nil
        
        await MainActor.run {
            currentPlayer?.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}

// MARK: - Dependency Key

private enum AudioClientKey: DependencyKey {
    static let liveValue: any AudioClientProtocol = LiveAudioClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var audioClient: any AudioClientProtocol {
        get { self[AudioClientKey.self] }
        set { self[AudioClientKey.self] = newValue }
    }
}
