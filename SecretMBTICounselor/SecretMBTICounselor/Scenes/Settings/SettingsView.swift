//
//  SettingsView.swift
//  SecretMBTICounselor
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultInteractionMode") private var defaultModeRaw: String = InteractionMode.chat.rawValue
    @AppStorage("autoPlayTTS") private var autoPlayTTS: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    @AppStorage("notionLastFetchDate") private var notionLastFetchTimestamp: Double = 0

    // 일일 체크인
    @AppStorage(NotificationService.morningEnabledKey) private var morningEnabled: Bool = false
    @AppStorage(NotificationService.eveningEnabledKey) private var eveningEnabled: Bool = false
    @AppStorage(NotificationService.morningHourKey) private var morningHour: Int = 7
    @AppStorage(NotificationService.morningMinuteKey) private var morningMinute: Int = 30
    @AppStorage(NotificationService.eveningHourKey) private var eveningHour: Int = 18
    @AppStorage(NotificationService.eveningMinuteKey) private var eveningMinute: Int = 0

    private var morningTime: Binding<Date> {
        Binding(
            get: { Self.dateFor(hour: morningHour, minute: morningMinute) },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                morningHour = c.hour ?? 7
                morningMinute = c.minute ?? 30
            }
        )
    }

    private var eveningTime: Binding<Date> {
        Binding(
            get: { Self.dateFor(hour: eveningHour, minute: eveningMinute) },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                eveningHour = c.hour ?? 18
                eveningMinute = c.minute ?? 0
            }
        )
    }

    private static func dateFor(hour: Int, minute: Int) -> Date {
        var c = DateComponents()
        c.hour = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? .now
    }

    private func rescheduleCheckins() {
        let last = NotificationService.shared.lastUsedMBTI(context: modelContext)
        Task { await NotificationService.shared.rescheduleAll(lastUsedMBTI: last) }
    }

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

                    Section {
                        Toggle(isOn: $morningEnabled) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("아침 체크인")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Text("최근 대화한 상담사가 하루를 열어줘요")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            } icon: {
                                Image(systemName: "sun.max.fill").foregroundStyle(Color(hex: "FFCB70"))
                            }
                        }
                        if morningEnabled {
                            DatePicker("아침 시간",
                                       selection: morningTime,
                                       displayedComponents: .hourAndMinute)
                        }
                        Toggle(isOn: $eveningEnabled) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("저녁 체크인")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Text("하루를 돌아보는 한마디를 건네요")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            } icon: {
                                Image(systemName: "moon.stars.fill").foregroundStyle(Color(hex: "B19CD9"))
                            }
                        }
                        if eveningEnabled {
                            DatePicker("저녁 시간",
                                       selection: eveningTime,
                                       displayedComponents: .hourAndMinute)
                        }
                    } header: {
                        Text("일일 체크인")
                    } footer: {
                        Text("알림은 기기에서만 스케줄되며, 서버로 데이터가 전송되지 않아요.")
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
                .onChange(of: morningEnabled) { _, _ in rescheduleCheckins() }
                .onChange(of: eveningEnabled) { _, _ in rescheduleCheckins() }
                .onChange(of: morningHour) { _, _ in rescheduleCheckins() }
                .onChange(of: morningMinute) { _, _ in rescheduleCheckins() }
                .onChange(of: eveningHour) { _, _ in rescheduleCheckins() }
                .onChange(of: eveningMinute) { _, _ in rescheduleCheckins() }
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
