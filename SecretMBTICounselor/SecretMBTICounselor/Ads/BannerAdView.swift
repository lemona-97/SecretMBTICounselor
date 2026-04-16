//
//  BannerAdView.swift
//  SecretMBTICounselor
//
//  Google Mobile Ads SDK 13.x 기준.
//  BannerView는 UIKit 클래스이므로 UIViewRepresentable로 래핑.
//

import SwiftUI
import GoogleMobileAds

// MARK: - UIViewRepresentable 래퍼

private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    let adUnitID: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[AdMob] Banner 로드 성공")
        }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdMob] Banner 로드 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - HomeView 하단 고정 배너

struct HomeBannerAdContainer: View {
    var body: some View {
        GeometryReader { geo in
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: geo.size.width)
            BannerViewContainer(adSize: adSize, adUnitID: AdConstants.homeBannerID)
                .frame(width: geo.size.width, height: adSize.size.height)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(AppTheme.surface)
    }
}
