//
//  SeekBar.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/17/26.
//

import SwiftUI

/// 진행률 표시 및 탐색 기능을 제공하는 SeekBar 컴포넌트
struct SeekBar: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    var tintColor: Color = AppColors.primaryAccent // 기본값 설정
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return isDragging ? dragProgress : currentTime / duration
    }
    
    private var activeColor: Color {
        tintColor
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 프로그레스 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 트랙
                    Capsule()
                        .fill(Color.white.opacity(0.2)) // 다크 모드에 맞게 수정
                        .frame(height: 4)
                    
                    // 진행률 트랙
                    Capsule()
                        .fill(activeColor)
                        .frame(width: max(0, geometry.size.width * progress), height: 4)
                    
                    // 드래그 핸들 (Thumb)
                    Circle()
                        .fill(activeColor)
                        .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: max(0, min(geometry.size.width - 12, geometry.size.width * progress - 6)))
                        .animation(.easeOut(duration: 0.1), value: isDragging)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                            dragProgress = newProgress
                        }
                        .onEnded { value in
                            isDragging = false
                            let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                            onSeek(duration * newProgress)
                        }
                )
            }
            .frame(height: 20)
            
            // 시간 표시
            HStack {
                Text((isDragging ? duration * dragProgress : currentTime).formattedAsMinutesSeconds)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(duration.formattedAsMinutesSeconds)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("재생 진행률")
        .accessibilityValue("\(Int(progress * 100))퍼센트")
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        VStack {
            SeekBar(
                currentTime: 45,
                duration: 150,
                onSeek: { print("Seek to: \($0)") },
                tintColor: AppColors.primaryAccent
            )
            .padding()
        }
    }
}
