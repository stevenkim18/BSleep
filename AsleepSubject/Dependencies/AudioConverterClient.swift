//
//  AudioConverterClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import AVFoundation
import Dependencies
import Foundation

// MARK: - Protocol

protocol AudioConverterClientProtocol: Sendable {
    func convert(
        from sourceURL: URL,
        to destinationURL: URL
    ) async throws -> AsyncStream<Float>
}

// MARK: - Audio Converter Error

enum AudioConverterError: LocalizedError {
    case exportSessionCreationFailed
    case exportFailed(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .exportSessionCreationFailed:
            return "오디오 변환 세션을 생성할 수 없습니다."
        case .exportFailed(let reason):
            return "오디오 변환 실패: \(reason)"
        case .cancelled:
            return "오디오 변환이 취소되었습니다."
        }
    }
}

// MARK: - Live Implementation

actor LiveAudioConverterClient: AudioConverterClientProtocol {
    
    func convert(
        from sourceURL: URL,
        to destinationURL: URL
    ) async throws -> AsyncStream<Float> {
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioConverterError.exportSessionCreationFailed
        }
        
        destinationURL.removeFileIfExists()
        
        return AsyncStream { continuation in
            Task {
                async let exportResult: Void = exportSession.export(to: destinationURL, as: .m4a)
                
                for await state in exportSession.states(updateInterval: 0.1) {
                    switch state {
                    case .pending, .waiting:
                        continue
                    case .exporting(let progress):
                        continuation.yield(Float(progress.fractionCompleted))
                    @unknown default:
                        continue
                    }
                }
                
                do {
                    try await exportResult
                    continuation.yield(1.0)
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

// MARK: - Dependency Key

private enum AudioConverterClientKey: DependencyKey {
    static let liveValue: any AudioConverterClientProtocol = LiveAudioConverterClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var audioConverterClient: any AudioConverterClientProtocol {
        get { self[AudioConverterClientKey.self] }
        set { self[AudioConverterClientKey.self] = newValue }
    }
}
