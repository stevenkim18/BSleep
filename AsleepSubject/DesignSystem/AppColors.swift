//
//  AppColors.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

enum AppColors {
    
    // MARK: - Timeline
    
    static let background = Color(hex: "0D0D1A")
    static let backgroundSecondary = Color(hex: "1A1A2E")
    static let timelineGridLine = Color(hex: "2A2A4A")
    static let timelineBarGradientStart = Color(hex: "8B5CF6")
    static let timelineBarGradientEnd = Color(hex: "6366F1")
    
    // MARK: - Common
    
    static let primaryAccent = Color(hex: "8B5CF6")
    
    // MARK: - Text
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)
}

// MARK: - Convenience

extension AppColors {
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var timelineBarGradient: LinearGradient {
        LinearGradient(
            colors: [timelineBarGradientStart, timelineBarGradientEnd.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
