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
        let asset = AVAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioConverterError.exportSessionCreationFailed
        }
        
        // 기존 파일이 있으면 삭제
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .m4a
        
        return AsyncStream { continuation in
            Task {
                // 변환 시작 (비동기)
                let exportTask = Task {
                    await exportSession.export()
                }
                
                // Export가 시작될 때까지 대기
                while exportSession.status == .unknown || exportSession.status == .waiting {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                
                // 진행률 모니터링
                while exportSession.status == .exporting {
                    continuation.yield(exportSession.progress)
                    try? await Task.sleep(for: .milliseconds(100))
                }
                
                // exportTask가 완료될 때까지 대기
                await exportTask.value
                
                // 최종 결과 처리
                switch exportSession.status {
                case .completed:
                    continuation.yield(1.0)
                    continuation.finish()
                case .failed, .cancelled:
                    continuation.finish()
                default:
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
