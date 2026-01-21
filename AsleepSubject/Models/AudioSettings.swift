//
//  AudioSettings.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/21/26.
//

import Foundation

enum AudioSettings {
    static let sampleRate: Double = 44100
    static let numberOfChannels: Int = 1
    static let bitsPerSample: Int = 16
    
    static var byteRate: Int {
        Int(sampleRate) * numberOfChannels * (bitsPerSample / 8)
    }
    
    static var blockAlign: Int {
        numberOfChannels * (bitsPerSample / 8)
    }
}
