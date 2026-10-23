import SwiftUI

/// Screen 7: logged-in user and logout button.
struct ProfileView: View {
    @Environment(SessionManager.self) private var session
    @Environment(VotingGuideViewModel.self) private var votingGuide
    @State private var confirmingLogout = false

    var body: some View {
        List {
            if let user = session.user {
                Section {
                    HStack(spacing: 16) {
                        Text(user.initials)
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(Color.accentColor.gradient, in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.title3.bold())
                            Text(user.email)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Account") {
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Saved candidates", value: "\(votingGuide.count)")
                    if let expiry = session.tokenExpiry {
                        LabeledContent("Session expires",
                                       value: expiry.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            Section("About") {
                LabeledContent("App", value: "Municipal Elections Companion")
                LabeledContent("API", value: AppConfig.apiBaseURL.host() ?? "")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Section {
                Button("Log Out", role: .destructive) {
                    confirmingLogout = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Profile")
        .task { await session.refreshUser() }
        .confirmationDialog("Log out of Municipal Elections?",
                            isPresented: $confirmingLogout,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                session.signOut()
            }
        }
    }
}
