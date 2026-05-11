//
//  TypingIndicatorView.swift
//  SecretMBTICounselor
//

import SwiftUI

// MARK: - Typing Indicator (파이프라인 대기 중 표시)

struct TypingIndicatorView: View {
    let mbti: MBTIType
    var stageLabel: String = "답변 생성 중"

    @State private var dotCount = 0

    private var displayText: String {
        stageLabel + String(repeating: ".", count: dotCount)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            FlameCharacterView()

            Text(displayText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .fill(AppTheme.bubbleAssistant)
                )
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.1), value: dotCount)

            Spacer(minLength: 40)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - Flame Character

struct FlameCharacterView: View {
    @State private var bounce = false
    @State private var glow = false

    private let gradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.93, blue: 0.55), // 밝은 노란
            Color(red: 1.00, green: 0.73, blue: 0.18), // 골드
            Color(red: 1.00, green: 0.55, blue: 0.05), // 주황
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            // 그림자
            Ellipse()
                .fill(Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.28))
                .frame(width: 34, height: 7)
                .blur(radius: 3)
                .scaleEffect(x: bounce ? 0.82 : 1.0)
                .animation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true), value: bounce)

            ZStack {
                // 왼쪽 귀
                FlameEarShape()
                    .fill(gradient)
                    .frame(width: 13, height: 17)
                    .offset(x: -16, y: -22)
                    .rotationEffect(.degrees(-18))

                // 오른쪽 귀
                FlameEarShape()
                    .fill(gradient)
                    .frame(width: 13, height: 17)
                    .scaleEffect(x: -1)
                    .offset(x: 16, y: -22)
                    .rotationEffect(.degrees(18))

                // 몸통
                FlameBodyShape()
                    .fill(gradient)
                    .frame(width: 44, height: 54)

                // 내부 하이라이트 (광택)
                FlameBodyShape()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(glow ? 0.38 : 0.22), Color.clear],
                            center: UnitPoint(x: 0.45, y: 0.52),
                            startRadius: 0,
                            endRadius: 16
                        )
                    )
                    .frame(width: 44, height: 54)

                // 눈
                HStack(spacing: 9) {
                    Circle().fill(Color.black).frame(width: 5.5, height: 5.5)
                    Circle().fill(Color.black).frame(width: 5.5, height: 5.5)
                }
                .offset(y: 10)

                // 미소
                SmileShape()
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .frame(width: 13, height: 5)
                    .offset(y: 19)
            }
            .offset(y: bounce ? -5 : 0)
            .scaleEffect(y: bounce ? 1.04 : 0.97)
            .animation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true), value: bounce)
        }
        .frame(width: 52, height: 64)
        .onAppear {
            bounce = true
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Shapes

/// 불꽃 몸통: 아래가 둥글고 위로 갈수록 뾰족해지는 teardrop
private struct FlameBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX

        p.move(to: CGPoint(x: cx, y: h))
        // 왼쪽 아래 → 왼쪽 위
        p.addCurve(
            to: CGPoint(x: cx - w * 0.44, y: h * 0.52),
            control1: CGPoint(x: cx - w * 0.28, y: h),
            control2: CGPoint(x: cx - w * 0.44, y: h * 0.76)
        )
        p.addCurve(
            to: CGPoint(x: cx - w * 0.14, y: h * 0.16),
            control1: CGPoint(x: cx - w * 0.44, y: h * 0.30),
            control2: CGPoint(x: cx - w * 0.28, y: h * 0.10)
        )
        // 왼쪽 → 꼭대기
        p.addCurve(
            to: CGPoint(x: cx, y: 0),
            control1: CGPoint(x: cx - w * 0.07, y: h * 0.06),
            control2: CGPoint(x: cx - w * 0.02, y: 0)
        )
        // 꼭대기 → 오른쪽
        p.addCurve(
            to: CGPoint(x: cx + w * 0.14, y: h * 0.16),
            control1: CGPoint(x: cx + w * 0.02, y: 0),
            control2: CGPoint(x: cx + w * 0.07, y: h * 0.06)
        )
        p.addCurve(
            to: CGPoint(x: cx + w * 0.44, y: h * 0.52),
            control1: CGPoint(x: cx + w * 0.28, y: h * 0.10),
            control2: CGPoint(x: cx + w * 0.44, y: h * 0.30)
        )
        p.addCurve(
            to: CGPoint(x: cx, y: h),
            control1: CGPoint(x: cx + w * 0.44, y: h * 0.76),
            control2: CGPoint(x: cx + w * 0.28, y: h)
        )
        p.closeSubpath()
        return p
    }
}

/// 귀 (작은 불꽃 모양)
private struct FlameEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let h = rect.height

        p.move(to: CGPoint(x: cx, y: h))
        p.addCurve(
            to: CGPoint(x: cx, y: 0),
            control1: CGPoint(x: rect.minX, y: h * 0.7),
            control2: CGPoint(x: rect.minX + rect.width * 0.1, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: cx, y: h),
            control1: CGPoint(x: rect.maxX - rect.width * 0.1, y: 0),
            control2: CGPoint(x: rect.maxX, y: h * 0.7)
        )
        p.closeSubpath()
        return p
    }
}

/// 미소 (위로 오목한 호)
private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return p
    }
}
