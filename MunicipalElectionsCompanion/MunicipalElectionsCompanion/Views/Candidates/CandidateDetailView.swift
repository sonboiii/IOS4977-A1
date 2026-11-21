import SwiftUI

/// Candidate Details: API data (GET /api/candidates/{id}?city=) plus the user's Firestore
/// selection with Add / Edit / Delete Selection buttons.
///
/// Adaptive: photo and information side by side when there's room (iPad, iPhone landscape),
/// stacked vertically on narrow screens (iPhone portrait).
struct CandidateDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(CandidateSelectionsViewModel.self) private var selections
    @State private var viewModel: CandidateDetailViewModel

    // Presentation state lives on this view (outside the size-dependent layout),
    // so an open editor or dialog survives rotation.
    @State private var editorViewModel: SelectionEditorViewModel?
    @State private var confirmingDelete = false

    init(candidate: Candidate) {
        _viewModel = State(initialValue: CandidateDetailViewModel(candidate: candidate))
    }

    private var candidate: Candidate { viewModel.candidate }
    private var selection: CandidateSelection? { selections.selection(for: candidate.candidateId) }
    private var isSideBySide: Bool { horizontalSizeClass == .regular || verticalSizeClass == .compact }

    var body: some View {
        ScrollView {
            Group {
                if viewModel.isUnavailable {
                    ContentUnavailableView("Not in Your Municipality",
                                           systemImage: "building.2",
                                           description: Text("This candidate isn't running in \(municipality.city ?? "your municipality")."))
                } else if isSideBySide {
                    HStack(alignment: .top, spacing: 24) {
                        header
                            .frame(width: 260)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 16))
                        VStack(spacing: 20) {
                            selectionSection
                            contactSection
                            biographySection
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        header
                        selectionSection
                        contactSection
                        biographySection
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(candidate.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: municipality.city) {
            if let city = municipality.city { await viewModel.refresh(city: city) }
        }
        .sheet(item: $editorViewModel) { editor in
            SelectionEditorView(viewModel: editor)
        }
        .confirmationDialog("Delete this selection?",
                            isPresented: $confirmingDelete,
                            titleVisibility: .visible) {
            Button("Delete Selection", role: .destructive) {
                if let selection {
                    Task { await selections.delete(selection) }
                }
            }
        } message: {
            Text("\(candidate.name) will be removed from My Candidate Selections.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            RemoteImage(url: candidate.photoURL, size: 140)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            Text(candidate.name)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(candidate.positionName)
                .font(.headline)
                .foregroundStyle(.tint)
            Label(candidate.municipalityName, systemImage: "building.2")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Selection (Firestore)

    @ViewBuilder
    private var selectionSection: some View {
        let isPending = selections.isPending(candidate.candidateId)

        if let selection {
            DetailCard(title: "Your Selection") {
                Label("Saved \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))",
                      systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                Text(selection.notes.isEmpty ? "No notes." : selection.notes)
                    .foregroundStyle(selection.notes.isEmpty ? Color.secondary : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { editButton; deleteButton }
                    VStack(spacing: 10) { editButton; deleteButton }
                }
                .disabled(isPending)
            }
        } else {
            Button {
                editorViewModel = SelectionEditorViewModel(candidate: candidate, existing: nil)
            } label: {
                HStack {
                    if isPending {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text("Add Selection")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isPending || selections.state != .loaded)

            if let seats = selections.seats(forPositionId: candidate.positionId) {
                Text("You've chosen \(selections.selectedCount(forPositionId: candidate.positionId)) of \(seats) for \(candidate.positionName).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, -12)
            }
        }
    }

    private var editButton: some View {
        Button {
            editorViewModel = SelectionEditorViewModel(candidate: candidate, existing: selection)
        } label: {
            Label("Edit Selection", systemImage: "pencil")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            confirmingDelete = true
        } label: {
            Label("Delete Selection", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    // MARK: API data

    @ViewBuilder
    private var contactSection: some View {
        if candidate.websiteURL != nil || candidate.emailURL != nil {
            DetailCard(title: "Contact") {
                if let url = candidate.websiteURL, let website = candidate.website {
                    Link(destination: url) {
                        ContactRow(systemImage: "globe", title: "Website", value: website)
                    }
                }
                if candidate.websiteURL != nil && candidate.emailURL != nil {
                    Divider()
                }
                if let url = candidate.emailURL, let email = candidate.email {
                    Link(destination: url) {
                        ContactRow(systemImage: "envelope", title: "Email", value: email)
                    }
                }
            }
        }
    }

    private var biographySection: some View {
        DetailCard(title: "Biography") {
            if viewModel.isRefreshing && candidate.biography == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let hasBio = candidate.biography?.isEmpty == false
                Text(hasBio ? (candidate.biography ?? "") : "This candidate hasn't provided a biography yet.")
                    .foregroundStyle(hasBio ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ContactRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 24)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
