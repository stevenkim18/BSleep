//
//  RecoveryCompletedView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

/// 복구 성공 화면
struct RecoveryCompletedView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 성공 아이콘
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
            }
            
            // 텍스트
            VStack(spacing: 12) {
                Text("파일 복구 완료!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("WAV 파일 헤더가 성공적으로 복구되었습니다.\n이제 M4A로 변환할 수 있습니다.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // 변환 계속 버튼
            Button(action: onContinue) {
                Label("변환 시작", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
        RecoveryCompletedView(onContinue: {})
    }
}
#endif
