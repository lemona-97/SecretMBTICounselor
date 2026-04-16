//
//  ModeToggleView.swift
//  SecretMBTICounselor
//

import SwiftUI

struct ModeToggleView: View {
    @Binding var mode: InteractionMode
    let accent: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InteractionMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon).font(.system(size: 12, weight: .bold))
                        Text(m.label).font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(mode == m ? .white : AppTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(mode == m ? accent : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(AppTheme.surface))
        .overlay(Capsule().stroke(AppTheme.divider, lineWidth: 1))
    }
}
