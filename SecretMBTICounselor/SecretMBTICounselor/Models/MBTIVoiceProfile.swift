//
//  MBTIVoiceProfile.swift
//  SecretMBTICounselor
//
//  MBTI별 TTS 보이스 프로파일(성별/피치/속도) 매핑.
//

import AVFoundation

struct VoiceProfile: Sendable {
    enum Gender: Sendable { case female, male }
    let gender: Gender
    let pitch: Float
    let rate: Float
    let preDelay: TimeInterval
    let postDelay: TimeInterval
}

extension MBTIType {

    /// 상담사 톤에 어울리는 TTS 프로파일.
    nonisolated var voiceProfile: VoiceProfile {
        let base = AVSpeechUtteranceDefaultSpeechRate
        switch self {
        // 분석가 (NT) — 낮고 차분
        case .intj: return .init(gender: .male,   pitch: 0.92, rate: base * 0.95, preDelay: 0,    postDelay: 0.08)
        case .intp: return .init(gender: .male,   pitch: 0.97, rate: base * 0.96, preDelay: 0,    postDelay: 0.10)
        case .entj: return .init(gender: .female, pitch: 0.95, rate: base * 1.05, preDelay: 0,    postDelay: 0.04)
        case .entp: return .init(gender: .male,   pitch: 1.08, rate: base * 1.08, preDelay: 0,    postDelay: 0.04)

        // 외교관 (NF) — 부드럽고 따뜻
        case .infj: return .init(gender: .female, pitch: 0.98, rate: base * 0.93, preDelay: 0.05, postDelay: 0.12)
        case .infp: return .init(gender: .female, pitch: 1.05, rate: base * 0.95, preDelay: 0.05, postDelay: 0.12)
        case .enfj: return .init(gender: .female, pitch: 1.08, rate: base * 1.00, preDelay: 0,    postDelay: 0.08)
        case .enfp: return .init(gender: .female, pitch: 1.15, rate: base * 1.08, preDelay: 0,    postDelay: 0.04)

        // 관리자 (SJ) — 정돈된 톤
        case .istj: return .init(gender: .male,   pitch: 0.90, rate: base * 0.96, preDelay: 0,    postDelay: 0.10)
        case .isfj: return .init(gender: .female, pitch: 1.02, rate: base * 0.94, preDelay: 0.05, postDelay: 0.12)
        case .estj: return .init(gender: .male,   pitch: 0.95, rate: base * 1.02, preDelay: 0,    postDelay: 0.06)
        case .esfj: return .init(gender: .female, pitch: 1.10, rate: base * 1.00, preDelay: 0,    postDelay: 0.08)

        // 탐험가 (SP) — 경쾌하거나 담백
        case .istp: return .init(gender: .male,   pitch: 0.95, rate: base * 1.00, preDelay: 0,    postDelay: 0.06)
        case .isfp: return .init(gender: .female, pitch: 1.00, rate: base * 0.92, preDelay: 0.08, postDelay: 0.14)
        case .estp: return .init(gender: .male,   pitch: 1.05, rate: base * 1.12, preDelay: 0,    postDelay: 0.03)
        case .esfp: return .init(gender: .female, pitch: 1.18, rate: base * 1.10, preDelay: 0,    postDelay: 0.04)
        }
    }

    /// 설치된 한국어 보이스 중 성별에 가장 맞는 것을 고름.
    /// 향상된(enhanced/premium) 보이스가 있으면 우선.
    nonisolated func preferredVoice() -> AVSpeechSynthesisVoice? {
        let profile = voiceProfile
        let all = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("ko")
        }

        // 성별 가중치 적용 (iOS 17+ gender API)
        let genderMatched = all.filter { v -> Bool in
            switch profile.gender {
            case .female: return v.gender == .female || v.gender == .unspecified
            case .male:   return v.gender == .male
            }
        }
        let candidates = genderMatched.isEmpty ? all : genderMatched

        // 품질 우선순위: premium > enhanced > default
        let ranked = candidates.sorted { a, b in
            qualityRank(a.quality) > qualityRank(b.quality)
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: "ko-KR")
    }

    nonisolated private func qualityRank(_ q: AVSpeechSynthesisVoiceQuality) -> Int {
        switch q {
        case .premium:  return 3
        case .enhanced: return 2
        case .default:  return 1
        @unknown default: return 0
        }
    }
}
