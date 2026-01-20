//
//  RecordingRow.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//
import SwiftUI

/// 녹음 파일 목록의 각 행을 표시하는 컴포넌트
struct RecordingRow: View {
    let recording: Recording
    let isPlaying: Bool
    let onTap: () -> Void
    
    /// WAV 파일 여부
    private var isWav: Bool {
        recording.format == .wav
    }
    
    /// 아이콘 색상
    private var iconColor: Color {
        isWav ? .orange : AppColors.primaryAccent
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 아이콘 (WAV: 경고, M4A: 재생)
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isWav ? "exclamationmark.triangle.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(iconColor)
                        .offset(x: isWav ? 0 : 2) // play 아이콘만 시각적 중심 보정
                }
                
                // 파일 정보
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(recording.fileName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        // WAV 배지
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
                
                // 재생 시간
                Text(recording.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.8))
                
                // 화살표
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
                    startedAt: Date().addingTimeInterval(-3600), // 1시간
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
                    startedAt: Date().addingTimeInterval(-10 * 3600), // 10시간 전
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
                    startedAt: Date().addingTimeInterval(-30 * 60), // 30분 전
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
                // 7시간 수면
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
                
                // 5시간 수면
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
                
                // 30분 낮잠
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
