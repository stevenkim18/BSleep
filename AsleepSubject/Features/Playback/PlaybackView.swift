//
//  PlaybackView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

/// 반모달 재생 화면
struct PlaybackView: View {
    @Bindable var store: StoreOf<PlaybackFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // 드래그 핸들
            dragHandle
            
            // 헤더 (녹음 정보)
            headerSection
            
            Spacer()
            
            // 재생 컨트롤
            controlSection
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
        .overlay {
            if let errorMessage = store.errorMessage {
                errorOverlay(message: errorMessage)
            }
        }
    }
    
    // MARK: - Drag Handle
    
    private var dragHandle: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: store.isPlaying && !store.isPaused ? "waveform" : "waveform.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .symbolEffect(.variableColor.iterative, isActive: store.isPlaying && !store.isPaused)
            }
            
            // 파일 정보
            VStack(spacing: 4) {
                Text(store.recording.formattedDate)
                    .font(.headline)
                
                Text(store.recording.formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Control Section
    
    private var controlSection: some View {
        VStack(spacing: 24) {
            // SeekBar
            if let playbackState = store.playbackState {
                SeekBar(
                    currentTime: playbackState.currentTime,
                    duration: playbackState.duration,
                    onSeek: { store.send(.seekTo($0)) }
                )
            } else {
                SeekBar(
                    currentTime: 0,
                    duration: store.recording.duration,
                    onSeek: { _ in }
                )
                .opacity(0.5)
                .disabled(true)
            }
            
            // 컨트롤 버튼
            HStack(spacing: 48) {
                // 정지 버튼
                Button {
                    store.send(.stopTapped)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .disabled(!store.isPlaying && !store.isPaused)
                
                // 재생/일시정지 버튼
                Button {
                    if store.isPaused {
                        store.send(.resumeTapped)
                    } else if store.isPlaying {
                        store.send(.pauseTapped)
                    } else {
                        store.send(.playTapped)
                    }
                } label: {
                    Image(systemName: playPauseIcon)
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // 닫기 버튼
                Button {
                    store.send(.dismissTapped)
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    private var playPauseIcon: String {
        if store.isPaused {
            return "play.fill"
        } else if store.isPlaying {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(.red.opacity(0.9))
            .cornerRadius(12)
            .padding()
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Playing") {
    PlaybackView(
        store: Store(
            initialState: PlaybackFeature.State(
                recording: Recording.mockRecordings[0],
                isPlaying: true,
                playbackState: PlaybackState(
                    currentTime: 45,
                    duration: 150,
                    isPlaying: true
                )
            )
        ) {
            EmptyReducer()
        }
    )
    .presentationDetents([.medium])
}

#Preview("Paused") {
    PlaybackView(
        store: Store(
            initialState: PlaybackFeature.State(
                recording: Recording.mockRecordings[0],
                isPlaying: true,
                isPaused: true,
                playbackState: PlaybackState(
                    currentTime: 45,
                    duration: 150,
                    isPlaying: false
                )
            )
        ) {
            EmptyReducer()
        }
    )
    .presentationDetents([.medium])
}

#Preview("Stopped") {
    PlaybackView(
        store: Store(
            initialState: PlaybackFeature.State(
                recording: Recording.mockRecordings[0]
            )
        ) {
            EmptyReducer()
        }
    )
    .presentationDetents([.medium])
}
#endif
