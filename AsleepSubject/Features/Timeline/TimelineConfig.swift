//
//  TimelineConfig.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import Foundation

/// Timeline 그래프 레이아웃 설정
struct TimelineConfig: Equatable {
    // MARK: - 시간 축 설정
    
    /// 시간 축 시작 시간 (21:00)
    let startHour: Int = 21
    
    /// 전체 시간 (24시간 + 1시간 여유)
    let totalHours: Int = 25
    
    /// 1시간당 너비 (핀치 줌 시 이 값만 변경)
    var hourWidth: CGFloat = 40
    
    /// 시간 표시 간격 (2시간 또는 1시간)
    var hourInterval: Int = 1
    
    // MARK: - 레이아웃 설정
    
    /// 1행당 높이
    let rowHeight: CGFloat = 44
    
    /// 날짜 컬럼 너비
    let dateColumnWidth: CGFloat = 70
    
    /// 헤더 높이
    let headerHeight: CGFloat = 32
    
    // MARK: - 표시할 날짜 수
    
    /// 표시할 날짜 수 (기본 14일)
    let numberOfDays: Int = 14
    
    // MARK: - 계산된 값
    
    /// 전체 시간 축 너비
    var totalTimeWidth: CGFloat {
        CGFloat(totalHours) * hourWidth
    }
    
    /// 시간 레이블 간격 (2시간 간격이면 80pt)
    var labelSpacing: CGFloat {
        CGFloat(hourInterval) * hourWidth
    }
    
    /// 표시할 시간 레이블 목록
    var timeLabels: [Int] {
        stride(from: 0, to: totalHours, by: hourInterval)
            .map { (startHour + $0) % 24 }
    }
}
