import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""

    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    /// Field errors appear only after the first submit attempt, then update live.
    private var hasAttemptedSubmit = false

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    var canSubmit: Bool { !isLoading }

    func fieldsChanged() {
        if hasAttemptedSubmit { validate() }
        errorMessage = nil
    }

    @discardableResult
    private func validate() -> Bool {
        emailError = Validators.email(email)
        passwordError = Validators.password(password)
        return emailError == nil && passwordError == nil
    }

    func login(session: SessionManager) async {
        hasAttemptedSubmit = true
        errorMessage = nil
        guard validate() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password)
            password = ""
            session.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""

    private(set) var nameError: String?
    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var confirmError: String?
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    private var hasAttemptedSubmit = false

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    func fieldsChanged() {
        if hasAttemptedSubmit { validate() }
        errorMessage = nil
    }

    @discardableResult
    private func validate() -> Bool {
        nameError = Validators.required(name, field: "Name")
        emailError = Validators.email(email)
        passwordError = Validators.password(password)
        confirmError = confirmPassword.isEmpty
            ? "Please confirm your password."
            : (confirmPassword != password ? "Passwords don't match." : nil)
        return [nameError, emailError, passwordError, confirmError].allSatisfy { $0 == nil }
    }

    func register(session: SessionManager) async {
        hasAttemptedSubmit = true
        errorMessage = nil
        guard validate() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.register(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password)
            // The API returns a JWT on registration, so the user is signed in straight away.
            session.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
