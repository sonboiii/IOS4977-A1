import SwiftUI

/// Choose the municipality you live in. Shown full-screen on first login,
/// and as a sheet from Home / Profile to change it.
struct MunicipalityPickerView: View {
    @Environment(SessionManager.self) private var session
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(\.dismiss) private var dismiss

    var isFirstRun = false

    var body: some View {
        content
            .navigationTitle(isFirstRun ? "Welcome" : "Change Municipality")
            .navigationBarTitleDisplayMode(isFirstRun ? .large : .inline)
            .toolbar {
                if isFirstRun {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Log Out") { session.signOut() }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .overlay {
                if municipality.isSaving {
                    ProgressView("Saving…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .disabled(municipality.isSaving)
            .task { await municipality.loadMunicipalities() }
            .alert("Couldn't Save",
                   isPresented: Binding(get: { municipality.saveError != nil },
                                        set: { if !$0 { municipality.saveError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(municipality.saveError ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch municipality.municipalitiesState {
        case .idle, .loading where municipality.municipalities.isEmpty:
            LoadingStateView(message: "Loading municipalities…")
        case .failed(let message) where municipality.municipalities.isEmpty:
            ErrorStateView(message: message) { await municipality.loadMunicipalities() }
        default:
            List {
                Section {
                    Text(isFirstRun
                         ? "Municipal Elections Companion shows candidates and offices for the municipality you live in. Choose it below — you can change it later from your Profile."
                         : "Election data and your candidate selections will switch to the municipality you choose.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Where do you live?") {
                    ForEach(municipality.municipalities) { option in
                        Button {
                            choose(option)
                        } label: {
                            HStack {
                                MunicipalityRow(municipality: option)
                                Spacer(minLength: 8)
                                if option.name == municipality.city {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                        .accessibilityLabel("Current municipality")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func choose(_ option: Municipality) {
        guard let email = session.userEmail else { return }
        Task {
            if await municipality.select(option, userEmail: email), !isFirstRun {
                dismiss()
            }
        }
    }
}
