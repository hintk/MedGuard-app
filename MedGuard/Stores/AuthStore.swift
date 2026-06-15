import Foundation
import SwiftUI
import CryptoKit

@MainActor
final class AuthStore: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var allUsers: [User] = []
    @Published var bindingRequests: [BindingRequest] = []
    @Published var notificationRecords: [NotificationRecord] = []

    private let usersKey = "medguard_users"
    private let bindingRequestsKey = "medguard_binding_requests"
    private let notificationsKey = "medguard_notification_records"
    private let currentUserKey = "medguard_current_user"

    static let shared = AuthStore()

    init() {
        loadData()
    }

    // MARK: - Auth Actions

    func register(phone: String, password: String, nickname: String, role: UserRole) throws -> User {
        guard !phone.isEmpty, phone.count >= 11 else {
            throw AuthError.invalidPhone
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        guard !nickname.isEmpty else {
            throw AuthError.emptyNickname
        }
        guard !allUsers.contains(where: { $0.phone == phone }) else {
            throw AuthError.phoneAlreadyRegistered
        }

        let user = User(
            phone: phone,
            passwordHash: hashPassword(password),
            nickname: nickname,
            role: role
        )
        allUsers.append(user)
        saveUsers()
        currentUser = user
        isLoggedIn = true
        saveCurrentUser()
        return user
    }

    func login(phone: String, password: String) throws -> User {
        guard !phone.isEmpty else { throw AuthError.emptyField }
        guard !password.isEmpty else { throw AuthError.emptyField }

        guard let user = allUsers.first(where: { $0.phone == phone }) else {
            throw AuthError.userNotFound
        }
        guard user.passwordHash == hashPassword(password) else {
            throw AuthError.wrongPassword
        }
        currentUser = user
        isLoggedIn = true
        saveCurrentUser()
        return user
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }

    func deleteAccount() {
        guard let user = currentUser else { return }

        if let otherUserIdx = allUsers.firstIndex(where: { $0.id == user.boundUserId }) {
            var other = allUsers[otherUserIdx]
            other.boundUserId = nil
            other.boundUserName = nil
            other.boundUserPhone = nil
            allUsers[otherUserIdx] = other
        }

        allUsers.removeAll { $0.id == user.id }
        bindingRequests.removeAll { $0.elderlyId == user.id || $0.childId == user.id }
        notificationRecords.removeAll()
        saveUsers()
        saveBindingRequests()
        logout()
    }

    // MARK: - Binding Actions

    func sendBindingRequest() -> BindingRequest? {
        guard let user = currentUser, user.role == .elderly else { return nil }

        let request = BindingRequest(
            id: UUID().uuidString,
            elderlyId: user.id,
            elderlyName: user.nickname,
            elderlyPhone: user.phone,
            elderlyInviteCode: user.inviteCode,
            childId: "",
            childName: "",
            childPhone: ""
        )
        bindingRequests.append(request)
        saveBindingRequests()
        return request
    }

    func bindByCode(_ code: String, childName: String, childPhone: String) throws {
        guard let request = bindingRequests.first(where: {
            $0.elderlyInviteCode.uppercased() == code.uppercased() && $0.childId.isEmpty
        }) else {
            throw BindingError.invalidCode
        }

        guard let elderlyIdx = allUsers.firstIndex(where: { $0.id == request.elderlyId }) else {
            throw BindingError.elderlyNotFound
        }

        var elderlyUser = allUsers[elderlyIdx]
        elderlyUser.boundUserId = currentUser?.id
        elderlyUser.boundUserName = currentUser?.nickname
        elderlyUser.boundUserPhone = currentUser?.phone
        allUsers[elderlyIdx] = elderlyUser

        var childUser = currentUser
        childUser?.boundUserId = elderlyUser.id
        childUser?.boundUserName = elderlyUser.nickname
        childUser?.boundUserPhone = elderlyUser.phone

        if let idx = allUsers.firstIndex(where: { $0.id == childUser?.id }) {
            allUsers[idx] = childUser!
        }

        currentUser = childUser

        let newRequest = BindingRequest(
            id: request.id,
            elderlyId: request.elderlyId,
            elderlyName: request.elderlyName,
            elderlyPhone: request.elderlyPhone,
            elderlyInviteCode: request.elderlyInviteCode,
            childId: childUser?.id ?? "",
            childName: childUser?.nickname ?? "",
            childPhone: childUser?.phone ?? ""
        )
        if let reqIdx = bindingRequests.firstIndex(where: { $0.id == request.id }) {
            bindingRequests[reqIdx] = newRequest
        }

        saveUsers()
        saveCurrentUser()
        saveBindingRequests()
    }

    func unbind() {
        guard let user = currentUser, let boundId = user.boundUserId else { return }

        if let boundIdx = allUsers.firstIndex(where: { $0.id == boundId }) {
            var other = allUsers[boundIdx]
            other.boundUserId = nil
            other.boundUserName = nil
            other.boundUserPhone = nil
            allUsers[boundIdx] = other
        }

        var updatedUser = user
        updatedUser.boundUserId = nil
        updatedUser.boundUserName = nil
        updatedUser.boundUserPhone = nil

        if let idx = allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
            allUsers[idx] = updatedUser
        }
        currentUser = updatedUser

        bindingRequests.removeAll { $0.elderlyId == user.id || $0.childId == user.id }

        saveUsers()
        saveCurrentUser()
        saveBindingRequests()
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
                timestamp: record.timestamp,
                isRead: true
            )
            notificationRecords[idx] = record
            saveNotificationRecords()
        }
    }

    var unreadCount: Int {
        notificationRecords.filter { !$0.isRead }.count
    }

    // MARK: - Helpers

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            allUsers = users
        }
        if let data = UserDefaults.standard.data(forKey: bindingRequestsKey),
           let requests = try? JSONDecoder().decode([BindingRequest].self, from: data) {
            bindingRequests = requests
        }
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let records = try? JSONDecoder().decode([NotificationRecord].self, from: data) {
            notificationRecords = records
        }
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            if allUsers.contains(where: { $0.id == user.id }) {
                currentUser = user
                isLoggedIn = true
            }
        }
    }

    private func saveUsers() {
        if let data = try? JSONEncoder().encode(allUsers) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    private func saveBindingRequests() {
        if let data = try? JSONEncoder().encode(bindingRequests) {
            UserDefaults.standard.set(data, forKey: bindingRequestsKey)
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

enum AuthError: LocalizedError {
    case invalidPhone
    case weakPassword
    case emptyNickname
    case emptyField
    case phoneAlreadyRegistered
    case userNotFound
    case wrongPassword

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "请输入正确的手机号（至少11位）"
        case .weakPassword: return "密码至少需要6位"
        case .emptyNickname: return "请输入昵称"
        case .emptyField: return "请填写所有字段"
        case .phoneAlreadyRegistered: return "该手机号已注册"
        case .userNotFound: return "用户不存在"
        case .wrongPassword: return "密码错误"
        }
    }
}

enum BindingError: LocalizedError {
    case invalidCode
    case elderlyNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "邀请码无效或已被使用"
        case .elderlyNotFound: return "未找到对应老人账号"
        }
    }
}
