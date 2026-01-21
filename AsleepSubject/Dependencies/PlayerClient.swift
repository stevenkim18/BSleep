//
//  PlayerClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies

// MARK: - Protocol

protocol PlayerClientProtocol: Sendable {
    func play(url: URL) async throws
    func pause() async
    func resume() async
    func stop() async
    func seek(to time: TimeInterval) async
    func currentState() async -> PlaybackState?
    func stateStream() -> AsyncStream<PlaybackState>
    func eventStream() -> AsyncStream<PlaybackEvent>
    var isPlaying: Bool { get async }
}

// MARK: - Live Implementation

actor LivePlayerClient: PlayerClientProtocol {
    
    private var player: AVAudioPlayer?
    private var delegate: PlayerDelegate?
    private var eventStreamContinuation: AsyncStream<PlaybackEvent>.Continuation?
    private var stateStreamContinuation: AsyncStream<PlaybackState>.Continuation?
    private var stateUpdateTask: Task<Void, Never>?
    
    // MARK: - Properties
    
    nonisolated var isPlaying: Bool {
        get async {
            await _isPlaying
        }
    }
    
    private var _isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    // MARK: - Playback
    
    func play(url: URL) async throws {
        await stop()
        
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        }
        
        let delegate = PlayerDelegate { [weak self] in
            Task {
                await self?.handleFinished()
            }
        }
        
        let newPlayer = try AVAudioPlayer(contentsOf: url)
        newPlayer.delegate = delegate
        newPlayer.play()
        
        self.player = newPlayer
        self.delegate = delegate
        
        startStateUpdates()
    }
    
    func pause() async {
        player?.pause()
    }
    
    func resume() async {
        player?.play()
    }
    
    func stop() async {
        stopStateUpdates()
        
        let currentPlayer = player
        player = nil
        delegate = nil
        
        await MainActor.run {
            currentPlayer?.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    func seek(to time: TimeInterval) async {
        player?.currentTime = time
    }
    
    func currentState() async -> PlaybackState? {
        guard let player = player else { return nil }
        return PlaybackState(
            currentTime: player.currentTime,
            duration: player.duration,
            isPlaying: player.isPlaying
        )
    }
    
    // MARK: - State Stream
    
    nonisolated func stateStream() -> AsyncStream<PlaybackState> {
        AsyncStream { continuation in
            Task {
                await self.setStateStreamContinuation(continuation)
            }
        }
    }
    
    private func setStateStreamContinuation(_ continuation: AsyncStream<PlaybackState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    private func startStateUpdates() {
        stateUpdateTask?.cancel()
        
        stateUpdateTask = Task {
            while !Task.isCancelled {
                if let state = await currentState() {
                    stateStreamContinuation?.yield(state)
                } else {
                    break
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    private func stopStateUpdates() {
        stateUpdateTask?.cancel()
        stateUpdateTask = nil
    }
    
    // MARK: - Event Stream
    
    nonisolated func eventStream() -> AsyncStream<PlaybackEvent> {
        AsyncStream { continuation in
            Task {
                await self.setEventStreamContinuation(continuation)
            }
        }
    }
    
    private func setEventStreamContinuation(_ continuation: AsyncStream<PlaybackEvent>.Continuation) {
        self.eventStreamContinuation = continuation
    }
    
    private func handleFinished() {
        stopStateUpdates()
        eventStreamContinuation?.yield(.finished)
        player = nil
        delegate = nil
    }
}

// MARK: - Player Delegate

private class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: @Sendable () -> Void
    
    init(onFinish: @escaping @Sendable () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Dependency Key

private enum PlayerClientKey: DependencyKey {
    static let liveValue: any PlayerClientProtocol = LivePlayerClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var playerClient: any PlayerClientProtocol {
        get { self[PlayerClientKey.self] }
        set { self[PlayerClientKey.self] = newValue }
    }
}
