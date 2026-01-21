//
//  URL+FileManager.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/22/26.
//

import Foundation

extension URL {
        
    static var documentsDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
        
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: self.path)
    }
        
    func removeFile() throws {
        try FileManager.default.removeItem(at: self)
    }
    
    func removeFileIfExists() {
        try? FileManager.default.removeItem(at: self)
    }
    
    func copyFile(to destination: URL) throws {
        try FileManager.default.copyItem(at: self, to: destination)
    }
        
    func fileAttributes() throws -> [FileAttributeKey: Any] {
        try FileManager.default.attributesOfItem(atPath: self.path)
    }
    
    var fileSize: UInt64? {
        guard let attrs = try? fileAttributes(),
              let size = attrs[.size] as? UInt64 else {
            return nil
        }
        return size
    }
    
    var fileCreationDate: Date? {
        guard let attrs = try? fileAttributes(),
              let date = attrs[.creationDate] as? Date else {
            return nil
        }
        return date
    }
    
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
