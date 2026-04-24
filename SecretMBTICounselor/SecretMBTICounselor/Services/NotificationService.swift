//
//  NotificationService.swift
//  SecretMBTICounselor
//
//  매일 아침/저녁 일일 체크인 로컬 알림.
//  - 앞으로 N일치를 개별 등록 (랜덤 프리셋 + 최근 대화 MBTI 반영)
//  - 앱 foreground 진입 시 재스케줄
//

import Foundation
import UserNotifications
import SwiftData

enum CheckinSlot: String {
    case morning, evening
}

struct DailyCheckinPresets: Decodable {
    struct Slots: Decodable {
        let morning: [String]
        let evening: [String]
    }
    let version: Int
    let presets: [String: Slots]
}

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    // AppStorage keys (SettingsView에서 공유)
    static let morningEnabledKey = "checkinMorningEnabled"
    static let eveningEnabledKey = "checkinEveningEnabled"
    static let morningHourKey = "checkinMorningHour"      // Int, default 7
    static let morningMinuteKey = "checkinMorningMinute"  // Int, default 30
    static let eveningHourKey = "checkinEveningHour"      // Int, default 18
    static let eveningMinuteKey = "checkinEveningMinute"  // Int, default 0

    private let scheduleDays = 14
    private let morningIDPrefix = "checkin.morning."
    private let eveningIDPrefix = "checkin.evening."

    private lazy var presets: DailyCheckinPresets? = loadPresets()

    private init() {}

    // MARK: - Auth

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Reschedule

    /// 설정값을 읽어 전체 재스케줄. 앱 foreground 진입 및 설정 변경 시 호출.
    func rescheduleAll(lastUsedMBTI: MBTIType?) async {
        // 단짝 풀이 있으면 매일 그 중에서 랜덤, 없으면 최근 대화 MBTI, 그것도 없으면 전체 랜덤
        let besties = FavoritesStore.shared.besties
        let pickMBTI: () -> MBTIType = {
            if let pick = besties.randomElement() { return pick }
            if let last = lastUsedMBTI { return last }
            return MBTIType.allCases.randomElement() ?? .infp
        }
        let defaults = UserDefaults.standard
        let morningEnabled = defaults.object(forKey: Self.morningEnabledKey) as? Bool ?? false
        let eveningEnabled = defaults.object(forKey: Self.eveningEnabledKey) as? Bool ?? false

        // 기존 체크인 알림 모두 제거 (다른 알림이 생길 경우 대비해 prefix로 필터)
        await cancelAllCheckins()

        guard morningEnabled || eveningEnabled else { return }

        let granted = await requestAuthorization()
        guard granted else { return }

        let morningHour = defaults.object(forKey: Self.morningHourKey) as? Int ?? 7
        let morningMinute = defaults.object(forKey: Self.morningMinuteKey) as? Int ?? 30
        let eveningHour = defaults.object(forKey: Self.eveningHourKey) as? Int ?? 18
        let eveningMinute = defaults.object(forKey: Self.eveningMinuteKey) as? Int ?? 0

        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<scheduleDays {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            if morningEnabled {
                await schedule(
                    slot: .morning,
                    mbti: pickMBTI(),
                    baseDate: dayDate,
                    hour: morningHour,
                    minute: morningMinute,
                    idPrefix: morningIDPrefix,
                    dayOffset: dayOffset
                )
            }
            if eveningEnabled {
                await schedule(
                    slot: .evening,
                    mbti: pickMBTI(),
                    baseDate: dayDate,
                    hour: eveningHour,
                    minute: eveningMinute,
                    idPrefix: eveningIDPrefix,
                    dayOffset: dayOffset
                )
            }
        }
    }

    func cancelAllCheckins() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(morningIDPrefix) || $0.hasPrefix(eveningIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Last used MBTI

    /// SwiftData에서 가장 최근 업데이트된 세션의 MBTI를 반환. 없으면 nil.
    func lastUsedMBTI(context: ModelContext) -> MBTIType? {
        var descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.mbti
    }

    // MARK: - Private

    private func schedule(
        slot: CheckinSlot,
        mbti: MBTIType,
        baseDate: Date,
        hour: Int,
        minute: Int,
        idPrefix: String,
        dayOffset: Int
    ) async {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0

        guard let fireDate = calendar.date(from: comps), fireDate > Date() else { return }

        let message = randomMessage(for: mbti, slot: slot) ?? defaultMessage(slot: slot)

        let content = UNMutableNotificationContent()
        content.title = mbti.nickname
        content.body = message
        content.sound = .default
        content.userInfo = ["mbti": mbti.rawValue, "slot": slot.rawValue]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )

        let id = "\(idPrefix)\(dayOffset)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func randomMessage(for mbti: MBTIType, slot: CheckinSlot) -> String? {
        guard let slots = presets?.presets[mbti.rawValue] else { return nil }
        let pool = slot == .morning ? slots.morning : slots.evening
        return pool.randomElement()
    }

    private func defaultMessage(slot: CheckinSlot) -> String {
        switch slot {
        case .morning: return "좋은 아침이에요. 오늘도 응원할게요."
        case .evening: return "오늘 하루도 수고 많으셨어요."
        }
    }

    private func loadPresets() -> DailyCheckinPresets? {
        guard let url = Bundle.main.url(forResource: "DailyCheckinPresets", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(DailyCheckinPresets.self, from: data)
    }
}
