//
//  AppColors.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import SwiftUI

/// 앱 전체 색상 체계
enum AppColors {
    
    // MARK: - Timeline 다크 테마
    
    /// 메인 배경 (진한 네이비)
    static let background = Color(hex: "0D0D1A")
    
    /// 보조 배경 (그라데이션용)
    static let backgroundSecondary = Color(hex: "1A1A2E")
    
    /// 그리드 라인/구분선
    static let timelineGridLine = Color(hex: "2A2A4A")
    
    /// 녹음 바 그라데이션 - 시작 (보라)
    static let timelineBarGradientStart = Color(hex: "8B5CF6")
    
    /// 녹음 바 그라데이션 - 끝 (인디고)
    static let timelineBarGradientEnd = Color(hex: "6366F1")
    
    // MARK: - 공용
    
    /// 프라이머리 액센트 컬러
    static let primaryAccent = Color(hex: "8B5CF6")
}

// MARK: - Convenience

extension AppColors {
    /// Timeline 배경 그라데이션
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Timeline 바 그라데이션
    static var timelineBarGradient: LinearGradient {
        LinearGradient(
            colors: [timelineBarGradientStart, timelineBarGradientEnd.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
