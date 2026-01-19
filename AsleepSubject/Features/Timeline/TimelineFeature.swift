//
//  TimelineFeature.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TimelineFeature {
    
    @ObservableState
    struct State: Equatable {
        // MARK: - 데이터
        
        /// 녹음 목록
        var recordings: [RecordingEntity] = []
        
        /// 로딩 상태
        var isLoading = false
        
        /// 에러 메시지
        var errorMessage: String?
        
        /// 선택된 녹음 (재생 화면 네비게이션용)
        var selectedRecording: RecordingEntity?
        
        // MARK: - 설정
        
        /// 레이아웃 설정
        let config = TimelineConfig()
        
        // MARK: - 계산된 값
        
        /// 표시할 날짜 범위 (sleepDate 기준, 최신 → 과거 순)
        var dateRange: [Date] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            return (0..<config.numberOfDays).compactMap { offset in
                calendar.date(byAdding: .day, value: -offset, to: today)
            }
        }
        
        /// 날짜별 녹음 그룹핑
        var recordingsByDate: [Date: [RecordingEntity]] {
            Dictionary(grouping: recordings, by: { $0.sleepDate })
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case recordingsLoaded([RecordingEntity])
        case recordingTapped(RecordingEntity)
        case errorOccurred(String)
    }
    
    @Dependency(\.recordingStorageClient) var recordingStorageClient
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let recordings = try await recordingStorageClient.fetchRecordings()
                        await send(.recordingsLoaded(recordings))
                    } catch {
                        await send(.errorOccurred("녹음 목록을 불러올 수 없습니다."))
                    }
                }
                
            case let .recordingsLoaded(recordings):
                state.isLoading = false
                state.recordings = recordings
                return .none
                
            case let .recordingTapped(recording):
                state.selectedRecording = recording
                return .none
                
            case let .errorOccurred(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }
}
