//
//  RecordingRow.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import SwiftUI

/// 녹음 파일 목록의 각 행을 표시하는 컴포넌트
struct RecordingRow: View {
    let recording: RecordingEntity
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 재생/정지 아이콘
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isPlaying ? .red : .blue)
                
                // 파일 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.fileName)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 재생 시간
                Text(recording.formattedDuration)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        RecordingRow(
            recording: RecordingEntity(
                id: UUID(),
                url: URL(fileURLWithPath: "/recording_12345.m4a"),
                startedAt: Date().addingTimeInterval(-3600),
                endedAt: Date()
            ),
            isPlaying: false
        ) {
            print("Tapped")
        }
        
        RecordingRow(
            recording: RecordingEntity(
                id: UUID(),
                url: URL(fileURLWithPath: "/recording_67890.m4a"),
                startedAt: Date().addingTimeInterval(-3600),
                endedAt: Date()
            ),
            isPlaying: true
        ) {
            print("Tapped")
        }
    }
}
