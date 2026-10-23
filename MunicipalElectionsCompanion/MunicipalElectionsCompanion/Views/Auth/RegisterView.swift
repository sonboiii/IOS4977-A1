import SwiftUI

struct RegisterView: View {
    @Environment(SessionManager.self) private var session
    @State private var viewModel = RegisterViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case name, email, password, confirm }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthHeader(title: "Create Account",
                           subtitle: "Save candidates to your personal voting guide.")

                VStack(alignment: .leading, spacing: 16) {
                    field(error: viewModel.nameError) {
                        TextField("Name", text: $viewModel.name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                            .authFieldStyle(hasError: viewModel.nameError != nil)
                    }

                    field(error: viewModel.emailError) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .authFieldStyle(hasError: viewModel.emailError != nil)
                    }

                    field(error: viewModel.passwordError) {
                        SecureField("Password (min. \(AppConfig.minimumPasswordLength) characters)",
                                    text: $viewModel.password)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirm }
                            .authFieldStyle(hasError: viewModel.passwordError != nil)
                    }

                    field(error: viewModel.confirmError) {
                        SecureField("Confirm password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirm)
                            .submitLabel(.go)
                            .onSubmit(submit)
                            .authFieldStyle(hasError: viewModel.confirmError != nil)
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    Button(action: submit) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.name) { viewModel.fieldsChanged() }
        .onChange(of: viewModel.email) { viewModel.fieldsChanged() }
        .onChange(of: viewModel.password) { viewModel.fieldsChanged() }
        .onChange(of: viewModel.confirmPassword) { viewModel.fieldsChanged() }
    }

    private func field<Content: View>(error: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content()
            FieldErrorText(message: error)
        }
    }

    private func submit() {
        focusedField = nil
        Task { await viewModel.register(session: session) }
    }
}

#Preview {
    NavigationStack { RegisterView() }
        .environment(SessionManager())
}
