//
//  PlayerClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies

// MARK: - Protocol

/// 재생 전용 프로토콜
protocol PlayerClientProtocol: Sendable {
    /// 재생 시작
    func play(url: URL) async throws
    
    /// 일시 정지
    func pause() async
    
    /// 다시 재생 (일시 정지 후)
    func resume() async
    
    /// 정지 (리소스 해제)
    func stop() async
    
    /// 특정 위치로 이동
    func seek(to time: TimeInterval) async
    
    /// 현재 재생 상태 조회
    func currentState() async -> PlaybackState?
    
    /// 재생 상태 업데이트 스트림 (주기적 업데이트)
    func stateStream() -> AsyncStream<PlaybackState>
    
    /// 재생 완료 이벤트 스트림
    func eventStream() -> AsyncStream<PlaybackEvent>
    
    /// 현재 재생 중인지 확인
    var isPlaying: Bool { get async }
}

// MARK: - Live Implementation

/// PlayerClientProtocol의 실제 구현체
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
        // 기존 재생 정지
        await stop()
        
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        }
        
        // Delegate 생성
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
        
        // 상태 업데이트 시작
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
