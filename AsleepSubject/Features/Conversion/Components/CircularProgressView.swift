//
//  CircularProgressView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/20/26.
//

import SwiftUI

struct CircularProgressView: View {
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
        CircularProgressView(progress: 0)
            .frame(width: 180, height: 180)
    }
}

#Preview("45%") {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        CircularProgressView(progress: 0.45)
            .frame(width: 180, height: 180)
    }
}

#Preview("100%") {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        CircularProgressView(progress: 1.0)
            .frame(width: 180, height: 180)
    }
}
#endif
