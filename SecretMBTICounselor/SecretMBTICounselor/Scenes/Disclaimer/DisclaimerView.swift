//
//  DisclaimerView.swift
//  SecretMBTICounselor
//
//  앱 최초 실행 시 단 한 번 표시되는 AI 상담 주의사항 + 데이터 처리 동의 팝업.
//  App Store 심사 가이드라인 5.1.1(i) / 5.1.2(i) 준수를 위해
//  - 어떤 데이터가 처리되는지
//  - 누가(어디서) 처리하는지 (Apple Intelligence: 온디바이스 / Private Cloud Compute)
//  - 사용자의 명시적 사전 동의(체크박스)
//  를 모두 안내·수집한다.
//

import SwiftUI

struct DisclaimerView: View {
    @Binding var isPresented: Bool

    @State private var didAgree: Bool = false

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
                    Image("mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(.circle)

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

                        // ⭐️ AI 데이터 처리 안내 (App Store 5.1.1 / 5.1.2 대응)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("🧠 AI 데이터 처리 안내")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("본 앱은 답변 생성을 위해 Apple이 제공하는 Apple Intelligence(Apple Foundation Models)를 사용합니다. OpenAI·Google 등 어떤 제3자 AI 서비스에도 데이터를 전송하지 않습니다.")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            bullet("전송되는 데이터: 사용자가 입력한 메시지, 선택한 MBTI 유형")
                            bullet("처리 주체: Apple Inc. (온디바이스 처리, 필요 시 Apple의 Private Cloud Compute)")
                            bullet("이용 목적: 상담 답변 생성")
                            bullet("제3자 제공: 없음 · 광고/마케팅 활용: 없음")
                            bullet("저장 위치: 대화 기록은 사용자의 기기에만 저장됩니다")
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall))

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
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .frame(maxHeight: 380)

                Divider()
                    .padding(.horizontal, 24)

                // 동의 체크박스
                Button {
                    didAgree.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: didAgree ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundStyle(didAgree ? AppTheme.textPrimary : AppTheme.textSecondary)
                        Text("위 내용을 확인했으며, Apple Intelligence를 통한 데이터 처리에 동의합니다.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // 확인 버튼
                Button {
                    guard didAgree else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("동의하고 시작할게요")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(didAgree ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
                }
                .disabled(!didAgree)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)
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

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
