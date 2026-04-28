//
//  SessionRowView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct SessionRowView: View {
    let session: ChatSession

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(session.mbti.gradient)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                if let attributed = try? AttributedString(markdown: session.preview) {
                    Text(attributed)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(session.preview)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(session.updatedAt.formatted(.relative(presentation: .named)))
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .fill(AppTheme.surface)
        )
    }
}
