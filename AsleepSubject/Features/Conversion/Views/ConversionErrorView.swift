//
//  ConversionErrorView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

/// 변환 실패 화면
struct ConversionErrorView: View {
    let message: String
    let onRecovery: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 에러 아이콘
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
            }
            
            // 에러 메시지
            VStack(spacing: 12) {
                Text("변환 실패")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // 버튼들
            VStack(spacing: 12) {
                // 파일 복구 버튼 (Primary)
                Button(action: onRecovery) {
                    Label("파일 복구", systemImage: "wrench.and.screwdriver")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 다시 시도 버튼
                Button(action: onRetry) {
                    Label("다시 시도", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primaryAccent.opacity(0.15))
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
        ConversionErrorView(
            message: "The operation couldn't be completed. (OSStatus error 12780)",
            onRecovery: {},
            onRetry: {},
            onClose: {}
        )
    }
}
#endif
