//
//  SecretMBTICounselorApp.swift
//  SecretMBTICounselor
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct SecretMBTICounselorApp: App {
    init() {
        // AdMob SDK 초기화 (앱 시작 시 단 한 번)
        MobileAds.shared.start(completionHandler: nil)

        // 시뮬레이터는 SDK가 자동으로 테스트 광고를 표시함.
        // 실기기에서 테스트하려면 Xcode 콘솔에 출력되는 기기 ID를 아래에 추가:
        // MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["YOUR_DEVICE_ID"]
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
        }
        .modelContainer(sharedModelContainer)
    }
}
