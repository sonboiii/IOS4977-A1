import Foundation
import Observation

/// Owns the authentication state for the whole app (JWT + signed-in user).
@MainActor
@Observable
final class SessionManager {
    private(set) var user: User?
    /// Shown on the login screen after an automatic sign-out (expired token).
    var signOutMessage: String?

    var isAuthenticated: Bool { user != nil }

    private let tokenStore: TokenStore
    private let service: any ElectionServicing
    @ObservationIgnored private var expiryObserver: NSObjectProtocol?

    init(tokenStore: TokenStore = .shared, service: any ElectionServicing = ElectionService.shared) {
        self.tokenStore = tokenStore
        self.service = service

        // Restore a previous session if its token is still valid.
        if let stored = tokenStore.session {
            if stored.isExpired {
                tokenStore.clear()
            } else {
                user = stored.user
            }
        }

        expiryObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isAuthenticated else { return }
                self.signOut(message: "Your session has expired. Please sign in again.")
            }
        }
    }

    /// Persists the JWT returned by login/register and switches the app to the signed-in state.
    func signIn(with response: AuthResponse) {
        tokenStore.save(StoredSession(token: response.token,
                                      expiresAt: response.expiresAt,
                                      user: response.user))
        signOutMessage = nil
        user = response.user
    }

    func signOut(message: String? = nil) {
        tokenStore.clear()
        signOutMessage = message
        user = nil
    }

    /// Re-reads the profile from GET /api/auth/me (also confirms the token is still accepted).
    func refreshUser() async {
        guard isAuthenticated, let stored = tokenStore.session else { return }
        do {
            let fresh = try await service.currentUser()
            tokenStore.save(StoredSession(token: stored.token, expiresAt: stored.expiresAt, user: fresh))
            user = fresh
        } catch {
            // A 401 signs out via the notification; other errors keep the cached profile.
        }
    }

    var tokenExpiry: Date? { tokenStore.session?.expiryDate }
}
