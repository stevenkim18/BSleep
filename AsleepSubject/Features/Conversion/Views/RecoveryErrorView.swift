//
//  RecoveryErrorView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

/// 복구 실패 화면
struct RecoveryErrorView: View {
    let message: String
    let onDelete: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 에러 아이콘
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
            }
            
            // 에러 메시지
            VStack(spacing: 12) {
                Text("복구 실패")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text("파일이 너무 손상되어 복구할 수 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            // 버튼들
            VStack(spacing: 12) {
                // 파일 삭제 버튼
                Button(action: onDelete) {
                    Label("파일 삭제", systemImage: "trash")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 닫기 버튼
                Button(action: onClose) {
                    Text("닫기")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        RecoveryErrorView(
            message: "파일 크기가 너무 작아 복구할 수 없습니다.",
            onDelete: {},
            onClose: {}
        )
    }
}
#endif
