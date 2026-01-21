//
//  PulseView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/16/26.
//

import SwiftUI

struct PulseView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                .frame(width: 180, height: 180)
                .scaleEffect(animate ? 1.5 : 1.0)
                .opacity(animate ? 0 : 0.8)
            
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                .frame(width: 180, height: 180)
                .scaleEffect(animate ? 1.35 : 1.0)
                .opacity(animate ? 0 : 0.6)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.2), value: animate)
        }
        .animation(
            .easeOut(duration: 1.5).repeatForever(autoreverses: false),
            value: animate
        )
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        PulseView()
    }
}
#endif
