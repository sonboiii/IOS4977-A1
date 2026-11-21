import SwiftUI

/// Profile & settings: user, municipality (view / change), selection stats, sync time, logout.
struct ProfileView: View {
    @Environment(SessionManager.self) private var session
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(CandidateSelectionsViewModel.self) private var selections
    @State private var confirmingLogout = false
    @State private var showingPicker = false
    @State private var isSyncing = false

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
                            Text("City: \(municipality.city ?? "—")")
                                .font(.subheadline)
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Account") {
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    if let expiry = session.tokenExpiry {
                        LabeledContent("Session expires",
                                       value: expiry.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            Section {
                LabeledContent("City", value: municipality.city ?? "—")
                Button("Change Municipality", systemImage: "building.2") {
                    showingPicker = true
                }
            } header: {
                Text("Municipality")
            } footer: {
                Text("Stored in Firebase with your account. Candidates, offices and selections are shown for this municipality only.")
            }

            Section("Candidate Selections") {
                LabeledContent("Total saved selections", value: "\(selections.count)")
                LabeledContent("Last synchronization",
                               value: selections.lastSynchronized?.formatted(date: .abbreviated, time: .standard)
                                   ?? "Not synchronized yet")
                Button {
                    Task {
                        isSyncing = true
                        await selections.refresh()
                        isSyncing = false
                    }
                } label: {
                    HStack {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        if isSyncing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isSyncing)
                if let message = selections.state.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("App", value: "Municipal Elections Companion")
                LabeledContent("API", value: AppConfig.apiBaseURL.host() ?? "")
                    .lineLimit(1)
                    .truncationMode(.middle)
                LabeledContent("Cloud data", value: "Firebase Firestore")
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
        .refreshable { await selections.refresh() }
        .sheet(isPresented: $showingPicker) {
            NavigationStack { MunicipalityPickerView() }
        }
        .confirmationDialog("Log out of Municipal Elections?",
                            isPresented: $confirmingLogout,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                session.signOut()
            }
        }
    }
}
