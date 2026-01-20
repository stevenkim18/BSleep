//
//  RecoveringLoadingView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

/// 복구 진행 중 로딩 화면
struct RecoveringLoadingView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 로딩 인디케이터
            ZStack {
                Circle()
                    .fill(AppColors.primaryAccent.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(2.0)
                    .tint(AppColors.primaryAccent)
            }
            
            // 텍스트
            VStack(spacing: 12) {
                Text("파일 복구 중...")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("WAV 파일 헤더를 수정하고 있습니다.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        RecoveringLoadingView()
    }
}
#endif
