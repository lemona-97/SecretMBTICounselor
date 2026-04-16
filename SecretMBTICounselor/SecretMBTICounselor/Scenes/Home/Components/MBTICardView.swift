//
//  MBTICardView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct MBTICardView: View {
    let type: MBTIType

    var body: some View {
        VStack(spacing: 6) {
            Text(type.emoji)
                .font(.system(size: 28))
                .padding(.top, 10)
            Text(type.code)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(type.nickname.components(separatedBy: " ").last ?? "")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .fill(type.gradient)
        )
        .shadow(color: type.accent.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
