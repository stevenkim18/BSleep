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

protocol WavRecoveryClientProtocol: Sendable {
    func recover(fileURL: URL) async throws -> Bool
}

// MARK: - Live Implementation

actor LiveWavRecoveryClient: WavRecoveryClientProtocol {
    
    private let headerSize: UInt32 = 44
    
    private var sampleRate: UInt32 { UInt32(AudioSettings.sampleRate) }
    private var numChannels: UInt16 { UInt16(AudioSettings.numberOfChannels) }
    private var bitsPerSample: UInt16 { UInt16(AudioSettings.bitsPerSample) }
    
    func recover(fileURL: URL) async throws -> Bool {
        guard fileURL.fileExists else {
            throw WavRecoveryError.fileNotFound
        }
        
        guard let fileSize = fileURL.fileSize,
              fileSize > UInt64(headerSize) else {
            throw WavRecoveryError.fileTooSmall
        }
        
        let dataSize = UInt32(fileSize) - headerSize
        let header = createWavHeader(dataSize: dataSize)
        
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
    
    private func createWavHeader(dataSize: UInt32) -> Data {
        var header = Data()
        
        header.append(contentsOf: "RIFF".utf8)
        header.append(littleEndian: dataSize + 36)
        header.append(contentsOf: "WAVE".utf8)
        
        header.append(contentsOf: "fmt ".utf8)
        header.append(littleEndian: UInt32(16))
        header.append(littleEndian: UInt16(1))
        header.append(littleEndian: numChannels)
        header.append(littleEndian: sampleRate)
        
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        header.append(littleEndian: byteRate)
        
        let blockAlign = numChannels * (bitsPerSample / 8)
        header.append(littleEndian: blockAlign)
        header.append(littleEndian: bitsPerSample)
        
        header.append(contentsOf: "data".utf8)
        header.append(littleEndian: dataSize)
        
        return header
    }
}

// MARK: - Data Extension

private extension Data {
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
    func createEmptyWavForTesting() async throws -> URL {
        guard let documentsURL = URL.documentsDirectory else {
            throw WavRecoveryError.writeFailed
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "test_empty_\(formatter.string(from: Date())).wav"
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        let header = createWavHeader(dataSize: 0)
        try header.write(to: fileURL)
        
        return fileURL
    }
    
    func createIncompleteWavForTesting() async throws -> URL {
        guard let documentsURL = URL.documentsDirectory else {
            throw WavRecoveryError.writeFailed
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "test_incomplete_\(formatter.string(from: Date())).wav"
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        var header = createWavHeader(dataSize: 0)
        
        let dummyAudioData = Data(repeating: 0, count: 44100 * 2 * 7200)
        header.append(dummyAudioData)
        
        try header.write(to: fileURL)
        
        return fileURL
    }
}
#endif
