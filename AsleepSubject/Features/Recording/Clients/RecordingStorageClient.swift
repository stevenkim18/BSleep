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
    func fetchRecordings() async throws -> [RecordingEntity]
    
    /// 녹음 파일 삭제
    func deleteRecording(_ recording: RecordingEntity) async throws
}

// MARK: - Live Implementation

/// RecordingStorageClientProtocol의 실제 구현체
actor LiveRecordingStorageClient: RecordingStorageClientProtocol {
    
    private let fileManager = FileManager.default
    
    func fetchRecordings() async throws -> [RecordingEntity] {
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
            .filter { $0.pathExtension == "m4a" }
        
        return files.compactMap { url -> RecordingEntity? in
            guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
                  let createdAt = attrs[.creationDate] as? Date else {
                return nil
            }
            
            // endedAt은 수정일 또는 duration 기반으로 계산
            let modifiedAt = attrs[.modificationDate] as? Date
            let duration = getDuration(of: url)
            let endedAt = modifiedAt ?? createdAt.addingTimeInterval(duration)
            
            return RecordingEntity(
                id: UUID(),
                url: url,
                startedAt: createdAt,
                endedAt: endedAt
            )
        }
        .sorted { $0.startedAt > $1.startedAt }
    }
    
    func deleteRecording(_ recording: RecordingEntity) async throws {
        try fileManager.removeItem(at: recording.url)
    }
    
    // MARK: - Private
    
    private func getDuration(of url: URL) -> TimeInterval {
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            return 0
        }
        return player.duration
    }
}

// MARK: - Mock Implementation for Previews

#if DEBUG
/// Preview/Test용 Mock 구현체
struct MockRecordingStorageClient: RecordingStorageClientProtocol {
    var recordings: [RecordingEntity] = []
    var shouldFail: Bool = false
    
    func fetchRecordings() async throws -> [RecordingEntity] {
        if shouldFail {
            throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock fetch failed"])
        }
        return recordings
    }
    
    func deleteRecording(_ recording: RecordingEntity) async throws {
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

