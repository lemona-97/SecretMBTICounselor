//
//  NativeAdLoader.swift
//  SecretMBTICounselor
//
//  네이티브 광고 고급형을 로드하는 ObservableObject.
//  NSObject 상속이 필요해 ObservableObject 사용.
//

import Combine
import SwiftUI
import GoogleMobileAds

@MainActor
final class NativeAdLoader: NSObject, ObservableObject {
    @Published var nativeAd: NativeAd?
    @Published var isLoading: Bool = false
    @Published var loadFailed: Bool = false

    private var adLoader: AdLoader?
    private var didRequestAd = false

    func load(adUnitID: String) {
        guard !didRequestAd, !isLoading, nativeAd == nil else { return }
        didRequestAd = true
        isLoading = true
        loadFailed = false

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first?.rootViewController
        else {
            isLoading = false
            loadFailed = true
            return
        }

        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
}

// MARK: - NativeAdLoaderDelegate

extension NativeAdLoader: NativeAdLoaderDelegate {
    nonisolated func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        Task { @MainActor in
            self.nativeAd = nativeAd
            self.isLoading = false
            self.adLoader = nil
            print("[AdMob] Native 광고 로드 성공")
        }
    }

    nonisolated func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.loadFailed = true
            self.adLoader = nil
            print("[AdMob] Native 광고 로드 실패: \(error.localizedDescription)")
        }
    }
}
