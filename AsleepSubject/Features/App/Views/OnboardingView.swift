//
//  OnboardingView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct OnboardingView: View {
    let onRequestPermission: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.3))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(AppColors.primaryAccent)
                }
                
                VStack(spacing: 12) {
                    Text("마이크 권한이 필요해요")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("녹음을 시작하려면\n마이크 접근 권한을 허용해주세요")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                Button {
                    onRequestPermission()
                } label: {
                    HStack {
                        Image(systemName: "mic.badge.plus")
                        Text("권한 허용하기")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingView(onRequestPermission: {})
}
