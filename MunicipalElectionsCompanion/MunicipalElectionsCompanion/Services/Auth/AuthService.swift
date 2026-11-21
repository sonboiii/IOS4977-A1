import Foundation

/// Authentication against the ASP.NET Core Web API (JWT). The API remains the source of truth
/// for accounts; Firebase Auth is only signed in alongside it (see FirebaseAuthService).
protocol AuthServicing {
    /// POST /api/auth/login
    func login(email: String, password: String) async throws -> AuthResponse
    /// POST /api/auth/register
    func register(name: String, email: String, password: String) async throws -> AuthResponse
    /// GET /api/auth/me (Bearer token)
    func currentUser() async throws -> User
}

struct AuthService: AuthServicing {
    static let shared = AuthService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await client.post("api/auth/login", body: LoginRequest(email: email, password: password))
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try await client.post("api/auth/register",
                              body: RegisterRequest(name: name, email: email, password: password))
    }

    func currentUser() async throws -> User {
        try await client.get("api/auth/me", authorized: true)
    }
}
