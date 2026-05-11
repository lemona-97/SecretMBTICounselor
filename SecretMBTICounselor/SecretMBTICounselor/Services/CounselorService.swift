//
//  CounselorService.swift
//  SecretMBTICounselor
//
//  Apple FoundationModels (on-device) 래퍼.
//  MBTI별 페르소나 instructions 를 주입해 세션을 유지한다.
//

import Foundation
import FoundationModels

@MainActor
@Observable
final class CounselorService {
    let mbti: MBTIType
    private var _session: LanguageModelSession?
    private var sessionTask: Task<LanguageModelSession, Never>?
    private let instructions: String
    private var didInjectHistory = false
    private let priorHistory: [ChatMessage]

    // 파이프라인 진행 단계 — UI에서 관찰
    var pipelineStageLabel: String = ""

    private static func log(_ message: String) {
        print("[CounselorService] \(message)")
    }

    init(mbti: MBTIType, history: [ChatMessage] = [], knownTerms: [UserTerm] = [], notionTerms: [NotionTerm] = []) {
        self.mbti = mbti
        self.priorHistory = history.sorted { $0.createdAt < $1.createdAt }
        self.instructions = Self.buildInstructions(mbti: mbti, knownTerms: knownTerms, notionTerms: notionTerms)
    }

    // 세션 생성은 첫 응답 요청까지 지연한다. 빈 채팅 화면 진입만으로 모델 세션을 만들지 않는다.
    private var session: LanguageModelSession {
        get async {
            if let s = _session { return s }
            if sessionTask == nil {
                let instructions = instructions
                Self.log("creating LanguageModelSession lazily")
                sessionTask = Task.detached {
                    LanguageModelSession(instructions: instructions)
                }
            }
            guard let sessionTask else {
                Self.log("sessionTask missing, creating fallback session synchronously")
                let s = LanguageModelSession(instructions: instructions)
                _session = s
                return s
            }
            let s = await sessionTask.value
            _session = s
            Self.log("LanguageModelSession ready")
            return s
        }
    }

    /// 메모리 해제 — ChatView dismiss 시 호출
    func releaseSession() {
        _session = nil
        sessionTask = nil
        didInjectHistory = false
    }

    private static func buildInstructions(mbti: MBTIType, knownTerms: [UserTerm], notionTerms: [NotionTerm]) -> String {
        var base = mbti.systemInstructions

        // Notion DB에서 가져온 신조어 — 컨텍스트 폭주 방지를 위해 상한
        if !notionTerms.isEmpty {
            let capped = Array(notionTerms.prefix(120))
            let lines = capped.map { $0.instructionLine }.joined(separator: "\n")
            base += """

            [Background vocabulary — for your understanding only]
            The following slang and terms may appear in conversation. Use this as silent background knowledge to understand what the user means. Do NOT mention, explain, or reference these definitions in your responses. Simply understand and respond naturally.
            \(lines)
            """
        }

        if !knownTerms.isEmpty {
            let lines = knownTerms.map { "- \($0.word): \($0.definition)" }.joined(separator: "\n")
            base += """

            [User-defined terms — use these meanings exactly when these words appear]
            \(lines)
            """
        }

        return base
    }

    // MARK: - 단발 / 스트리밍 (파이프라인 외 폴백용)

    func reply(to userText: String) async throws -> String {
        Self.log("one-shot reply requested textLength=\(userText.count)")
        let prompt = composedPrompt(for: userText)
        let s = await session
        let response = try await s.respond(to: prompt)
        Self.log("one-shot reply completed responseLength=\(response.content.count)")
        return deduplicateResponse(response.content)
    }

    func streamReply(to userText: String) -> AsyncThrowingStream<String, Error> {
        let prompt = composedPrompt(for: userText)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let s = await self.session
                    for try await partial in s.streamResponse(to: prompt) {
                        continuation.yield(Self.extractText(partial))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Pipeline (세션 재사용 — 신규 LanguageModelSession 생성 없음)
    //
    // 기존: 메시지 1개당 최대 7개 신규 세션 → NSConcreteAttributedString 10만+ 누수
    // 현재: self.session 재사용 + Core ML 감정 컨텍스트를 프롬프트에 직접 주입

    func pipelineStreamReply(to userText: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    self.pipelineStageLabel = "답변 생성 중"
                    Self.log("pipeline start textLength=\(userText.count)")
                    let emotionContext = await PromptContextClassifier.shared.classify(userText)
                    if let emotionContext {
                        Self.log("emotion classified label=\(emotionContext.label.displayName) confidence=\(emotionContext.confidence)")
                    } else {
                        Self.log("emotion classification unavailable")
                    }
                    let prompt = self.enrichedPrompt(for: userText, emotionContext: emotionContext)
                    let s = await self.session
                    Self.log("streamResponse begin promptLength=\(prompt.count)")
                    var didLogFirstChunk = false
                    for try await partial in s.streamResponse(to: prompt) {
                        if !didLogFirstChunk {
                            Self.log("streamResponse first chunk arrived")
                            didLogFirstChunk = true
                        }
                        continuation.yield(Self.extractText(partial))
                    }
                    self.pipelineStageLabel = ""
                    Self.log("pipeline stream finished")
                    continuation.finish()
                } catch {
                    self.pipelineStageLabel = ""
                    Self.log("pipeline stream failed error=\(String(describing: error))")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func enrichedPrompt(for userText: String, emotionContext: EmotionClassification?) -> String {
        let base = composedPrompt(for: userText)
        guard let emotion = emotionContext, emotion.isHighConfidence else { return base }
        return "\(emotion.promptContext)\n\n\(base)"
    }

    // MARK: - Helpers

    private func composedPrompt(for userText: String) -> String {
        guard !didInjectHistory, !priorHistory.isEmpty else { return userText }
        didInjectHistory = true
        let recent = priorHistory.suffix(12).map { m in
            let who = m.role == .user ? "User" : mbti.nickname
            return "\(who): \(m.content)"
        }.joined(separator: "\n")
        return """
        [Previous conversation — use for context only, do not mention it explicitly]
        \(recent)

        [Current user message]
        \(userText)
        """
    }

    private static func extractText(_ any: Any) -> String {
        if let s = any as? String { return s }
        let mirror = Mirror(reflecting: any)
        if let content = mirror.children.first(where: { $0.label == "content" })?.value as? String {
            return content
        }
        return String(describing: any)
    }

    private func deduplicateResponse(_ text: String) -> String {
        let sentences = text.split(separator: ".", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: .whitespaces) }
        var result: [String] = []
        for sentence in sentences {
            if let last = result.last, similarityScore(sentence, last) > 0.8 { continue }
            result.append(sentence)
        }
        return result.joined(separator: ". ") + (result.isEmpty ? "" : ".")
    }

    private func similarityScore(_ s1: String, _ s2: String) -> Double {
        let words1 = Set(s1.lowercased().split(separator: " ").map(String.init))
        let words2 = Set(s2.lowercased().split(separator: " ").map(String.init))
        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }
}
