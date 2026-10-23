import SwiftUI

struct LoginView: View {
    @Environment(SessionManager.self) private var session
    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                AuthHeader(title: "Municipal Elections",
                           subtitle: "Sign in to explore candidates and build your voting guide.")

                VStack(alignment: .leading, spacing: 16) {
                    if let message = session.signOutMessage {
                        ErrorBanner(message: message)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .authFieldStyle(hasError: viewModel.emailError != nil)
                        FieldErrorText(message: viewModel.emailError)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(submit)
                            .authFieldStyle(hasError: viewModel.passwordError != nil)
                        FieldErrorText(message: viewModel.passwordError)
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    Button(action: submit) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                }

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    NavigationLink("Create one") {
                        RegisterView()
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(24)
            .animation(.default, value: viewModel.emailError)
            .animation(.default, value: viewModel.passwordError)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.email) { viewModel.fieldsChanged() }
        .onChange(of: viewModel.password) { viewModel.fieldsChanged() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func submit() {
        focusedField = nil
        Task { await viewModel.login(session: session) }
    }
}

/// App icon + title shared by Login and Register.
struct AuthHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.rectangle.stack.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .padding(.top, 40)
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

extension View {
    func authFieldStyle(hasError: Bool) -> some View {
        self
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasError ? Color.red : Color.clear, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack { LoginView() }
        .environment(SessionManager())
}
