import SwiftUI

/// My Candidate Selections: the user's Firestore selections for their municipality,
/// grouped by office. Edit, delete (with confirmation) and pull to refresh.
struct MyCandidateSelectionsView: View {
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(CandidateSelectionsViewModel.self) private var selections

    @State private var editorViewModel: SelectionEditorViewModel?
    @State private var pendingDelete: CandidateSelection?

    var body: some View {
        content
            .navigationTitle("My Candidate Selections")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await selections.refresh() }
            .sheet(item: $editorViewModel) { editor in
                SelectionEditorView(viewModel: editor)
            }
            .confirmationDialog("Delete this selection?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible,
                                presenting: pendingDelete) { selection in
                Button("Delete \(selection.candidateName)", role: .destructive) {
                    Task { await selections.delete(selection) }
                }
            } message: { selection in
                Text("\(selection.candidateName) will be removed from your \(selection.municipalityName) selections.")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch selections.state {
        case .idle, .loading where selections.selections.isEmpty:
            LoadingStateView(message: "Loading your selections…")
        case .failed(let message) where selections.selections.isEmpty:
            ErrorStateView(message: message) { await selections.refresh() }
        default:
            if selections.selections.isEmpty {
                ScrollView {
                    ContentUnavailableView {
                        Label("No Selections Yet", systemImage: "checklist")
                    } description: {
                        Text("Open a \(municipality.city ?? "") candidate and tap “Add Selection” to save them here.")
                    }
                    .padding(.top, 60)
                }
            } else {
                List {
                    Section {
                        LabeledContent("City", value: municipality.city ?? "")
                        if let synced = selections.lastSynchronized {
                            LabeledContent("Last synchronized",
                                           value: synced.formatted(date: .abbreviated, time: .shortened))
                        }
                    } footer: {
                        Text("Swipe a selection to edit or delete it. Pull down to refresh.")
                    }

                    ForEach(selections.groupedByPosition, id: \.positionId) { group in
                        Section {
                            ForEach(group.items) { selection in
                                NavigationLink(value: selection.candidateStub) {
                                    SelectionRow(selection: selection)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        pendingDelete = selection
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)

                                    Button {
                                        edit(selection)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .contextMenu {
                                    Button("Edit Selection", systemImage: "pencil") { edit(selection) }
                                    Button("Delete Selection", systemImage: "trash", role: .destructive) {
                                        pendingDelete = selection
                                    }
                                }
                            }
                        } header: {
                            Text(sectionTitle(for: group.positionId, name: group.positionName,
                                              count: group.items.count))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .animation(.default, value: selections.selections)
            }
        }
    }

    private func sectionTitle(for positionId: Int, name: String, count: Int) -> String {
        if let seats = selections.seats(forPositionId: positionId) {
            return "\(name) · \(count) of \(seats)"
        }
        return name
    }

    private func edit(_ selection: CandidateSelection) {
        editorViewModel = SelectionEditorViewModel(candidate: selection.candidateStub, existing: selection)
    }
}

/// Candidate image, name, municipality, position, notes and date saved.
private struct SelectionRow: View {
    let selection: CandidateSelection

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(url: selection.photoURL, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(selection.candidateName)
                    .font(.headline)
                Text(selection.positionName)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                Label(selection.municipalityName, systemImage: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !selection.notes.isEmpty {
                    Text(selection.notes)
                        .font(.footnote)
                        .lineLimit(3)
                        .padding(.top, 2)
                }
                Text("Saved \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
