//
//  SecretMBTICounselorApp.swift
//  SecretMBTICounselor
//

import SwiftUI
import SwiftData
import GoogleMobileAds
import AppTrackingTransparency

@main
struct SecretMBTICounselorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var notionTerms: [NotionTerm] = []

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
                    if let terms = try? await NotionService.shared.fetchTermsIfNeeded(),
                       !terms.isEmpty {
                        notionTerms = terms
                    }
                }
                .task {
                    try? await Task.sleep(for: .seconds(1))
                    requestTrackingAndInitAds()
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

    private func requestTrackingAndInitAds() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        print("[ATT] 현재 상태: \(status.rawValue)") // 0=notDetermined 1=restricted 2=denied 3=authorized
        guard status == .notDetermined else {
            MobileAds.shared.start(completionHandler: nil)
            return
        }
        ATTrackingManager.requestTrackingAuthorization { result in
            print("[ATT] 사용자 선택 결과: \(result.rawValue)")
            MobileAds.shared.start(completionHandler: nil)
        }
    }
}
