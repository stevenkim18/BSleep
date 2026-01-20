//
//  PermissionClient.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import AVFoundation
import ComposableArchitecture
import UIKit

// MARK: - PermissionStatus

enum PermissionStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

// MARK: - PermissionClient Protocol

protocol PermissionClient: Sendable {
    func checkMicrophonePermission() -> PermissionStatus
    func requestMicrophonePermission() async -> Bool
    func openSettings()
}

// MARK: - Live Implementation

final class LivePermissionClient: PermissionClient {
    
    func checkMicrophonePermission() -> PermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            return .notDetermined
        case .granted:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        Task { @MainActor in
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - TCA Dependency

private enum PermissionClientKey: DependencyKey {
    static let liveValue: any PermissionClient = LivePermissionClient()
}

extension DependencyValues {
    var permissionClient: any PermissionClient {
        get { self[PermissionClientKey.self] }
        set { self[PermissionClientKey.self] = newValue }
    }
}
