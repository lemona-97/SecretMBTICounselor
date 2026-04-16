//
//  MessageBubbleView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let mbti: MBTIType

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 40) }
            if !isUser {
                ZStack {
                    Circle().fill(mbti.gradient).frame(width: 30, height: 30)
                    Text(mbti.emoji).font(.system(size: 15))
                }
                .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 0) {
                if let attributedContent = try? AttributedString(markdown: message.content) {
                    Text(attributedContent)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                } else {
                    Text(message.content.isEmpty ? " " : message.content)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .fill(isUser ? AppTheme.bubbleUser : AppTheme.bubbleAssistant)
            )

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
