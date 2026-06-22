import Foundation
import CryptoKit

enum UserRole: String, Codable, CaseIterable {
    case elderly = "elderly"
    case child = "child"

    var displayName: String {
        switch self {
        case .elderly: return "老人"
        case .child: return "子女"
        }
    }

    var icon: String {
        switch self {
        case .elderly: return "figure.walk"
        case .child: return "person.fill"
        }
    }
}

struct User: Identifiable, Codable, Equatable {
    let id: String
    var nickname: String
    var role: UserRole
    var boundUserId: String?
    var boundUserName: String?
    var createdAt: Date

    var isBound: Bool {
        boundUserId != nil
    }


    init(
        id: String = UUID().uuidString,
        nickname: String,
        role: UserRole,
        boundUserId: String? = nil,
        boundUserName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.role = role
        self.boundUserId = boundUserId
        self.boundUserName = boundUserName
        self.createdAt = createdAt
    }
}

enum QuickReplyEmoji: String, CaseIterable, Identifiable, Codable {
    case confirm
    case thanks
    case happy
    case unwell

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .confirm: return "👍"
        case .thanks:  return "🙏"
        case .happy:   return "😊"
        case .unwell:  return "😟"
        }
    }

    var displayText: String {
        switch self {
        case .confirm: return "已确认服药"
        case .thanks:  return "谢谢提醒"
        case .happy:   return "今天感觉不错"
        case .unwell:  return "有点不舒服"
        }
    }

    var notificationTitle: String {
        "❤️ 老人回复"
    }

    var notificationBody: String? { nil }

    func notificationBody(senderName: String) -> String {
        "「\(senderName)」\(emoji) \(displayText)"
    }
}

enum NotificationKind: String, Codable {
    case system
    case reply
}

struct NotificationRecord: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let kind: NotificationKind
    let title: String
    let body: String
    let medicationName: String?
    let recipientUserId: String
    let senderUserId: String?
    let replyEmojiRaw: String?
    let timestamp: Date
    let isRead: Bool

    enum NotificationType: String, Codable {
        case taken = "taken"
        case missed = "missed"
        case care = "care"
        case unwell = "unwell"
        case reply = "reply"
    }

    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        kind: NotificationKind = .system,
        title: String,
        body: String,
        medicationName: String? = nil,
        recipientUserId: String,
        senderUserId: String? = nil,
        replyEmojiRaw: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.kind = kind
        self.title = title
        self.body = body
        self.medicationName = medicationName
        self.recipientUserId = recipientUserId
        self.senderUserId = senderUserId
        self.replyEmojiRaw = replyEmojiRaw
        self.timestamp = timestamp
        self.isRead = isRead
    }

    var replyEmoji: QuickReplyEmoji? {
        guard let raw = replyEmojiRaw else { return nil }
        return QuickReplyEmoji(rawValue: raw)
    }
}
