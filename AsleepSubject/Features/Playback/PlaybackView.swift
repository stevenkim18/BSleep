//
//  PlaybackView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

struct PlaybackView: View {
    @Bindable var store: StoreOf<PlaybackFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            headerSection
            Spacer()
            controlSection
            Spacer()
        }
        .padding()
        .background(AppColors.backgroundSecondary.ignoresSafeArea())
        .onAppear {
            store.send(.onAppear)
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
            .fill(Color.white.opacity(0.2))
            .frame(width: 36, height: 5)
            .padding(.top, 20)
            .padding(.bottom, 16)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: store.isPlaying && !store.isPaused ? "waveform" : "waveform.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primaryAccent)
                    .symbolEffect(.variableColor.iterative, isActive: store.isPlaying && !store.isPaused)
            }
            
            VStack(spacing: 8) {
                Text(store.recording.fileName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(store.recording.formattedDate)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Control Section
    
    private var controlSection: some View {
        VStack(spacing: 32) {
            if let playbackState = store.playbackState {
                SeekBar(
                    currentTime: playbackState.currentTime,
                    duration: playbackState.duration,
                    onSeek: { store.send(.seekTo($0)) },
                    tintColor: AppColors.primaryAccent
                )
            } else {
                SeekBar(
                    currentTime: 0,
                    duration: store.recording.duration,
                    onSeek: { _ in },
                    tintColor: AppColors.primaryAccent
                )
                .opacity(0.5)
                .disabled(true)
            }
            
            HStack(spacing: 40) {
                Button {
                    store.send(.stopTapped)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(!store.isPlaying && !store.isPaused)
                .opacity((!store.isPlaying && !store.isPaused) ? 0.5 : 1)
                
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
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(AppColors.primaryAccent)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primaryAccent.opacity(0.4), radius: 10, x: 0, y: 4)
                }
                
                Button {
                    store.send(.dismissTapped)
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.1))
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
