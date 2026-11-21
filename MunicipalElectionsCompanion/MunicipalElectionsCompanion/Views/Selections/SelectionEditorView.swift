import SwiftUI

/// Add or edit a candidate selection (notes up to 500 characters).
struct SelectionEditorView: View {
    @Environment(CandidateSelectionsViewModel.self) private var selections
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SelectionEditorViewModel
    @FocusState private var notesFocused: Bool

    private var candidate: Candidate { viewModel.candidate }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        RemoteImage(url: candidate.photoURL, size: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(candidate.name).font(.headline)
                            Text(candidate.positionName).font(.subheadline).foregroundStyle(.tint)
                            Label(candidate.municipalityName, systemImage: "building.2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    if viewModel.isNew, let seats = selections.seats(forPositionId: candidate.positionId) {
                        LabeledContent("\(candidate.positionName) selections",
                                       value: "\(selections.selectedCount(forPositionId: candidate.positionId)) of \(seats)")
                    }
                }

                Section {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 140)
                        .focused($notesFocused)
                        .accessibilityLabel("Notes")
                } header: {
                    Text("Notes (optional)")
                } footer: {
                    HStack(alignment: .top) {
                        if let error = viewModel.errorMessage {
                            Text(error).foregroundStyle(.red)
                        }
                        Spacer()
                        Text("\(viewModel.characterCount)/\(CandidateSelection.maxNotesLength)")
                            .monospacedDigit()
                            .foregroundStyle(viewModel.isOverLimit ? Color.red : Color.secondary)
                    }
                }
            }
            .navigationTitle(viewModel.isNew ? "Add Selection" : "Edit Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .disabled(viewModel.isOverLimit || (!viewModel.isNew && !viewModel.hasChanges))
                    }
                }
            }
            .onChange(of: viewModel.notes) { viewModel.notesChanged() }
            .interactiveDismissDisabled(viewModel.isSaving || viewModel.hasChanges)
        }
    }

    private func save() {
        notesFocused = false
        Task {
            if await viewModel.save(using: selections) {
                dismiss()
            }
        }
    }
}
