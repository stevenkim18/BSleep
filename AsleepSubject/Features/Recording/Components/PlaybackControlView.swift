//
//  PlaybackControlView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import SwiftUI

/// 재생 컨트롤 버튼과 SeekBar를 통합한 컴포넌트
struct PlaybackControlView: View {
    let playbackState: PlaybackState?
    let isPaused: Bool
    
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onSeek: (TimeInterval) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Seek Bar
            if let state = playbackState {
                SeekBar(
                    currentTime: state.currentTime,
                    duration: state.duration,
                    onSeek: onSeek
                )
            } else {
                // 빈 상태 표시
                SeekBar(
                    currentTime: 0,
                    duration: 0,
                    onSeek: { _ in }
                )
                .opacity(0.5)
                .disabled(true)
            }
            
            // 컨트롤 버튼
            HStack(spacing: 40) {
                // 정지 버튼
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
                .disabled(playbackState == nil)
                .accessibilityLabel("정지")
                
                // 재생/일시정지 버튼
                Button {
                    if isPaused {
                        onResume()
                    } else {
                        onPause()
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(playbackState == nil)
                .accessibilityLabel(isPaused ? "재생" : "일시정지")
                
                // 빈 공간 (대칭을 위해)
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview("Playing") {
    PlaybackControlView(
        playbackState: PlaybackState(
            currentTime: 45,
            duration: 150,
            isPlaying: true
        ),
        isPaused: false,
        onPause: {},
        onResume: {},
        onStop: {},
        onSeek: { _ in }
    )
}

#Preview("Paused") {
    PlaybackControlView(
        playbackState: PlaybackState(
            currentTime: 45,
            duration: 150,
            isPlaying: false
        ),
        isPaused: true,
        onPause: {},
        onResume: {},
        onStop: {},
        onSeek: { _ in }
    )
}
