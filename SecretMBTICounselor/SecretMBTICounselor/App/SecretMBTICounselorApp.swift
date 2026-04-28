//
//  SecretMBTICounselorApp.swift
//  SecretMBTICounselor
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct SecretMBTICounselorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var notionTerms: [NotionTerm] = []

    init() {
        // AdMob SDK 초기화 (앱 시작 시 단 한 번)
        MobileAds.shared.start(completionHandler: nil)
    }

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([ChatSession.self, ChatMessage.self, UserTerm.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(AppTheme.textPrimary)
                .preferredColorScheme(.light)
                .environment(\.notionTerms, notionTerms)
                .task {
                    // 하루 1회만 Notion에서 신조어 fetch
                    if let terms = try? await NotionService.shared.fetchTermsIfNeeded(),
                       !terms.isEmpty {
                        notionTerms = terms
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    let context = sharedModelContainer.mainContext
                    let last = NotificationService.shared.lastUsedMBTI(context: context)
                    Task { await NotificationService.shared.rescheduleAll(lastUsedMBTI: last) }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
