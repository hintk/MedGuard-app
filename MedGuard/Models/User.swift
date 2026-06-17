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

struct NotificationRecord: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let medicationName: String?
    let recipientUserId: String
    let timestamp: Date
    let isRead: Bool

    enum NotificationType: String, Codable {
        case taken = "taken"
        case missed = "missed"
        case care = "care"
    }

    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        body: String,
        medicationName: String? = nil,
        recipientUserId: String,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.medicationName = medicationName
        self.recipientUserId = recipientUserId
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
