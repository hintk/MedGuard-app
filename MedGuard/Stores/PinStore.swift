import Foundation
import CryptoKit

/// Stores the device-local 6-digit PIN as a salted SHA-256 hash inside the
/// iOS Keychain (`kSecClassGenericPassword`). The PIN is bound to this
/// device only; uninstalling the app removes it.
enum PinStore {
    private static let service = "com.wangchuhao.medguard.pin"
    private static let account = "device_pin"
    private static let saltKey = "com.wangchuhao.medguard.pin.salt"

    enum SetupState {
        case notSet
        case set
    }

    static var hasPin: Bool {
        readHash() != nil
    }

    /// Save (or overwrite) the PIN. Length must be exactly 6 digits.
    static func setPin(_ pin: String) throws {
        try validate(pin)
        let salt = ensureSalt()
        let hash = hashPin(pin, salt: salt)
        try writeHash(hash)
    }

    /// Returns `true` if the candidate matches the stored PIN.
    static func verify(_ pin: String) -> Bool {
        guard let stored = readHash() else { return false }
        let salt = readSalt() ?? Data() // fallback: empty salt
        let candidate = hashPin(pin, salt: salt)
        return constantTimeEqual(stored, candidate)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Validation

    enum PinError: LocalizedError {
        case invalidLength
        case notNumeric

        var errorDescription: String? {
            switch self {
            case .invalidLength: return "密码必须为 6 位数字"
            case .notNumeric:    return "密码只能包含数字"
            }
        }
    }

    static func validate(_ pin: String) throws {
        guard pin.count == 6 else { throw PinError.invalidLength }
        guard pin.allSatisfy({ $0.isNumber }) else { throw PinError.notNumeric }
    }

    // MARK: - Hashing

    private static func hashPin(_ pin: String, salt: Data) -> Data {
        var bytes = salt
        bytes.append(contentsOf: Array(pin.utf8))
        let digest = SHA256.hash(data: bytes)
        return Data(digest)
    }

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<lhs.count { diff |= lhs[i] ^ rhs[i] }
        return diff == 0
    }

    // MARK: - Salt persistence

    private static func ensureSalt() -> Data {
        if let existing = readSalt() { return existing }
        var fresh = Data(count: 16)
        let result = fresh.withUnsafeMutableBytes { ptr -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, 16, ptr.baseAddress!)
        }
        if result == errSecSuccess {
            UserDefaults.standard.set(fresh, forKey: saltKey)
        } else {
            // last-resort fallback so the user isn't locked out
            fresh = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
            UserDefaults.standard.set(fresh, forKey: saltKey)
        }
        return fresh
    }

    private static func readSalt() -> Data? {
        UserDefaults.standard.data(forKey: saltKey)
    }

    // MARK: - Keychain read / write

    private static func readHash() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    private static func writeHash(_ data: Data) throws {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        // Try update first
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let updateAttrs: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(updateQuery as CFDictionary, updateAttrs as CFDictionary)
        if status == errSecItemNotFound {
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
            }
        } else if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}