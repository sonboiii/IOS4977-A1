import Foundation
import FirebaseAuth

/// Signs the user in to Firebase Auth with the same email and password used for the Web API.
///
/// Firestore security rules can only identify a user through Firebase Auth (`request.auth`),
/// so this is what lets the rules restrict each CandidateSelections document to its owner's email.
protocol FirebaseAuthServicing {
    /// Lower-cased email of the signed-in Firebase user, if any.
    var currentEmail: String? { get }
    /// Signs in; creates the Firebase account the first time (e.g. accounts made in Assignment 1).
    func signIn(email: String, password: String) async throws
    func signOut()
}

final class FirebaseAuthService: FirebaseAuthServicing {
    static let shared = FirebaseAuthService()

    // Firebase Auth error codes (FIRAuthErrorCode). Compared as raw values so this works across SDK versions.
    private enum Code {
        static let invalidCredential = 17004
        static let emailAlreadyInUse = 17007
        static let wrongPassword = 17009
        static let userNotFound = 17011
    }

    var currentEmail: String? {
        Auth.auth().currentUser?.email?.lowercased()
    }

    func signIn(email: String, password: String) async throws {
        let email = email.lowercased()
        if currentEmail == email { return }
        if Auth.auth().currentUser != nil { signOut() }

        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError where Self.mayBeMissingAccount(error) {
            // With email-enumeration protection, a missing account and a wrong password both
            // come back as "invalid credential", so try to create the account.
            do {
                _ = try await Auth.auth().createUser(withEmail: email, password: password)
            } catch let createError as NSError where createError.code == Code.emailAlreadyInUse {
                // The Firebase account exists with a different password.
                throw FirebaseServiceError.authenticationFailed
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    private static func mayBeMissingAccount(_ error: NSError) -> Bool {
        [Code.invalidCredential, Code.userNotFound, Code.wrongPassword].contains(error.code)
    }
}
