//
//  NativeAdRowView.swift
//  SecretMBTICounselor
//
//  채팅 리스트에 삽입되는 네이티브 광고 고급형 UI.
//  Google Mobile Ads SDK 11+ 기준.
//

import SwiftUI
import GoogleMobileAds

// MARK: - SwiftUI Wrapper

struct NativeAdRowView: View {
    @StateObject private var loader = NativeAdLoader()

    var body: some View {
        Group {
            if let ad = loader.nativeAd {
                NativeAdUIView(nativeAd: ad)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
            } else if loader.loadFailed {
                EmptyView()
            } else {
                NativeAdSkeletonView()
            }
        }
        .onAppear {
            loader.load(adUnitID: AdConstants.chatListNativeID)
        }
    }
}

// MARK: - UIViewRepresentable (NativeAdView)

private struct NativeAdUIView: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        setupSubviews(adView)
        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        bindAd(adView)
    }

    // MARK: - Layout

    private func setupSubviews(_ adView: NativeAdView) {
        adView.backgroundColor = UIColor(AppTheme.surface)
        adView.layer.cornerRadius = AppTheme.cornerMedium
        adView.clipsToBounds = true

        // 광고 표시 레이블
        let adLabel = makeAdLabel()

        // 아이콘
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.translatesAutoresizingMaskIntoConstraints = false
        adView.iconView = iconView

        // 제목
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = UIColor(AppTheme.textPrimary)
        headlineLabel.numberOfLines = 1
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.headlineView = headlineLabel

        // 본문
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor(AppTheme.textSecondary)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.bodyView = bodyLabel

        // CTA 버튼 (UIButton.Configuration으로 iOS 15+ 대응)
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.cornerStyle = .fixed
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            return a
        }
        let ctaButton = UIButton(configuration: config)
        ctaButton.layer.cornerRadius = 8
        ctaButton.clipsToBounds = true
        ctaButton.isUserInteractionEnabled = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        adView.callToActionView = ctaButton

        [iconView, headlineLabel, bodyLabel, ctaButton, adLabel].forEach {
            adView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // 아이콘
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            iconView.topAnchor.constraint(greaterThanOrEqualTo: adView.topAnchor, constant: 12),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -12),

            // 제목
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(lessThanOrEqualTo: ctaButton.leadingAnchor, constant: -8),
            headlineLabel.topAnchor.constraint(equalTo: adView.topAnchor, constant: 14),

            // 본문
            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -14),

            // CTA
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            ctaButton.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            ctaButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // 광고 레이블
            adLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            adLabel.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -4),
        ])
    }

    private func bindAd(_ adView: NativeAdView) {
        adView.nativeAd = nativeAd

        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)

        if let icon = nativeAd.icon?.image {
            (adView.iconView as? UIImageView)?.image = icon
        } else {
            adView.iconView?.isHidden = true
        }
    }

    private func makeAdLabel() -> UILabel {
        let label = UILabel()
        label.text = "광고"
        label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemOrange
        label.textAlignment = .center
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 24),
            label.heightAnchor.constraint(equalToConstant: 14),
        ])
        return label
    }
}

// MARK: - Skeleton

private struct NativeAdSkeletonView: View {
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.divider)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.divider)
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.divider)
                    .frame(width: 140, height: 10)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .fill(AppTheme.surface)
        )
        .opacity(0.65)
    }
}
