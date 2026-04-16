//
//  ProfileHeaderView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct ProfileHeaderView: View {
    let mbti: MBTIType

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .fill(mbti.gradient)
                    .frame(width: 56, height: 56)
                Text(mbti.emoji).font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(mbti.nickname)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(mbti.tagline)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .fill(AppTheme.surface)
                .shadow(color: AppTheme.shadow, radius: 8, x: 0, y: 4)
        )
    }
}
