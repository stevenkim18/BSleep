//
//  SplashView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 앱 아이콘/로고
                ZStack {
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.25))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(AppColors.primaryAccent)
                }
                
                // 앱 이름
                Text("Bsleep")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("당신의 수면을 분석하세요.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                
                Spacer()
                    .frame(height: 40)
                
                // 로딩 인디케이터
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryAccent))
                    .scaleEffect(1.2)
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SplashView()
}
