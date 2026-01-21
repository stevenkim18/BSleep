//
//  RecordingRow.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//
import SwiftUI

struct RecordingRow: View {
    let recording: Recording
    let isPlaying: Bool
    let onTap: () -> Void
    
    private var isWav: Bool {
        recording.format == .wav
    }
    
    private var iconColor: Color {
        isWav ? .orange : AppColors.primaryAccent
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isWav ? "exclamationmark.triangle.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(iconColor)
                        .offset(x: isWav ? 0 : 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(recording.fileName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        if isWav {
                            Text("변환 필요")
                                .font(.caption2.bold())
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.2))
                                )
                        }
                    }
                    
                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(recording.formattedDuration)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(recording.formattedFileSize)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isWav ? Color.orange.opacity(0.05) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isWav ? Color.orange.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Default") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()
        
        VStack {
            RecordingRow(
                recording: Recording(
                    id: UUID(),
                    url: URL(fileURLWithPath: "/recordings/recording_20260119_233015.m4a"),
                    startedAt: Date().addingTimeInterval(-3600),
                    endedAt: Date(),
                    format: .m4a
                ),
                isPlaying: false
            ) {
                print("Tapped")
            }
            .padding()
        }
    }
}

#Preview("Long Duration (10 hours)") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()
        
        VStack {
            RecordingRow(
                recording: Recording(
                    id: UUID(),
                    url: URL(fileURLWithPath: "/recordings/recording_20260118_220000.m4a"),
                    startedAt: Date().addingTimeInterval(-10 * 3600),
                    endedAt: Date(),
                    format: .m4a
                ),
                isPlaying: false
            ) {
                print("Tapped")
            }
            .padding()
        }
    }
}

#Preview("Short Duration (30 min)") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()
        
        VStack {
            RecordingRow(
                recording: Recording(
                    id: UUID(),
                    url: URL(fileURLWithPath: "/recordings/short_nap.m4a"),
                    startedAt: Date().addingTimeInterval(-30 * 60),
                    endedAt: Date(),
                    format: .m4a
                ),
                isPlaying: false
            ) {
                print("Tapped")
            }
            .padding()
        }
    }
}

#Preview("Multiple Rows") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 0) {
                RecordingRow(
                    recording: Recording(
                        id: UUID(),
                        url: URL(fileURLWithPath: "/recordings/recording_20260119_233015.m4a"),
                        startedAt: Date().addingTimeInterval(-7 * 3600),
                        endedAt: Date(),
                        format: .m4a
                    ),
                    isPlaying: false
                ) {
                    print("Tapped")
                }
                
                RecordingRow(
                    recording: Recording(
                        id: UUID(),
                        url: URL(fileURLWithPath: "/recordings/recording_20260118_020030.m4a"),
                        startedAt: Date().addingTimeInterval(-2 * 24 * 3600 - 5 * 3600),
                        endedAt: Date().addingTimeInterval(-2 * 24 * 3600),
                        format: .m4a
                    ),
                    isPlaying: false
                ) {
                    print("Tapped")
                }
                
                RecordingRow(
                    recording: Recording(
                        id: UUID(),
                        url: URL(fileURLWithPath: "/recordings/nap_20260117.m4a"),
                        startedAt: Date().addingTimeInterval(-3 * 24 * 3600 - 30 * 60),
                        endedAt: Date().addingTimeInterval(-3 * 24 * 3600),
                        format: .m4a
                    ),
                    isPlaying: false
                ) {
                    print("Tapped")
                }
            }
            .padding(.horizontal)
        }
    }
}
#endif
