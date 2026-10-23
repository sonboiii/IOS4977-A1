import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct User: Codable, Equatable {
    let id: String
    let name: String
    let email: String

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? String(email.prefix(1)).uppercased() : letters.uppercased()
    }
}

/// Response of POST /api/auth/login and /api/auth/register: { "token": "...", "expiresAt": "...", "user": {...} }
struct AuthResponse: Codable {
    let token: String
    let expiresAt: String
    let user: User
}
