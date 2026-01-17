//
//  AsleepSubjectWidgetExtensionLiveActivity.swift
//  AsleepSubjectWidgetExtension
//
//  Created by seungwooKim on 1/18/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AsleepSubjectWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            // 잠금 화면 UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startedAt, style: .timer)
                        .font(.headline)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("녹음 중")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.recordingName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                // Compact - 좌측
                Image(systemName: "waveform")
                    .foregroundStyle(.red)
            } compactTrailing: {
                // Compact - 우측
                Text(context.state.startedAt, style: .timer)
                    .monospacedDigit()
                    .font(.caption)
            } minimal: {
                // Minimal (다른 앱과 동시 표시 시)
                Image(systemName: "waveform")
                    .foregroundStyle(.red)
            }
            .keylineTint(.white)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // 녹음 아이콘
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "waveform")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            
            // 녹음 정보
            VStack(alignment: .leading, spacing: 2) {
                Text("녹음 중")
                    .font(.headline)
                
                Text(context.state.startedAt, style: .timer)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

extension RecordingActivityAttributes {
    fileprivate static var preview: RecordingActivityAttributes {
        RecordingActivityAttributes(recordingName: "수면 녹음")
    }
}

extension RecordingActivityAttributes.ContentState {
    fileprivate static var recording: RecordingActivityAttributes.ContentState {
        RecordingActivityAttributes.ContentState(startedAt: Date())
    }
}

#Preview("Notification", as: .content, using: RecordingActivityAttributes.preview) {
    AsleepSubjectWidgetExtensionLiveActivity()
} contentStates: {
    RecordingActivityAttributes.ContentState.recording
}
