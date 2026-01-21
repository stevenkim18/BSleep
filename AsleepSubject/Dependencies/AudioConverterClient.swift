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

/// 오디오 파일 변환을 위한 프로토콜
protocol AudioConverterClientProtocol: Sendable {
    /// WAV 파일을 M4A로 변환
    /// - Parameters:
    ///   - sourceURL: WAV 파일 경로
    ///   - destinationURL: M4A 파일 경로
    /// - Returns: 진행률 스트림 (0.0 ~ 1.0), 스트림 종료 시 변환 완료
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

/// AudioConverterClientProtocol의 실제 구현체
actor LiveAudioConverterClient: AudioConverterClientProtocol {
    
    func convert(
        from sourceURL: URL,
        to destinationURL: URL
    ) async throws -> AsyncStream<Float> {
        // iOS 18+: AVURLAsset 사용 (AVAsset(url:) deprecated)
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioConverterError.exportSessionCreationFailed
        }
        
        // 기존 파일이 있으면 삭제
        destinationURL.removeFileIfExists()
        
        return AsyncStream { continuation in
            Task {
                // iOS 18+: export(to:as:) 사용 및 states()로 진행률 모니터링
                async let exportResult: Void = exportSession.export(to: destinationURL, as: .m4a)
                
                // iOS 18+: states(updateInterval:)로 상태 모니터링 (status 폴링 대체)
                for await state in exportSession.states(updateInterval: 0.1) {
                    switch state {
                    case .pending, .waiting:
                        continue
                    case .exporting(let progress):
                        continuation.yield(Float(progress.fractionCompleted))
                    @unknown default:
                        // 미래에 추가될 수 있는 새로운 상태 처리
                        continue
                    }
                }
                
                // export 완료 대기 및 결과 처리
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
