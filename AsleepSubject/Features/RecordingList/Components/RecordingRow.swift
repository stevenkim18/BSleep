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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 재생 아이콘 (배경 원 포함)
                ZStack {
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.primaryAccent)
                        .offset(x: 2) // 시각적 중심 보정
                }
                
                // 파일 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.fileName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 재생 시간
                Text(recording.formattedDuration)
                    .font(.caption.monospacedDigit()) // 모노스페이스 숫자
                    .foregroundStyle(.white.opacity(0.8))
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                    endedAt: Date()
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
                    endedAt: Date()
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
                    endedAt: Date()
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
                        endedAt: Date()
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
                        endedAt: Date().addingTimeInterval(-2 * 24 * 3600)
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
                        endedAt: Date().addingTimeInterval(-3 * 24 * 3600)
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
