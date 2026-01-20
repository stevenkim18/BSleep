//
//  RecordingStorageClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import AVFoundation
import Dependencies
import Foundation

// MARK: - Protocol

/// 녹음 파일 저장소 관리를 위한 프로토콜
protocol RecordingStorageClientProtocol: Sendable {
    /// 저장된 녹음 파일 목록 조회
    func fetchRecordings() async throws -> [Recording]
    
    /// 녹음 파일 삭제
    func deleteRecording(_ recording: Recording) async throws
}

// MARK: - Live Implementation

/// RecordingStorageClientProtocol의 실제 구현체
actor LiveRecordingStorageClient: RecordingStorageClientProtocol {
    
    private let fileManager = FileManager.default
    
    func fetchRecordings() async throws -> [Recording] {
        guard let documentsURL = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first else {
            return []
        }
        
        let files = try fileManager
            .contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]
            )
            .filter { $0.pathExtension == "m4a" || $0.pathExtension == "wav" }
        
        // 비동기로 각 파일의 Recording 생성
        var recordings: [Recording] = []
        
        for url in files {
            guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
                  let createdAt = attrs[.creationDate] as? Date else {
                continue
            }
            
            // 비동기로 duration 로드
            let duration = await getDurationAsync(of: url)
            let endedAt = createdAt.addingTimeInterval(duration)
            
            // 확장자에서 포맷 결정
            let format: Recording.Format = url.pathExtension == "wav" ? .wav : .m4a
            
            let recording = Recording(
                id: UUID(),
                url: url,
                startedAt: createdAt,
                endedAt: endedAt,
                format: format
            )
            recordings.append(recording)
        }
        
        return recordings.sorted { $0.startedAt > $1.startedAt }
    }
    
    func deleteRecording(_ recording: Recording) async throws {
        try fileManager.removeItem(at: recording.url)
    }
    
    // MARK: - Private
    
    /// 비동기로 오디오 파일의 duration을 로드
    private func getDurationAsync(of url: URL) async -> TimeInterval {
        let asset = AVAsset(url: url)
        
        do {
            // iOS 16+ 비동기 로딩
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            
            if seconds.isFinite && seconds > 0 {
                return seconds
            }
        } catch {
            // 로딩 실패 시 무시
        }
        
        // Fallback: AVAudioPlayer로 시도
        if let player = try? AVAudioPlayer(contentsOf: url) {
            return player.duration
        }
        
        return 0
    }
}

// MARK: - Mock Implementation for Previews

#if DEBUG
/// Preview/Test용 Mock 구현체
struct MockRecordingStorageClient: RecordingStorageClientProtocol {
    var recordings: [Recording] = []
    var shouldFail: Bool = false
    
    func fetchRecordings() async throws -> [Recording] {
        if shouldFail {
            throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock fetch failed"])
        }
        return recordings
    }
    
    func deleteRecording(_ recording: Recording) async throws {
        if shouldFail {
            throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock delete failed"])
        }
        // Do nothing in mock
    }
}
#endif

// MARK: - Dependency Key

private enum RecordingStorageClientKey: DependencyKey {
    static let liveValue: any RecordingStorageClientProtocol = LiveRecordingStorageClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var recordingStorageClient: any RecordingStorageClientProtocol {
        get { self[RecordingStorageClientKey.self] }
        set { self[RecordingStorageClientKey.self] = newValue }
    }
}

