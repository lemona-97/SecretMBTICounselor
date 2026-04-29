//
//  AIAvailability.swift
//  SecretMBTICounselor
//
//  Apple Intelligence(FoundationModels) 사용 가능 여부 체크.
//

import Foundation
import FoundationModels

enum AIAvailability {
    enum Status: Equatable {
        case available
        case deviceNotEligible          // 기기 미지원 (구형 칩)
        case appleIntelligenceNotEnabled // 설정에서 켜지 않음
        case modelNotReady              // 모델 다운로드/준비 중
        case unknown
    }

    static var status: Status {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .deviceNotEligible
            case .appleIntelligenceNotEnabled:
                return .appleIntelligenceNotEnabled
            case .modelNotReady:
                return .modelNotReady
            @unknown default:
                return .unknown
            }
        }
    }

    static var isAvailable: Bool { status == .available }
}
