import Foundation

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
    var phone: String
    var passwordHash: String
    var nickname: String
    var role: UserRole
    var boundUserId: String?
    var boundUserName: String?
    var boundUserPhone: String?
    var createdAt: Date

    var isBound: Bool {
        boundUserId != nil
    }

    var inviteCode: String {
        String(id.prefix(8)).uppercased()
    }

    init(
        id: String = UUID().uuidString,
        phone: String,
        passwordHash: String,
        nickname: String,
        role: UserRole,
        boundUserId: String? = nil,
        boundUserName: String? = nil,
        boundUserPhone: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.phone = phone
        self.passwordHash = passwordHash
        self.nickname = nickname
        self.role = role
        self.boundUserId = boundUserId
        self.boundUserName = boundUserName
        self.boundUserPhone = boundUserPhone
        self.createdAt = createdAt
    }
}

struct BindingRequest: Identifiable, Codable {
    let id: String
    let elderlyId: String
    let elderlyName: String
    let elderlyPhone: String
    let elderlyInviteCode: String
    let childId: String
    let childName: String
    let childPhone: String
}

struct NotificationRecord: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let medicationName: String?
    let timestamp: Date
    let isRead: Bool

    enum NotificationType: String, Codable {
        case taken = "taken"
        case missed = "missed"
    }

    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        body: String,
        medicationName: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.medicationName = medicationName
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
