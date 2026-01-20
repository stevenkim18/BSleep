//
//  RecorderClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies

// MARK: - Interruption Event

/// 오디오 세션 인터럽션 이벤트
enum RecorderInterruptionEvent: Equatable, Sendable {
    /// 인터럽션 시작 (전화, Siri 등)
    case began
    /// 인터럽션 종료
    case ended
}

// MARK: - Protocol

/// 녹음 전용 프로토콜
protocol RecorderClientProtocol: Sendable {
    /// 녹음 시작
    func startRecording(to url: URL) async throws
    
    /// 녹음 중지 및 파일 URL 반환
    func stopRecording() async -> URL?
    
    /// 현재 녹음 중인지 확인
    var isRecording: Bool { get async }
    
    /// 인터럽션 이벤트 스트림
    func interruptionEventStream() -> AsyncStream<RecorderInterruptionEvent>
}

// MARK: - Live Implementation

/// RecorderClientProtocol의 실제 구현체
actor LiveRecorderClient: RecorderClientProtocol {
    
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var interruptionContinuation: AsyncStream<RecorderInterruptionEvent>.Continuation?
    private var interruptionObserver: NSObjectProtocol?
    
    // MARK: - Init / Deinit
    
    init() {
        setupInterruptionObserver()
    }
    
    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        interruptionContinuation?.finish()
    }
    
    // MARK: - Properties
    
    nonisolated var isRecording: Bool {
        get async {
            await _isRecording
        }
    }
    
    private var _isRecording: Bool {
        recorder?.isRecording ?? false
    }
    
    // MARK: - Recording
    
    func startRecording(to url: URL) async throws {
        // 오디오 세션 설정
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        }
        
        // 녹음 설정 (WAV - LinearPCM)
        // WAV 형식은 finalize 없이도 복구 가능하여 앱 비정상 종료 시에도 데이터 보존 가능
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: AudioSettings.sampleRate,
            AVNumberOfChannelsKey: AudioSettings.numberOfChannels,
            AVLinearPCMBitDepthKey: AudioSettings.bitsPerSample,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
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
    
    // MARK: - Interruption Handling
    
    private func setupInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { await self?.handleInterruption(notification) }
        }
    }
    
    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            interruptionContinuation?.yield(.began)
        case .ended:
            interruptionContinuation?.yield(.ended)
        @unknown default:
            break
        }
    }
    
    nonisolated func interruptionEventStream() -> AsyncStream<RecorderInterruptionEvent> {
        AsyncStream { continuation in
            Task { await self.setInterruptionContinuation(continuation) }
        }
    }
    
    private func setInterruptionContinuation(
        _ continuation: AsyncStream<RecorderInterruptionEvent>.Continuation
    ) {
        self.interruptionContinuation = continuation
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

