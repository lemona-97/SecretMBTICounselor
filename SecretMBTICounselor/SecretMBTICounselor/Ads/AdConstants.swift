//
//  AdConstants.swift
//  SecretMBTICounselor
//

import Foundation
import GoogleMobileAds

enum AdConstants {
    #if DEBUG
    /// Google 공식 테스트 배너 ID
    static let homeBannerID    = "ca-app-pub-3940256099942544/2934735716"
    /// Google 공식 테스트 네이티브 고급형 ID
    static let chatListNativeID = "ca-app-pub-3940256099942544/3986624511"
    #else
    /// 홈 하단 배너 (실제)
    static let homeBannerID    = "ca-app-pub-4519140016182239/7001632042"
    /// 채팅 리스트 네이티브 광고 고급형 (실제)
    static let chatListNativeID = "ca-app-pub-4519140016182239/1033930009"
    #endif
}
