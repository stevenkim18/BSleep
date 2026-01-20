//
//  RecordingListView.swift
//  AsleepSubject
//
//  Created by seungwooKim on 1/19/26.
//

import ComposableArchitecture
import SwiftUI

/// 녹음 목록 화면
struct RecordingListView: View {
    @Bindable var store: StoreOf<RecordingListFeature>
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            Group {
                if store.isLoading {
                    loadingView
                } else if let errorMessage = store.errorMessage {
                    errorView(message: errorMessage)
                } else if store.recordings.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("녹음 목록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("🛠️ 디버그") {
                        Button {
                            store.send(.createEmptyWavTapped)
                        } label: {
                            Label("빈 WAV 생성 (복구 실패)", systemImage: "doc.badge.plus")
                        }
                        
                        Button {
                            store.send(.createIncompleteWavTapped)
                        } label: {
                            Label("불완전 WAV 생성 (복구 가능)", systemImage: "doc.badge.ellipsis")
                        }
                        
                        Button {
                            store.send(.copyBigWavTapped)
                        } label: {
                            Label("5GB big.wav 복사", systemImage: "doc.on.doc")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.white)
                }
            }
        }
        #endif
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.playback, action: \.playback)) { playbackStore in
            PlaybackView(store: playbackStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        // WAV 변환 확인 Alert
        .alert(
            "변환이 필요합니다",
            isPresented: Binding(
                get: { store.wavConversionAlert != nil },
                set: { if !$0 { store.send(.cancelConversion) } }
            )
        ) {
            Button("취소", role: .cancel) {
                store.send(.cancelConversion)
            }
            Button("변환하기") {
                store.send(.confirmConversion)
            }
        } message: {
            Text("이 파일은 WAV 형식입니다.\nM4A로 변환하시겠습니까?")
        }
        // 변환 화면
        .fullScreenCover(
            item: $store.scope(state: \.conversion, action: \.conversion)
        ) { conversionStore in
            ConversionView(store: conversionStore)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            
            Text("녹음 목록 불러오는 중...")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        ContentUnavailableView {
            Label("녹음 파일 없음", systemImage: "waveform")
                .font(.largeTitle)
                .foregroundStyle(AppColors.primaryAccent)
        } description: {
            Text("녹음 버튼을 눌러 첫 녹음을 시작하세요")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        List(store.recordings) { recording in
            RecordingRow(
                recording: recording,
                isPlaying: false
            ) {
                store.send(.recordingTapped(recording))
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("오류 발생", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } description: {
            Text(message)
                .foregroundStyle(.white.opacity(0.9))
        } actions: {
            Button("다시 시도") {
                store.send(.onAppear)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primaryAccent)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With Recordings") {
    NavigationStack {
        RecordingListView(
            store: Store(initialState: RecordingListFeature.State()) {
                RecordingListFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(
                    recordings: Recording.mockRecordings
                )
            }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        RecordingListView(
            store: Store(initialState: RecordingListFeature.State()) {
                RecordingListFeature()
            } withDependencies: {
                $0.recordingStorageClient = MockRecordingStorageClient(recordings: [])
            }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        RecordingListView(
            store: Store(
                initialState: RecordingListFeature.State(isLoading: true)
            ) {
                EmptyReducer()
            }
        )
    }
}

#Preview("Error") {
    NavigationStack {
        RecordingListView(
            store: Store(
                initialState: RecordingListFeature.State(errorMessage: "데이터를 불러올 수 없습니다.")
            ) {
                EmptyReducer()
            }
        )
    }
}
#endif
