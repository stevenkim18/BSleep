//
//  WavRecoveryClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import Dependencies
import Foundation

// MARK: - Error

enum WavRecoveryError: LocalizedError {
    case fileNotFound
    case fileTooSmall
    case invalidWavFormat
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "파일을 찾을 수 없습니다."
        case .fileTooSmall:
            return "파일 크기가 너무 작아 복구할 수 없습니다."
        case .invalidWavFormat:
            return "유효한 WAV 파일 형식이 아닙니다."
        case .writeFailed:
            return "파일 쓰기에 실패했습니다."
        }
    }
}

// MARK: - Protocol

/// WAV 파일 헤더 복구를 위한 프로토콜
protocol WavRecoveryClientProtocol: Sendable {
    /// 불완전한 WAV 파일의 헤더를 복구
    /// - Parameter fileURL: 복구할 WAV 파일 경로
    /// - Returns: 복구 성공 시 true
    func recover(fileURL: URL) async throws -> Bool
}

// MARK: - Live Implementation

/// WavRecoveryClientProtocol의 실제 구현체
///
/// WAV 파일 구조:
/// ```
/// Offset  Size  Description
/// 0       4     "RIFF"
/// 4       4     File size - 8
/// 8       4     "WAVE"
/// 12      4     "fmt "
/// 16      4     fmt chunk size (16 for PCM)
/// 20      2     Audio format (1 = PCM)
/// 22      2     Number of channels
/// 24      4     Sample rate
/// 28      4     Byte rate
/// 32      2     Block align
/// 34      2     Bits per sample
/// 36      4     "data"
/// 40      4     Data size (= file size - 44)
/// 44      ...   Raw PCM data
/// ```
actor LiveWavRecoveryClient: WavRecoveryClientProtocol {
    
    // WAV 헤더 크기 (표준 PCM)
    private let headerSize: UInt32 = 44
    
    // 오디오 설정 (AudioSettings에서 가져옴)
    private var sampleRate: UInt32 { UInt32(AudioSettings.sampleRate) }
    private var numChannels: UInt16 { UInt16(AudioSettings.numberOfChannels) }
    private var bitsPerSample: UInt16 { UInt16(AudioSettings.bitsPerSample) }
    
    func recover(fileURL: URL) async throws -> Bool {
        // 1. 파일 존재 확인
        guard fileURL.fileExists else {
            throw WavRecoveryError.fileNotFound
        }
        
        // 2. 파일 크기 확인 (최소 헤더 크기보다 커야 함)
        guard let fileSize = fileURL.fileSize,
              fileSize > UInt64(headerSize) else {
            throw WavRecoveryError.fileTooSmall
        }
        
        // 3. 데이터 크기 계산 (전체 파일 크기 - 헤더 크기)
        let dataSize = UInt32(fileSize) - headerSize
        
        // 4. 올바른 크기 값이 포함된 새 헤더 생성 (44 bytes)
        let header = createWavHeader(dataSize: dataSize)
        
        // 5. 파일의 처음 44 bytes만 덮어쓰기 (메모리 효율적!)
        //    오디오 데이터는 이미 파일에 있으므로 건드릴 필요 없음
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            defer { try? fileHandle.close() }
            
            try fileHandle.seek(toOffset: 0)
            try fileHandle.write(contentsOf: header)
        } catch {
            throw WavRecoveryError.writeFailed
        }
        
        return true
    }
    
    // MARK: - Private
    
    /// WAV 헤더 생성 (44 bytes)
    private func createWavHeader(dataSize: UInt32) -> Data {
        var header = Data()
        
        // RIFF chunk
        header.append(contentsOf: "RIFF".utf8)                              // ChunkID
        header.append(littleEndian: dataSize + 36)                          // ChunkSize (FileSize - 8)
        header.append(contentsOf: "WAVE".utf8)                              // Format
        
        // fmt sub-chunk
        header.append(contentsOf: "fmt ".utf8)                              // Subchunk1ID
        header.append(littleEndian: UInt32(16))                             // Subchunk1Size (PCM = 16)
        header.append(littleEndian: UInt16(1))                              // AudioFormat (PCM = 1)
        header.append(littleEndian: numChannels)                            // NumChannels
        header.append(littleEndian: sampleRate)                             // SampleRate
        
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        header.append(littleEndian: byteRate)                               // ByteRate
        
        let blockAlign = numChannels * (bitsPerSample / 8)
        header.append(littleEndian: blockAlign)                             // BlockAlign
        header.append(littleEndian: bitsPerSample)                          // BitsPerSample
        
        // data sub-chunk
        header.append(contentsOf: "data".utf8)                              // Subchunk2ID
        header.append(littleEndian: dataSize)                               // Subchunk2Size
        
        return header
    }
}

// MARK: - Data Extension

private extension Data {
    /// Little-endian으로 정수를 Data에 추가
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { buffer in
            self.append(contentsOf: buffer) 
        }
    }
}

// MARK: - Dependency Key

private enum WavRecoveryClientKey: DependencyKey {
    static let liveValue: any WavRecoveryClientProtocol = LiveWavRecoveryClient()
}

// MARK: - Dependency Values

extension DependencyValues {
    var wavRecoveryClient: any WavRecoveryClientProtocol {
        get { self[WavRecoveryClientKey.self] }
        set { self[WavRecoveryClientKey.self] = newValue }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension LiveWavRecoveryClient {
    /// 테스트용 빈 WAV 파일 생성 (헤더만 있어서 복구 실패함)
    func createEmptyWavForTesting() async throws -> URL {
        guard let documentsURL = URL.documentsDirectory else {
            throw WavRecoveryError.writeFailed
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "test_empty_\(formatter.string(from: Date())).wav"
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        // 데이터 크기 0인 헤더만 생성 (44 bytes)
        let header = createWavHeader(dataSize: 0)
        try header.write(to: fileURL)
        
        return fileURL
    }
    
    /// 테스트용 불완전 WAV 파일 생성 (헤더는 0이지만 데이터는 있음)
    func createIncompleteWavForTesting() async throws -> URL {
        guard let documentsURL = URL.documentsDirectory else {
            throw WavRecoveryError.writeFailed
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "test_incomplete_\(formatter.string(from: Date())).wav"
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        // 헤더는 크기 0으로 생성 (불완전)
        var header = createWavHeader(dataSize: 0)
        
        // 1초 분량의 더미 오디오 데이터 추가 (44100 samples × 2 bytes = 88200 bytes)
        let dummyAudioData = Data(repeating: 0, count: 44100 * 2 * 7200)
        header.append(dummyAudioData)
        
        try header.write(to: fileURL)
        
        return fileURL
    }
}
#endif

