import Foundation
import Observation

/// Owns the authentication state for the whole app: the API's JWT (in the Keychain)
/// plus the matching Firebase Auth session used by Firestore.
@MainActor
@Observable
final class SessionManager {
    private(set) var user: User?
    /// Shown on the login screen after an automatic sign-out (expired token).
    var signOutMessage: String?

    var isAuthenticated: Bool { user != nil }

    /// The email used as the user identifier in Firestore (lower-cased).
    var userEmail: String? { user?.email.lowercased() }

    private let tokenStore: TokenStore
    private let authService: any AuthServicing
    private let firebaseAuth: any FirebaseAuthServicing
    @ObservationIgnored private var expiryObserver: NSObjectProtocol?

    init(tokenStore: TokenStore = .shared,
         authService: any AuthServicing = AuthService.shared,
         firebaseAuth: any FirebaseAuthServicing = FirebaseAuthService.shared) {
        self.tokenStore = tokenStore
        self.authService = authService
        self.firebaseAuth = firebaseAuth

        // Restore a previous session if the JWT is still valid and Firebase is signed in as the same user.
        if let stored = tokenStore.session {
            if stored.isExpired {
                tokenStore.clear()
                firebaseAuth.signOut()
            } else if firebaseAuth.currentEmail != stored.user.email.lowercased() {
                tokenStore.clear()
                firebaseAuth.signOut()
                signOutMessage = "Please sign in again to sync your candidate selections."
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

    /// Signs in to Firebase with the same credentials, then persists the JWT returned by
    /// login/register and switches the app to the signed-in state.
    func signIn(with response: AuthResponse, password: String) async throws {
        try await firebaseAuth.signIn(email: response.user.email, password: password)
        tokenStore.save(StoredSession(token: response.token,
                                      expiresAt: response.expiresAt,
                                      user: response.user))
        signOutMessage = nil
        user = response.user
    }

    func signOut(message: String? = nil) {
        tokenStore.clear()
        firebaseAuth.signOut()
        signOutMessage = message
        user = nil
    }

    /// Re-reads the profile from GET /api/auth/me (also confirms the token is still accepted).
    func refreshUser() async {
        guard isAuthenticated, let stored = tokenStore.session else { return }
        do {
            let fresh = try await authService.currentUser()
            tokenStore.save(StoredSession(token: stored.token, expiresAt: stored.expiresAt, user: fresh))
            user = fresh
        } catch {
            // A 401 signs out via the notification; other errors keep the cached profile.
        }
    }

    var tokenExpiry: Date? { tokenStore.session?.expiryDate }
}
