import Foundation
import SwiftUI

@MainActor
final class AuthStore: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var allUsers: [User] = []
    @Published var notificationRecords: [NotificationRecord] = []

    private let usersKey = "medguard_users"
    private let notificationsKey = "medguard_notification_records"
    private let currentUserKey = "medguard_current_user"

    static let shared = AuthStore()

    init() {
        loadData()
    }

    var hasProfile: Bool {
        !allUsers.isEmpty
    }

    // MARK: - Unlock & Setup

    /// Call after Face ID succeeds to enter the app
    func unlock() {
        guard let user = currentUser ?? allUsers.first else { return }
        currentUser = user
        isLoggedIn = true
        saveCurrentUser()
    }

    /// First-time profile setup
    func setupProfile(nickname: String, role: UserRole) -> User {
        let user = User(nickname: nickname, role: role)
        allUsers.append(user)
        saveUsers()
        currentUser = user
        isLoggedIn = true
        saveCurrentUser()
        return user
    }

    func switchToUser(_ user: User) {
        currentUser = user
        isLoggedIn = true
        saveCurrentUser()
        // Continue without Face ID since user explicitly chose
    }

    // MARK: - Session

    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }

    func deleteAccount() {
        guard let user = currentUser else { return }

        if let otherIdx = allUsers.firstIndex(where: { $0.id == user.boundUserId }) {
            var other = allUsers[otherIdx]
            other.boundUserId = nil
            other.boundUserName = nil
            allUsers[otherIdx] = other
        }

        allUsers.removeAll { $0.id == user.id }
        notificationRecords.removeAll()
        saveUsers()
        saveNotificationRecords()
        logout()
    }

    // MARK: - One-Time Binding Code (6-digit, 5-min TTL)

    @Published var currentBindingCode: BindingCode?

    struct BindingCode {
        let code: String
        let elderlyId: String
        let expiresAt: Date

        var isValid: Bool { expiresAt > Date() }
        var timeRemaining: TimeInterval { max(0, expiresAt.timeIntervalSinceNow) }
    }

    /// Elderly generates a 6-digit code valid for 5 minutes
    func generateBindingCode() -> BindingCode {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let bindingCode = BindingCode(
            code: code,
            elderlyId: currentUser?.id ?? "",
            expiresAt: Date().addingTimeInterval(300)
        )
        currentBindingCode = bindingCode
        // Auto-expire after 5 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
            if self?.currentBindingCode?.code == code {
                self?.currentBindingCode = nil
            }
        }
        return bindingCode
    }

    enum BindError: LocalizedError {
        case notChildRole
        case noCode
        case codeExpired
        case selfBind
        case elderlyNotFound

        var errorDescription: String? {
            switch self {
            case .notChildRole: return "只有子女账号可以绑定老人"
            case .noCode: return "绑定码无效"
            case .codeExpired: return "绑定码已过期（5分钟有效），请让老人重新生成"
            case .selfBind: return "不能绑定自己的账号"
            case .elderlyNotFound: return "未找到对应的老人账号"
            }
        }
    }

    /// Child enters the 6-digit code to bind
    func bindWithCode(_ code: String) throws {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 6, trimmed.allSatisfy(\.isNumber) else {
            throw BindError.noCode
        }

        guard let childUser = currentUser, childUser.role == .child else {
            throw BindError.notChildRole
        }

        guard let bindingCode = currentBindingCode, bindingCode.code == trimmed else {
            throw BindError.noCode
        }

        guard bindingCode.isValid else {
            currentBindingCode = nil
            throw BindError.codeExpired
        }

        guard bindingCode.elderlyId != childUser.id else {
            throw BindError.selfBind
        }

        guard let elderlyIdx = allUsers.firstIndex(where: { $0.id == bindingCode.elderlyId }) else {
            throw BindError.elderlyNotFound
        }

        // Bind elderly
        var elderly = allUsers[elderlyIdx]
        elderly.boundUserId = childUser.id
        elderly.boundUserName = childUser.nickname
        allUsers[elderlyIdx] = elderly

        // Bind child
        var child = childUser
        child.boundUserId = elderly.id
        child.boundUserName = elderly.nickname
        if let childIdx = allUsers.firstIndex(where: { $0.id == childUser.id }) {
            allUsers[childIdx] = child
        }
        currentUser = child

        // Delete the code immediately (one-time use)
        currentBindingCode = nil

        saveUsers()
        saveCurrentUser()
    }

    func unbind() {
        guard let user = currentUser, let boundId = user.boundUserId else { return }

        if let boundIdx = allUsers.firstIndex(where: { $0.id == boundId }) {
            var other = allUsers[boundIdx]
            other.boundUserId = nil
            other.boundUserName = nil
            allUsers[boundIdx] = other
        }

        var updated = user
        updated.boundUserId = nil
        updated.boundUserName = nil

        if let idx = allUsers.firstIndex(where: { $0.id == updated.id }) {
            allUsers[idx] = updated
        }
        currentUser = updated

        saveUsers()
        saveCurrentUser()
    }

    // MARK: - Notification Records

    func addNotificationRecord(_ record: NotificationRecord) {
        notificationRecords.insert(record, at: 0)
        saveNotificationRecords()
    }

    func markNotificationRead(_ id: String) {
        if let idx = notificationRecords.firstIndex(where: { $0.id == id }) {
            var record = notificationRecords[idx]
            record = NotificationRecord(
                id: record.id,
                type: record.type,
                title: record.title,
                body: record.body,
                medicationName: record.medicationName,
                recipientUserId: record.recipientUserId,
                timestamp: record.timestamp,
                isRead: true
            )
            notificationRecords[idx] = record
            saveNotificationRecords()
        }
    }

    var unreadCount: Int {
        guard let userId = currentUser?.id else { return 0 }
        return notificationRecords.filter { !$0.isRead && $0.recipientUserId == userId }.count
    }

    func notifications(for userId: String) -> [NotificationRecord] {
        notificationRecords.filter { $0.recipientUserId == userId }
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            allUsers = users
        }
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let records = try? JSONDecoder().decode([NotificationRecord].self, from: data) {
            notificationRecords = records
        }
        // Load saved user but don't auto-login — Face ID required
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data),
           allUsers.contains(where: { $0.id == user.id }) {
            currentUser = user
        }
    }

    private func saveUsers() {
        if let data = try? JSONEncoder().encode(allUsers) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    private func saveCurrentUser() {
        if let user = currentUser, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        }
    }

    private func saveNotificationRecords() {
        if let data = try? JSONEncoder().encode(notificationRecords) {
            UserDefaults.standard.set(data, forKey: notificationsKey)
        }
    }
}

// MARK: - Errors

enum BindingError: LocalizedError {
    case invalidCode
    case elderlyNotFound
    case notChildRole

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "邀请码无效或已被使用"
        case .elderlyNotFound: return "未找到对应老人账号"
        case .notChildRole: return "只有子女账号可以绑定老人"
        }
    }
}
