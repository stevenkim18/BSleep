//
//  RecoveringLoadingView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct RecoveringLoadingView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.primaryAccent.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(2.0)
                    .tint(AppColors.primaryAccent)
            }
            
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
