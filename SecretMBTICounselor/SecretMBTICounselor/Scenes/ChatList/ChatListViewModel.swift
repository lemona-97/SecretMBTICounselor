//
//  ChatListViewModel.swift
//  SecretMBTICounselor
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ChatListViewModel {
    let mbti: MBTIType
    var renameTarget: ChatSession?
    var renameText: String = ""
    var deleteTarget: ChatSession?

    private let modelContext: ModelContext

    init(mbti: MBTIType, modelContext: ModelContext) {
        self.mbti = mbti
        self.modelContext = modelContext
    }

    /// 새 대화 세션을 만들고 반환.
    func createSession() -> ChatSession {
        let s = ChatSession(mbti: mbti)
        modelContext.insert(s)
        return s
    }

    // MARK: - Rename

    func beginRename(_ session: ChatSession) {
        renameTarget = session
        renameText = session.title
    }

    func confirmRename() {
        guard let target = renameTarget else { return }
        let newTitle = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        target.title = newTitle.isEmpty ? "새 대화" : newTitle
        target.updatedAt = .now
        try? modelContext.save()
        renameTarget = nil
    }

    func cancelRename() {
        renameTarget = nil
    }

    // MARK: - Delete

    func beginDelete(_ session: ChatSession) {
        deleteTarget = session
    }

    func confirmDelete() {
        guard let target = deleteTarget else { return }
        modelContext.delete(target)
        try? modelContext.save()
        deleteTarget = nil
    }

    func cancelDelete() {
        deleteTarget = nil
    }
}
