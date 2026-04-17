//
//  SettingsView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultInteractionMode") private var defaultModeRaw: String = InteractionMode.chat.rawValue
    @AppStorage("autoPlayTTS") private var autoPlayTTS: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    @AppStorage("notionLastFetchDate") private var notionLastFetchTimestamp: Double = 0

    private var lastFetchLabel: String {
        guard notionLastFetchTimestamp > 0 else { return "아직 없음" }
        let date = Date(timeIntervalSince1970: notionLastFetchTimestamp)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    private var isVoiceDefault: Binding<Bool> {
        Binding(
            get: { defaultModeRaw == InteractionMode.voice.rawValue },
            set: { defaultModeRaw = ($0 ? InteractionMode.voice : InteractionMode.chat).rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                Form {
                    Section("대화 기본 설정") {
                        Toggle(isOn: isVoiceDefault) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("기본 모드: 보이스")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Text("끄면 채팅 모드로 시작해요")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            } icon: {
                                Image(systemName: "mic.fill").foregroundStyle(Color(hex: "FFB787"))
                            }
                        }
                        Toggle(isOn: $autoPlayTTS) {
                            Label("상담사 답변 자동 읽기", systemImage: "speaker.wave.2.fill")
                        }
                        Toggle(isOn: $hapticsEnabled) {
                            Label("햅틱 피드백", systemImage: "hand.tap.fill")
                        }
                    }

                    Section("앱 정보") {
                        HStack {
                            Label("AI 모델", systemImage: "sparkles")
                            Spacer()
                            Text("On-Device Foundation")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        HStack {
                            Label("신조어 업데이트", systemImage: "text.book.closed.fill")
                            Spacer()
                            Text(lastFetchLabel)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        HStack {
                            Label("버전", systemImage: "app.badge")
                            Spacer()
                            Text("1.0.0")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
}
