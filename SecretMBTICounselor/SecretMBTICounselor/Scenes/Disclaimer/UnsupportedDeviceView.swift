//
//  UnsupportedDeviceView.swift
//  SecretMBTICounselor
//
//  Apple Intelligence 미지원/미활성 기기에서 안내 팝업.
//

import SwiftUI

struct UnsupportedDeviceView: View {
    let status: AIAvailability.Status
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.slash")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 80, height: 80)

                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 14) {
                    Text(message)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if status == .deviceNotEligible {
                        infoRow(
                            icon: "iphone",
                            text: "Apple Intelligence 지원 기기: iPhone 15 Pro 이상, M1 이상 iPad·Mac"
                        )
                    }

                    infoRow(
                        icon: "info.circle",
                        text: "AI 상담 기능은 사용할 수 없지만, 앱의 다른 기능은 둘러볼 수 있어요."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                Divider()
                    .padding(.horizontal, 24)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("확인")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge))
            .padding(.horizontal, 20)
            .shadow(color: AppTheme.shadow, radius: 24, y: 8)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }

    private var title: String {
        switch status {
        case .deviceNotEligible:        return "이 기기에서는\nAI 상담을 이용할 수 없어요"
        case .appleIntelligenceNotEnabled: return "Apple Intelligence가\n켜져 있지 않아요"
        case .modelNotReady:            return "AI 모델을 준비하고 있어요"
        default:                        return "AI 상담을 시작할 수 없어요"
        }
    }

    private var message: String {
        switch status {
        case .deviceNotEligible:
            return "이 앱의 상담 기능은 Apple Intelligence(온디바이스 AI)를 사용합니다. 현재 기기는 Apple Intelligence를 지원하지 않아 상담 대화를 이용할 수 없습니다."
        case .appleIntelligenceNotEnabled:
            return "설정 앱 → Apple Intelligence 및 Siri 에서 Apple Intelligence를 켠 뒤 다시 시도해 주세요."
        case .modelNotReady:
            return "Apple Intelligence 모델이 다운로드되는 중입니다. 잠시 후 다시 시도해 주세요. (Wi-Fi·충전 상태에서 더 빠르게 준비됩니다.)"
        default:
            return "현재 Apple Intelligence를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요."
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall))
    }
}
