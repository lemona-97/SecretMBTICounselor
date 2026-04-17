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
    private var session: LanguageModelSession
    private var didInjectHistory = false
    private let priorHistory: [ChatMessage]

    init(mbti: MBTIType, history: [ChatMessage] = [], knownTerms: [UserTerm] = [], notionTerms: [NotionTerm] = []) {
        self.mbti = mbti
        self.priorHistory = history.sorted { $0.createdAt < $1.createdAt }
        let instructions = Self.buildInstructions(mbti: mbti, knownTerms: knownTerms, notionTerms: notionTerms)
        self.session = LanguageModelSession(instructions: instructions)
    }

    private static func buildInstructions(mbti: MBTIType, knownTerms: [UserTerm], notionTerms: [NotionTerm]) -> String {
        var base = mbti.systemInstructions

        // Notion DB에서 가져온 신조어
        if !notionTerms.isEmpty {
            let lines = notionTerms.map { $0.instructionLine }.joined(separator: "\n")
            base += """

            [Background vocabulary — for your understanding only]
            The following slang and terms may appear in conversation. Use this as silent background knowledge to understand what the user means. Do NOT mention, explain, or reference these definitions in your responses. Simply understand and respond naturally.
            \(lines)
            """
        }

        // 유저가 대화 중 알려준 단어
        if !knownTerms.isEmpty {
            let lines = knownTerms.map { "- \($0.word): \($0.definition)" }.joined(separator: "\n")
            base += """

            [User-defined terms — use these meanings exactly when these words appear]
            \(lines)
            """
        }

        return base
    }

    /// 단발 응답
    func reply(to userText: String) async throws -> String {
        let prompt = composedPrompt(for: userText)
        let response = try await session.respond(to: prompt)
        return deduplicateResponse(response.content)
    }

    /// 스트리밍 응답 (누적 스냅샷 문자열)
    func streamReply(to userText: String) -> AsyncThrowingStream<String, Error> {
        let prompt = composedPrompt(for: userText)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await partial in session.streamResponse(to: prompt) {
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

    /// 연속된 중복 문장 제거 (반복 표현 완화)
    private func deduplicateResponse(_ text: String) -> String {
        let sentences = text.split(separator: ".", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: .whitespaces) }
        var result: [String] = []

        for sentence in sentences {
            // 이전 문장과 유사도가 높으면 스킵 (80% 이상 겹침)
            if let lastSentence = result.last,
               similarityScore(sentence, lastSentence) > 0.8 {
                continue
            }
            result.append(sentence)
        }

        return result.joined(separator: ". ") + (result.isEmpty ? "" : ".")
    }

    /// 두 문자열의 유사도 점수 (0.0 ~ 1.0)
    private func similarityScore(_ s1: String, _ s2: String) -> Double {
        let words1 = Set(s1.lowercased().split(separator: " ").map(String.init))
        let words2 = Set(s2.lowercased().split(separator: " ").map(String.init))

        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count

        return union == 0 ? 0 : Double(intersection) / Double(union)
    }
}
