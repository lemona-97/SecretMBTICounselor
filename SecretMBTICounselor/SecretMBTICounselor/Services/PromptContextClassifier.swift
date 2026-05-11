//
//  PromptContextClassifier.swift
//  SecretMBTICounselor
//
//  Core ML EmotionClassifier 를 감싸 FoundationModels 용 프롬프트 컨텍스트를 생성합니다.
//  EmotionClassifier.mlpackage 와 vocab.txt 가 앱 번들에 있어야 합니다.
//

import CoreML
import Foundation

// MARK: - 감정 레이블

enum EmotionLabel: Int, CaseIterable {
    case joy          = 0  // 기쁨
    case sadness      = 1  // 슬픔/우울
    case anxiety      = 2  // 불안
    case anger        = 3  // 분노
    case hurt         = 4  // 상처/당황
    case addiction    = 5  // 중독
    case crisis       = 6  // 위기

    var displayName: String {
        switch self {
        case .joy:       return "기쁨"
        case .sadness:   return "슬픔/우울"
        case .anxiety:   return "불안"
        case .anger:     return "분노"
        case .hurt:      return "상처/당황"
        case .addiction: return "중독"
        case .crisis:    return "위기"
        }
    }

    // FoundationModels 에 주입할 프롬프트 컨텍스트
    var promptContext: String {
        switch self {
        case .joy:
            return "[감정 맥락] 사용자는 현재 긍정적이고 밝은 감정 상태입니다. 함께 기뻐하며 자연스럽게 대화를 이어가세요."

        case .sadness:
            return "[감정 맥락] 사용자는 슬프거나 우울한 감정을 경험하고 있습니다. 깊은 공감과 따뜻한 위로를 최우선으로 하세요. 충고나 해결책 제시는 자제하고, 감정을 충분히 받아들인 뒤 조심스럽게 접근하세요."

        case .anxiety:
            return "[감정 맥락] 사용자가 불안하거나 두려움을 느끼고 있습니다. 안정감을 주는 차분한 말투로, 현재 상황에 집중할 수 있도록 도와주세요. 과도한 걱정을 부추기는 표현을 피하세요."

        case .anger:
            return "[감정 맥락] 사용자가 분노하고 있습니다. 감정을 먼저 인정하고 공감하세요. 반박, 설교, 즉각적인 조언은 피하고 '화가 날 만하다'는 태도로 감정을 수용하세요."

        case .hurt:
            return "[감정 맥락] 사용자가 상처받거나 당황한 상태입니다. 판단하지 않는 태도로 조심스럽게 접근하고, 사용자의 감정이 충분히 타당함을 먼저 인정하세요."

        case .addiction:
            return "[감정 맥락] 사용자가 충동적이거나 반복적인 행동 패턴을 언급할 수 있습니다. 비판 없이 중립적인 태도를 유지하고, 변화에 대한 동기를 조심스럽게 탐색하세요. 직접적인 금지나 훈계는 역효과를 낳습니다."

        case .crisis:
            return "[⚠️ 위기 감지] 사용자가 위험하거나 긴급한 상황에 처했을 수 있습니다. 즉각적인 안전을 최우선으로 확인하고, 전문적 도움(정신건강 위기상담전화 1577-0199, 자살예방상담전화 1393)을 안내하세요. 혼자 해결하려 하지 말고 전문가 연계를 권고하세요."
        }
    }
}

// MARK: - 분류 결과

struct EmotionClassification {
    let label: EmotionLabel
    let confidence: Float
    let allProbabilities: [EmotionLabel: Float]

    var promptContext: String { label.promptContext }

    var isHighConfidence: Bool { confidence >= 0.5 }
}

// MARK: - 분류기

actor PromptContextClassifier {
    static let shared = PromptContextClassifier()

    private var model: MLModel?
    private let tokenizer = BertTokenizer.shared

    private init() {
        Task { await self.loadModel() }
    }

    private func loadModel() async {
        guard let url = Bundle.main.url(
            forResource: "EmotionClassifier",
            withExtension: "mlpackage"  // 또는 "mlmodelc" (컴파일된 버전)
        ) else {
            print("[PromptContextClassifier] EmotionClassifier.mlpackage 를 번들에 추가해주세요.")
            return
        }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            model = try await MLModel.load(contentsOf: url, configuration: config)
            print("[PromptContextClassifier] 모델 로드 완료")
        } catch {
            print("[PromptContextClassifier] 모델 로드 실패: \(error)")
        }
    }

    // 텍스트 → EmotionClassification
    // 모델 미로드 시 nil 반환 (파이프라인은 계속 진행)
    func classify(_ text: String) -> EmotionClassification? {
        guard let model else {
            print("[PromptContextClassifier] classify skipped: model not loaded")
            return nil
        }

        let (ids, mask) = tokenizer.encode(text)

        // MLMultiArray 생성 (shape: [1, 128])
        guard
            let idsArray  = try? MLMultiArray(shape: [1, 128], dataType: .int32),
            let maskArray = try? MLMultiArray(shape: [1, 128], dataType: .int32)
        else { return nil }

        for i in 0..<128 {
            idsArray[i]  = NSNumber(value: ids[i])
            maskArray[i] = NSNumber(value: mask[i])
        }

        let input = try? MLDictionaryFeatureProvider(dictionary: [
            "input_ids":      MLFeatureValue(multiArray: idsArray),
            "attention_mask": MLFeatureValue(multiArray: maskArray),
        ])
        guard let input,
              let output = try? model.prediction(from: input),
              let probs  = output.featureValue(for: "probabilities")?.multiArrayValue
        else { return nil }

        // 가장 높은 확률 레이블 선택
        var maxProb: Float = -1
        var maxIdx = 0
        var allProbs: [EmotionLabel: Float] = [:]

        for i in 0..<EmotionLabel.allCases.count {
            let p = probs[i].floatValue
            allProbs[EmotionLabel(rawValue: i) ?? .joy] = p
            if p > maxProb {
                maxProb = p
                maxIdx  = i
            }
        }

        let label = EmotionLabel(rawValue: maxIdx) ?? .joy
        print("[PromptContextClassifier] classify result label=\(label.displayName) confidence=\(maxProb)")
        return EmotionClassification(
            label: label,
            confidence: maxProb,
            allProbabilities: allProbs
        )
    }
}
