//
//  TimelineConfig.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import Foundation

/// 타임라인 그래프 레이아웃 설정
/// - hourWidth 기반으로 설계하여 나중에 핀치 줌 확장 가능
struct TimelineConfig: Equatable {
    // MARK: - 시간 축 설정
    
    /// 시간 축 시작 시간 (21:00)
    let startHour: Int = 21
    
    /// 전체 시간 (24시간)
    let totalHours: Int = 24
    
    /// 1시간당 너비 (핀치 줌 시 이 값만 변경)
    let hourWidth: CGFloat = 30
    
    // MARK: - 레이아웃 설정
    
    /// 1행당 높이
    let rowHeight: CGFloat = 40
    
    /// 날짜 컬럼 너비
    let dateColumnWidth: CGFloat = 60
    
    /// 헤더 높이
    let headerHeight: CGFloat = 30
    
    // MARK: - 계산된 값
    
    /// 전체 시간 축 너비 (720pt)
    var totalTimeWidth: CGFloat {
        CGFloat(totalHours) * hourWidth
    }
    
    /// 기본 스크롤 오프셋 (22:00 위치)
    var defaultScrollOffset: CGFloat {
        hourWidth  // 21:00에서 22:00까지 = 1시간 = 30pt
    }
    
    // MARK: - 표시할 날짜 수
    
    /// 표시할 날짜 수 (기본 14일)
    let numberOfDays: Int = 14
}
