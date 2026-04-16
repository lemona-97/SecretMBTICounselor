//
//  ChatModels.swift
//  SecretMBTICounselor
//

import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var mbtiRaw: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []

    init(mbti: MBTIType, title: String = "새 대화") {
        self.id = UUID()
        self.mbtiRaw = mbti.rawValue
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
    }

    var mbti: MBTIType { MBTIType(rawValue: mbtiRaw) ?? .infp }

    var preview: String {
        messages.sorted { $0.createdAt < $1.createdAt }.last?.content ?? "아직 대화 내용이 없어요"
    }
}

enum ChatRole: String, Codable, Sendable {
    case user, assistant
}

@Model
final class ChatMessage {
    var id: UUID
    var roleRaw: String
    var content: String
    var createdAt: Date
    var session: ChatSession?

    init(role: ChatRole, content: String, session: ChatSession? = nil) {
        self.id = UUID()
        self.roleRaw = role.rawValue
        self.content = content
        self.createdAt = .now
        self.session = session
    }

    var role: ChatRole { ChatRole(rawValue: roleRaw) ?? .user }
}
