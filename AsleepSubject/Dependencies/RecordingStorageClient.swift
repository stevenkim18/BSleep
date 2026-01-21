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

protocol RecordingStorageClientProtocol: Sendable {
    func fetchRecordings() async throws -> [Recording]
    func deleteRecording(_ recording: Recording) async throws
}

// MARK: - Live Implementation

actor LiveRecordingStorageClient: RecordingStorageClientProtocol {
    
    private let fileManager = FileManager.default
    
    func fetchRecordings() async throws -> [Recording] {
        guard let documentsURL = URL.documentsDirectory else {
            return []
        }
        
        let files = try fileManager
            .contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]
            )
            .filter { $0.pathExtension == "m4a" || $0.pathExtension == "wav" }
        
        var recordings: [Recording] = []
        
        for url in files {
            guard let createdAt = url.fileCreationDate else {
                continue
            }
            
            let duration = await getDurationAsync(of: url)
            let endedAt = createdAt.addingTimeInterval(duration)
            
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
    
    private func getDurationAsync(of url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            
            if seconds.isFinite && seconds > 0 {
                return seconds
            }
        } catch {
        }
        
        if let player = try? AVAudioPlayer(contentsOf: url) {
            return player.duration
        }
        
        return 0
    }
}

// MARK: - Mock Implementation for Previews

#if DEBUG
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
