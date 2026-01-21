//
//  AppStorageClient.swift
//  AsleepSubject
//
//  Created by AI Assistant on 1/22/26.
//

import Foundation
import ComposableArchitecture

// MARK: - Protocol

protocol AppStorageClientProtocol: Sendable {
    /// 가용 저장 공간 (바이트 단위)
    func availableCapacity() async throws -> Int64
}

// MARK: - Live Implementation

final class LiveAppStorageClient: AppStorageClientProtocol, Sendable {
    
    func availableCapacity() async throws -> Int64 {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        
        guard let capacity = values.volumeAvailableCapacityForImportantUsage else {
            throw AppStorageError.unableToGetCapacity
        }
        
        return capacity
    }
}

// MARK: - Error

enum AppStorageError: Error, LocalizedError {
    case unableToGetCapacity
    
    var errorDescription: String? {
        switch self {
        case .unableToGetCapacity:
            return "저장 공간 정보를 가져올 수 없습니다."
        }
    }
}

// MARK: - Dependency Key

private enum AppStorageClientKey: DependencyKey {
    static let liveValue: any AppStorageClientProtocol = LiveAppStorageClient()
}

extension DependencyValues {
    var appStorageClient: any AppStorageClientProtocol {
        get { self[AppStorageClientKey.self] }
        set { self[AppStorageClientKey.self] = newValue }
    }
}
