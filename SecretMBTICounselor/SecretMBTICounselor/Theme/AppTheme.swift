//
//  AppTheme.swift
//  SecretMBTICounselor
//

import SwiftUI

enum AppTheme {
    static let background = Color(hex: "FBF7F4")      // 따뜻한 아이보리
    static let surface = Color.white
    static let textPrimary = Color(hex: "2B2A33")
    static let textSecondary = Color(hex: "7A7786")
    static let divider = Color(hex: "EDE7E1")
    static let bubbleUser = Color(hex: "FFE7D6")
    static let bubbleAssistant = Color(hex: "F2ECFF")
    static let shadow = Color.black.opacity(0.06)

    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 10
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((v & 0xFF0000) >> 16) / 255
            g = Double((v & 0x00FF00) >> 8) / 255
            b = Double(v & 0x0000FF) / 255
            a = 1
        case 8:
            r = Double((v & 0xFF000000) >> 24) / 255
            g = Double((v & 0x00FF0000) >> 16) / 255
            b = Double((v & 0x0000FF00) >> 8) / 255
            a = Double(v & 0x000000FF) / 255
        default:
            r = 1; g = 1; b = 1; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// 앱 전역에서 쓰는 기본 입력 모드
enum InteractionMode: String, CaseIterable, Codable {
    case chat, voice
    var label: String { self == .chat ? "채팅" : "보이스" }
    var icon: String { self == .chat ? "bubble.left.and.bubble.right.fill" : "mic.fill" }
}
