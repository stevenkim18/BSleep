//
//  ConversionCompletedView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct ConversionCompletedView: View {
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 12) {
                Text("변환 완료!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("녹음 파일이 M4A로 변환되었습니다.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onConfirm) {
                Text("확인")
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
        ConversionCompletedView(onConfirm: {})
    }
}
#endif
