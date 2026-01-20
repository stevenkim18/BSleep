//
//  AudioSettings.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/21/26.
//

import Foundation

/// 녹음 시 사용되는 오디오 설정
/// RecorderClient와 WavRecoveryClient에서 공통으로 사용
enum AudioSettings {
    /// 샘플 레이트 (Hz)
    static let sampleRate: Double = 44100
    
    /// 채널 수 (1 = 모노, 2 = 스테레오)
    static let numberOfChannels: Int = 1
    
    /// 비트 심도
    static let bitsPerSample: Int = 16
    
    /// 바이트 레이트 (bytes per second)
    static var byteRate: Int {
        Int(sampleRate) * numberOfChannels * (bitsPerSample / 8)
    }
    
    /// 블록 얼라인 (bytes per sample for all channels)
    static var blockAlign: Int {
        numberOfChannels * (bitsPerSample / 8)
    }
}
