//
//  MBTIType.swift
//  SecretMBTICounselor
//

import SwiftUI

enum MBTIType: String, CaseIterable, Identifiable, Codable, Sendable {
    case intj, intp, entj, entp
    case infj, infp, enfj, enfp
    case istj, isfj, estj, esfj
    case istp, isfp, estp, esfp

    nonisolated var id: String { rawValue }

    nonisolated var code: String { rawValue.uppercased() }

    /// 상담사 페르소나 닉네임
    nonisolated var nickname: String {
        switch self {
        case .intj: return "전략가 지안"
        case .intp: return "사색가 도윤"
        case .entj: return "지휘관 하린"
        case .entp: return "토론가 시우"
        case .infj: return "옹호자 해원"
        case .infp: return "중재자 윤슬"
        case .enfj: return "선도자 라온"
        case .enfp: return "활동가 반디"
        case .istj: return "현실주의자 정우"
        case .isfj: return "수호자 다정"
        case .estj: return "경영자 태오"
        case .esfj: return "집정관 소리"
        case .istp: return "장인 겨울"
        case .isfp: return "모험가 하나"
        case .estp: return "사업가 라이"
        case .esfp: return "연예인 봄이"
        }
    }

    /// 한 줄 컨셉 설명
    nonisolated var tagline: String {
        switch self {
        case .intj: return "깊이 있는 통찰로 길을 제시해요"
        case .intp: return "논리적으로 함께 고민해요"
        case .entj: return "결단력 있게 방향을 잡아요"
        case .entp: return "새로운 관점을 제안해요"
        case .infj: return "마음 깊이 공감해요"
        case .infp: return "따뜻하게 마음을 어루만져요"
        case .enfj: return "성장을 응원해요"
        case .enfp: return "에너지로 힘을 북돋아요"
        case .istj: return "단단한 조언을 드려요"
        case .isfj: return "조용히 곁을 지켜요"
        case .estj: return "현실적인 해결책을 찾아요"
        case .esfj: return "포근하게 안아드려요"
        case .istp: return "담백하게 정리해드려요"
        case .isfp: return "감성을 함께 나눠요"
        case .estp: return "행동으로 돌파해요"
        case .esfp: return "즐겁게 이야기해요"
        }
    }

    /// 이모지 아바타 (나중에 이미지로 교체 가능)
    nonisolated var emoji: String {
        switch self {
        case .intj: return "🔭"
        case .intp: return "🧩"
        case .entj: return "♟️"
        case .entp: return "💡"
        case .infj: return "🌙"
        case .infp: return "🌷"
        case .enfj: return "🌻"
        case .enfp: return "🎈"
        case .istj: return "📚"
        case .isfj: return "🍀"
        case .estj: return "🗂️"
        case .esfj: return "🍰"
        case .istp: return "🛠️"
        case .isfp: return "🎨"
        case .estp: return "🔥"
        case .esfp: return "🎉"
        }
    }

    /// 카드 그라데이션 (포근한 파스텔)
    var gradient: LinearGradient {
        LinearGradient(
            colors: palette,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var palette: [Color] {
        switch self {
        case .intj: return [Color(hex: "B8C5FF"), Color(hex: "8A9BE8")]
        case .intp: return [Color(hex: "C7E0F4"), Color(hex: "9BC6E8")]
        case .entj: return [Color(hex: "F4B8C5"), Color(hex: "E89BA8")]
        case .entp: return [Color(hex: "FFD9A8"), Color(hex: "FFB787")]
        case .infj: return [Color(hex: "D6C7F0"), Color(hex: "B19CD9")]
        case .infp: return [Color(hex: "FFD1DC"), Color(hex: "FFB3C6")]
        case .enfj: return [Color(hex: "FFE5A8"), Color(hex: "FFCB70")]
        case .enfp: return [Color(hex: "FFC8B4"), Color(hex: "FFA48C")]
        case .istj: return [Color(hex: "CFD8DC"), Color(hex: "90A4AE")]
        case .isfj: return [Color(hex: "C8E6C9"), Color(hex: "A5D6A7")]
        case .estj: return [Color(hex: "B0BEC5"), Color(hex: "78909C")]
        case .esfj: return [Color(hex: "FFDCE0"), Color(hex: "F5A3B0")]
        case .istp: return [Color(hex: "B2DFDB"), Color(hex: "80CBC4")]
        case .isfp: return [Color(hex: "E1BEE7"), Color(hex: "CE93D8")]
        case .estp: return [Color(hex: "FFAB91"), Color(hex: "FF8A65")]
        case .esfp: return [Color(hex: "FFF59D"), Color(hex: "FFE082")]
        }
    }

    var accent: Color { palette.last ?? .accentColor }
}
