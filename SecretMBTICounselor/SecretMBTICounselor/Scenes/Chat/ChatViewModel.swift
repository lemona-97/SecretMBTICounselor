//
//  ChatViewModel.swift
//  SecretMBTICounselor
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ChatViewModel {
    let session: ChatSession

    var draft: String = ""
    var mode: InteractionMode = .chat
    var isResponding: Bool = false
    var errorMessage: String?

    let speech: SpeechService
    private let counselor: CounselorService
    private let modelContext: ModelContext

    private var streamTask: Task<Void, Never>?

    init(session: ChatSession, modelContext: ModelContext, knownTerms: [UserTerm] = [], defaultMode: InteractionMode = .chat) {
        self.session = session
        self.modelContext = modelContext
        self.mode = defaultMode
        self.speech = SpeechService()
        self.counselor = CounselorService(mbti: session.mbti, history: session.messages, knownTerms: knownTerms)
    }

    var mbti: MBTIType { session.mbti }

    var sortedMessages: [ChatMessage] {
        session.messages.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Send

    func sendDraft(autoPlayTTS: Bool) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        draft = ""
        Task { await send(text: text, autoPlayTTS: autoPlayTTS) }
    }

    private func send(text: String, autoPlayTTS: Bool) async {
        // 사용자 메시지 저장
        let userMsg = ChatMessage(role: .user, content: text, session: session)
        modelContext.insert(userMsg)
        session.messages.append(userMsg)
        session.updatedAt = .now
        if session.title == "새 대화" {
            session.title = String(text.prefix(20))
        }
        try? modelContext.save()

        // 어시스턴트 자리 잡아두고 스트리밍으로 채움
        let replyMsg = ChatMessage(role: .assistant, content: "", session: session)
        isResponding = true

        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                var inserted = false
                var lastLength = 0
                for try await snapshot in self.counselor.streamReply(to: text) {
                    if !inserted {
                        self.modelContext.insert(replyMsg)
                        self.session.messages.append(replyMsg)
                        inserted = true
                    }
                    // snapshot은 누적된 텍스트이므로, 이전 길이보다 긴 부분만 사용
                    if snapshot.count > lastLength {
                        replyMsg.content = snapshot
                        lastLength = snapshot.count
                    }
                }
                // 스트림이 아무것도 내놓지 않았으면 단발 호출로 폴백
                if !inserted {
                    let full = try await self.counselor.reply(to: text)
                    replyMsg.content = full
                    self.modelContext.insert(replyMsg)
                    self.session.messages.append(replyMsg)
                }
                // [TERM:단어=뜻] 태그 파싱 → SwiftData 저장(기존 단어면 업데이트) → 표시 텍스트에서 제거
                if let extracted = Self.extractTerm(from: replyMsg.content) {
                    replyMsg.content = extracted.cleanedText
                    let descriptor = FetchDescriptor<UserTerm>()
                    let all = (try? self.modelContext.fetch(descriptor)) ?? []
                    if let existing = all.first(where: { $0.word == extracted.word }) {
                        existing.definition = extracted.definition  // 기존 단어 → 뜻만 업데이트
                    } else {
                        self.modelContext.insert(UserTerm(word: extracted.word, definition: extracted.definition))
                    }
                }

                self.session.updatedAt = .now
                try? self.modelContext.save()

                if (self.mode == .voice || autoPlayTTS), !replyMsg.content.isEmpty {
                    self.speech.speak(replyMsg.content, mbti: self.mbti)
                }
            } catch {
                // unsafe 콘텐츠 감지 또는 기타 모델 오류 → 팝업 대신 상담사 말풍선으로 자연스럽게 처리
                let fallback = Self.fallbackMessage(for: self.mbti)
                replyMsg.content = fallback
                if !self.session.messages.contains(where: { $0.id == replyMsg.id }) {
                    self.modelContext.insert(replyMsg)
                    self.session.messages.append(replyMsg)
                }
                try? self.modelContext.save()
            }
            self.isResponding = false
        }
    }

    // MARK: - Voice

    func toggleMic(autoPlayTTS: Bool) {
        if speech.isRecording {
            speech.stopRecording()
            let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                draft = text
                sendDraft(autoPlayTTS: autoPlayTTS)
            }
        } else {
            speech.stopSpeaking()
            Task { await speech.startRecording() }
        }
    }

    func stopSpeaking() { speech.stopSpeaking() }

    // MARK: - Term Extraction

    private struct ExtractedTerm {
        let word: String
        let definition: String
        let cleanedText: String
    }

    /// 응답에서 [TERM:단어=뜻] 태그를 파싱하고 제거한 텍스트를 반환
    private static func extractTerm(from text: String) -> ExtractedTerm? {
        let pattern = #"\[TERM:(.+?)=(.+?)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let wordRange = Range(match.range(at: 1), in: text),
              let defRange = Range(match.range(at: 2), in: text),
              let fullRange = Range(match.range(at: 0), in: text)
        else { return nil }

        let word = String(text[wordRange]).trimmingCharacters(in: .whitespaces)
        let definition = String(text[defRange]).trimmingCharacters(in: .whitespaces)
        let cleaned = text.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return ExtractedTerm(word: word, definition: definition, cleanedText: cleaned)
    }

    // MARK: - Fallback

    /// 모델 오류(unsafe 감지 등) 시 상담사 말투에 맞는 자연스러운 대체 메시지
    private static func fallbackMessage(for mbti: MBTIType) -> String {
        switch mbti {
        case .intj: return "음, 그 부분은 제가 답하기 어렵네요.\n다른 이야기를 해볼까요?"
        case .intp: return "흥미로운 질문이긴 한데, 솔직히 잘 모르겠어요.\n다른 방향으로 생각해볼까요?"
        case .entj: return "그 부분은 제 영역 밖이에요.\n지금 가장 중요한 게 뭔지 다시 얘기해봐요."
        case .entp: return "오, 그건 저도 잘 모르겠는데요.\n근데 이렇게 생각해보면 어때요?"
        case .infj: return "그 부분은 제가 잘 모르겠어요.\n지금 마음은 어떠세요?"
        case .infp: return "솔직히 그건 잘 모르겠어요.\n괜찮아요, 다른 얘기 해도 돼요."
        case .enfj: return "그 부분은 제가 답하기 어렵네요.\n지금 가장 마음에 걸리는 건 뭐예요?"
        case .enfp: return "아 그건 저도 잘 모르겠어요!\n근데 다른 데서 실마리를 찾아볼 수도 있지 않을까요?"
        case .istj: return "그 부분은 제가 정확히 답하기 어렵네요.\n다른 주제로 넘어가볼게요."
        case .isfj: return "혹시 다른 이야기를 해도 괜찮을까요?\n그 부분은 제가 잘 모르겠어서요."
        case .estj: return "그건 제 답변 범위를 벗어났어요.\n다른 걸로 바로 가보죠."
        case .esfj: return "어머, 그 부분은 제가 잘 모르겠어요.\n다른 얘기 해요, 괜찮아요!"
        case .istp: return "모르겠어요, 그건.\n다른 걸 얘기해봐요."
        case .isfp: return "그건 잘 모르겠어요.\n지금 느끼는 감정이 뭔지 얘기해줄래요?"
        case .estp: return "그건 저도 모르겠는데요.\n일단 다른 얘기 해봐요!"
        case .esfp: return "앗, 그건 저도 모르겠어요!\n다른 얘기 해요, 더 재밌는 거로!"
        }
    }

    // MARK: - Lifecycle

    func cleanup() {
        streamTask?.cancel()
        speech.stopRecording()
        speech.stopSpeaking()
    }
}
