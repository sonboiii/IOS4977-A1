import SwiftUI

/// Screen 6: view and remove saved candidates.
/// Uses GET /api/savedcandidates and DELETE /api/savedcandidates/{id}.
struct VotingGuideView: View {
    @Environment(VotingGuideViewModel.self) private var votingGuide

    var body: some View {
        content
            .navigationTitle("My Voting Guide")
            .toolbar {
                if !votingGuide.saved.isEmpty {
                    EditButton()
                }
            }
            .task { await votingGuide.load() }
            .refreshable { await votingGuide.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch votingGuide.state {
        case .idle, .loading where votingGuide.saved.isEmpty:
            LoadingStateView(message: "Loading your guide…")
        case .failed(let message) where votingGuide.saved.isEmpty:
            ErrorStateView(message: message) { await votingGuide.load() }
        default:
            if votingGuide.saved.isEmpty {
                ContentUnavailableView {
                    Label("Your Guide Is Empty", systemImage: "checklist")
                } description: {
                    Text("Open a candidate and tap “Add to Voting Guide” to save them here.")
                }
            } else {
                List {
                    Section {
                        Text("You've saved \(votingGuide.count) candidate\(votingGuide.count == 1 ? "" : "s"). Swipe left to remove one.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(votingGuide.groupedByMunicipality, id: \.municipality) { group in
                        Section(group.municipality) {
                            ForEach(group.items) { entry in
                                NavigationLink(value: entry.candidate) {
                                    SavedCandidateRow(entry: entry)
                                }
                            }
                            .onDelete { offsets in
                                let entries = offsets.map { group.items[$0] }
                                Task {
                                    for entry in entries {
                                        await votingGuide.remove(entry)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

private struct SavedCandidateRow: View {
    let entry: SavedCandidate

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(url: entry.candidate.photoURL, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.candidate.name)
                    .font(.headline)
                Text(entry.candidate.positionName)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                if let date = entry.savedDate {
                    Text("Saved \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
