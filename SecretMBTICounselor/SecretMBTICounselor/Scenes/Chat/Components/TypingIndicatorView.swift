//
//  TypingIndicatorView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct TypingIndicatorView: View {
    let mbti: MBTIType
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(mbti.gradient).frame(width: 30, height: 30)
                Text(mbti.emoji).font(.system(size: 15))
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(AppTheme.textSecondary.opacity(phase == i ? 0.9 : 0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .fill(AppTheme.bubbleAssistant)
            )
            Spacer(minLength: 40)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                phase = (phase + 1) % 3
            }
        }
    }
}
