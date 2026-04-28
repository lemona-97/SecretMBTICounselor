//
//  ChatInputBarView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct ChatInputBarView: View {
    @Binding var text: String
    let accent: Color
    let isResponding: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("마음을 털어놓아 보세요", text: $text, axis: .vertical)
                .font(.system(size: 15, design: .rounded))
                .lineLimit(5, reservesSpace: false)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .fill(AppTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(accent))
                    .opacity(canSend ? 1 : 0.4)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.background)
    }

    private var canSend: Bool {
        !isResponding && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
