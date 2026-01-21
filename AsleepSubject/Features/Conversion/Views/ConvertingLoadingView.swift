//
//  ConvertingLoadingView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct ConvertingLoadingView: View {
    let progress: Float
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            CircularProgressIndicator(progress: CGFloat(progress))
                .frame(width: 180, height: 180)
            
            VStack(spacing: 12) {
                Text("변환 중...")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundStyle(AppColors.primaryAccent)
            }
            
            Spacer()
            
            Text("녹음 파일을 변환하고 있습니다.\n잠시만 기다려주세요.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.bottom, 60)
        }
    }
}

// MARK: - Circular Progress Indicator

private struct CircularProgressIndicator: View {
    let progress: CGFloat
    
    private let lineWidth: CGFloat = 12
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: lineWidth
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColors.primaryAccent,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
            
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.primaryAccent)
                .symbolEffect(.variableColor.iterative, isActive: progress < 1.0)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("0%") {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        ConvertingLoadingView(progress: 0)
    }
}

#Preview("45%") {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        ConvertingLoadingView(progress: 0.45)
    }
}

#Preview("100%") {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        ConvertingLoadingView(progress: 1.0)
    }
}
#endif
