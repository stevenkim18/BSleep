//
//  URL+FileManager.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/22/26.
//

import Foundation

extension URL {
        
    /// Documents 디렉토리 경로
    static var documentsDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
        
    /// 파일 존재 여부 확인
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: self.path)
    }
        
    /// 파일 삭제
    func removeFile() throws {
        try FileManager.default.removeItem(at: self)
    }
    
    /// 파일 삭제 (에러 무시)
    func removeFileIfExists() {
        try? FileManager.default.removeItem(at: self)
    }
    
    /// 파일 복사
    func copyFile(to destination: URL) throws {
        try FileManager.default.copyItem(at: self, to: destination)
    }
        
    /// 파일 속성 조회
    func fileAttributes() throws -> [FileAttributeKey: Any] {
        try FileManager.default.attributesOfItem(atPath: self.path)
    }
    
    /// 파일 크기 (bytes)
    var fileSize: UInt64? {
        guard let attrs = try? fileAttributes(),
              let size = attrs[.size] as? UInt64 else {
            return nil
        }
        return size
    }
    
    /// 파일 생성일
    var fileCreationDate: Date? {
        guard let attrs = try? fileAttributes(),
              let date = attrs[.creationDate] as? Date else {
            return nil
        }
        return date
    }
    
    /// 녹음 파일 URL 생성 (timestamp 기반)
    static func makeRecordingURL() throws -> URL {
        guard let documentsPath = URL.documentsDirectory else {
            throw NSError(
                domain: "Recording",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"]
            )
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "recording_\(timestamp).wav"
        return documentsPath.appendingPathComponent(fileName)
    }
}
