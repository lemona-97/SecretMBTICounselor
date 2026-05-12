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

    private static func log(_ message: String) {
        print("[ChatPipeline] \(message)")
    }

    init(session: ChatSession, modelContext: ModelContext, knownTerms: [UserTerm] = [], notionTerms: [NotionTerm] = [], defaultMode: InteractionMode = .chat) {
        self.session = session
        self.modelContext = modelContext
        self.mode = defaultMode
        self.speech = SpeechService()
        self.counselor = CounselorService(mbti: session.mbti, history: session.messages, knownTerms: knownTerms, notionTerms: notionTerms)
        self.sortedMessages = session.messages.sorted { $0.createdAt < $1.createdAt }
    }

    var mbti: MBTIType { session.mbti }

    var pipelineStageLabel: String { counselor.pipelineStageLabel }

    private(set) var sortedMessages: [ChatMessage] = []
    // 스크롤 트리거용 — sortedMessages 재정렬 없이 onChange에서 사용
    private(set) var lastResponseContent: String = ""

    private func appendToSorted(_ msg: ChatMessage) {
        // 메시지는 항상 시간순 추가이므로 append만으로 정렬 유지
        sortedMessages.append(msg)
    }

    // MARK: - Send

    func sendDraft(autoPlayTTS: Bool) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        Self.log("sendDraft accepted mode=\(mode.rawValue) textLength=\(text.count)")
        draft = ""
        Task { await send(text: text, autoPlayTTS: autoPlayTTS) }
    }

    private func send(text: String, autoPlayTTS: Bool) async {
        Self.log("send begin sessionID=\(session.id) persisted=\(session.modelContext != nil)")
        if session.modelContext == nil {
            Self.log("persisting draft session before first message")
            modelContext.insert(session)
        }

        // 사용자 메시지 — in-memory 등록만, save는 스트림 완료 후 assistant msg와 함께 한 번에
        let userMsg = ChatMessage(role: .user, content: text, session: session)
        modelContext.insert(userMsg)
        session.messages.append(userMsg)
        appendToSorted(userMsg)
        Self.log("user message inserted messageID=\(userMsg.id) totalMessages=\(session.messages.count)")

        // 어시스턴트 응답 — SwiftData에는 스트림 완료 후 한 번만 insert
        // (스트리밍 중 @Model property 변경 → SwiftData notification → ChatListView 매 토큰 re-render 방지)
        let replyMsg = ChatMessage(role: .assistant, content: "", session: session)
        isResponding = true
        Self.log("assistant placeholder created messageID=\(replyMsg.id)")

        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self else { return }
            // do-catch 바깥에 선언 → catch 블록에서도 참조 가능
            var shownInUI = false
            do {
                var lastLength = 0
                Self.log("starting pipeline stream")
                for try await snapshot in self.counselor.pipelineStreamReply(to: text) {
                    if !shownInUI {
                        // UI 리스트에만 추가 — SwiftData insert는 스트림 완료 후에 함
                        self.appendToSorted(replyMsg)
                        shownInUI = true
                        Self.log("first streamed response chunk received")
                    }
                    if snapshot.count > lastLength {
                        // 미삽입 상태이므로 SwiftData notification 없이 in-memory만 변경됨
                        replyMsg.content = snapshot
                        self.lastResponseContent = snapshot
                        lastLength = snapshot.count
                    }
                }

                // 스트림이 아무것도 내놓지 않았으면 단발 호출로 폴백
                if !shownInUI {
                    Self.log("stream produced no chunks, falling back to one-shot reply")
                    let full = try await self.counselor.reply(to: text)
                    replyMsg.content = full
                    self.lastResponseContent = full
                    self.appendToSorted(replyMsg)
                    shownInUI = true
                }
                Self.log("response generation finished responseLength=\(replyMsg.content.count)")

                // [TERM:단어=뜻] 태그 파싱
                if let extracted = Self.extractTerm(from: replyMsg.content) {
                    Self.log("TERM tag extracted word=\(extracted.word)")
                    replyMsg.content = extracted.cleanedText
                    let descriptor = FetchDescriptor<UserTerm>()
                    let all = (try? self.modelContext.fetch(descriptor)) ?? []
                    if let existing = all.first(where: { $0.word == extracted.word }) {
                        existing.definition = extracted.definition
                    } else {
                        self.modelContext.insert(UserTerm(word: extracted.word, definition: extracted.definition))
                    }
                }

                // 스트림 완료 후 단 한 번 모든 SwiftData 변경을 커밋
                // → @Query sessions 알림이 대화 턴당 1회만 발생 (이전: user save + assistant save = 2회)
                self.modelContext.insert(replyMsg)
                self.session.messages.append(replyMsg)
                self.session.previewText = String(replyMsg.content.prefix(60))
                self.session.updatedAt = .now
                if self.session.title == "새 대화" {
                    self.session.title = String(text.prefix(20))
                }
                try? self.modelContext.save()
                Self.log("modelContext.save completed sessionTitle=\(self.session.title)")

                if (self.mode == .voice || autoPlayTTS), !replyMsg.content.isEmpty {
                    Self.log("starting TTS playback")
                    self.speech.speak(replyMsg.content, mbti: self.mbti)
                }
            } catch {
                Self.log("pipeline failed error=\(String(describing: error))")
                let fallback = Self.fallbackMessage()
                replyMsg.content = fallback
                if !shownInUI {
                    self.appendToSorted(replyMsg)
                }
                if !self.session.messages.contains(where: { $0.id == replyMsg.id }) {
                    self.modelContext.insert(replyMsg)
                    self.session.messages.append(replyMsg)
                }
                self.session.updatedAt = .now
                if self.session.title == "새 대화" {
                    self.session.title = String(text.prefix(20))
                }
                try? self.modelContext.save()
                Self.log("fallback response saved")
            }
            self.isResponding = false
            Self.log("send finished isResponding=false")
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
    private static func fallbackMessage() -> String {
        return "죄송합니다 잘 이해하지 못했어요"
    }

    // MARK: - Lifecycle

    func cleanup() {
        streamTask?.cancel()
        speech.stopRecording()
        speech.stopSpeaking()
        counselor.releaseSession()
    }
}
