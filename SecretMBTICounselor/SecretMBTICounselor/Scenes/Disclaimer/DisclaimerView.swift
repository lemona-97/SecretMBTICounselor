//
//  DisclaimerView.swift
//  SecretMBTICounselor
//
//  앱 최초 실행 시 단 한 번 표시되는 AI 상담 주의사항 팝업.
//  AppStorage("hasShownDisclaimer")로 표시 여부를 영구 저장.
//

import SwiftUI

struct DisclaimerView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 배경 딤
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .transition(.opacity)

            // 카드
            VStack(spacing: 0) {
                // 상단 아이콘 + 타이틀
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.bubbleAssistant)
                            .frame(width: 64, height: 64)
                        Text("🧠")
                            .font(.system(size: 30))
                    }

                    Text("상담을 시작하기 전에")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                // 본문
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        disclaimerItem(
                            icon: "🤖",
                            title: "AI 서비스입니다",
                            body: "Secret MBTI의 상담사는 사람이 아닌 인공지능(AI)입니다. 한국 AI기본법에 따라 이를 명확히 안내드립니다."
                        )

                        disclaimerItem(
                            icon: "🏥",
                            title: "전문 치료를 대체하지 않아요",
                            body: "이 앱은 가벼운 감정 나눔과 자기 이해를 돕는 도구입니다. 전문 심리치료, 정신과 진료, 의료적 조언을 대신하지 않습니다."
                        )

                        disclaimerItem(
                            icon: "⚠️",
                            title: "위기 상황에는 적합하지 않아요",
                            body: "자해·자살 충동, 심각한 정신건강 위기 상황에서는 이 앱 대신 아래 전문기관에 즉시 연락해 주세요."
                        )

                        // 위기상담 전화번호 박스
                        VStack(alignment: .leading, spacing: 10) {
                            Text("📞 위기상담 전화")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)

                            hotlineRow(name: "자살예방상담전화", number: "109", note: "24시간")
                            hotlineRow(name: "정신건강위기상담", number: "1577-0199", note: "24시간·365일")
                            hotlineRow(name: "청소년전화", number: "1388", note: "24시간")
                        }
                        .padding(14)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall))

                        disclaimerItem(
                            icon: "🔒",
                            title: "대화 내용은 기기에만 저장돼요",
                            body: "모든 대화는 외부 서버로 전송되지 않으며 이 기기에만 저장됩니다. Apple의 온디바이스 AI를 사용합니다."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .frame(maxHeight: 380)

                Divider()
                    .padding(.horizontal, 24)

                // 확인 버튼
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("이해했어요, 시작할게요")
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

    // MARK: - Subviews

    private func disclaimerItem(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(body)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func hotlineRow(name: String, number: String, note: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Link(number, destination: URL(string: "tel://\(number)")!)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.blue)
            Text("· \(note)")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
