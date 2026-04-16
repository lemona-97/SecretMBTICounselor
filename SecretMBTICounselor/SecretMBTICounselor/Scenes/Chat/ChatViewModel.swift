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

    init(session: ChatSession, modelContext: ModelContext, defaultMode: InteractionMode = .chat) {
        self.session = session
        self.modelContext = modelContext
        self.mode = defaultMode
        self.speech = SpeechService()
        self.counselor = CounselorService(mbti: session.mbti, history: session.messages)
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
                self.session.updatedAt = .now
                try? self.modelContext.save()

                if (self.mode == .voice || autoPlayTTS), !replyMsg.content.isEmpty {
                    self.speech.speak(replyMsg.content, mbti: self.mbti)
                }
            } catch {
                self.errorMessage = error.localizedDescription
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

    // MARK: - Lifecycle

    func cleanup() {
        streamTask?.cancel()
        speech.stopRecording()
        speech.stopSpeaking()
    }
}
