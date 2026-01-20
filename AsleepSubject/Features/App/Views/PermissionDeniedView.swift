//
//  PermissionDeniedView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct PermissionDeniedView: View {
    let onOpenSettings: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 경고 아이콘
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(.red)
                }
                
                VStack(spacing: 12) {
                    Text("마이크 권한이 거부되었어요")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("앱을 사용하려면 설정에서\n마이크 권한을 허용해주세요")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    // 설정 이동 버튼
                    Button {
                        onOpenSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("설정으로 이동")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Text("설정에서 권한 변경 후 돌아오면\n자동으로 확인합니다")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    PermissionDeniedView(onOpenSettings: {})
}
