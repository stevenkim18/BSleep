//
//  RecorderClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies

// MARK: - Interruption Event

enum RecorderInterruptionEvent: Equatable, Sendable {
    case began
    case ended
}

// MARK: - Protocol

protocol RecorderClientProtocol: Sendable {
    func startRecording(to url: URL) async throws
    func stopRecording() async -> URL?
    var isRecording: Bool { get async }
    func interruptionEventStream() -> AsyncStream<RecorderInterruptionEvent>
}

// MARK: - Live Implementation

actor LiveRecorderClient: RecorderClientProtocol {
    
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var interruptionContinuation: AsyncStream<RecorderInterruptionEvent>.Continuation?
    private var interruptionObserver: NSObjectProtocol?
    
    // MARK: - Init / Deinit
    
    init() {
        Task { await setupInterruptionObserver() }
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
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: AudioSettings.sampleRate,
            AVNumberOfChannelsKey: AudioSettings.numberOfChannels,
            AVLinearPCMBitDepthKey: AudioSettings.bitsPerSample,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
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
