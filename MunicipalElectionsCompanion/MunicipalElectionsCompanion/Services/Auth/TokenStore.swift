import Foundation
import Security

/// The signed-in session that is persisted between launches.
struct StoredSession: Codable {
    let token: String
    let expiresAt: String
    let user: User

    var expiryDate: Date? { DateParsing.date(fromISO: expiresAt) }

    var isExpired: Bool {
        guard let expiryDate else { return false }
        return expiryDate <= Date()
    }
}

/// Stores the JWT (and the user it belongs to) in the iOS Keychain rather than UserDefaults,
/// because the token is a credential.
final class TokenStore {
    static let shared = TokenStore()

    private let service = "ca.bcit.comp4977.MunicipalElectionsCompanion"
    private let account = "session"
    private let lock = NSLock()
    private var cached: StoredSession?

    init() {
        cached = readFromKeychain()
    }

    var session: StoredSession? {
        lock.lock(); defer { lock.unlock() }
        return cached
    }

    var token: String? { session?.token }

    func save(_ session: StoredSession) {
        lock.lock(); defer { lock.unlock() }
        cached = session
        guard let data = try? JSONEncoder().encode(session) else { return }

        let query = baseQuery()
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func clear() {
        lock.lock(); defer { lock.unlock() }
        cached = nil
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func readFromKeychain() -> StoredSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
