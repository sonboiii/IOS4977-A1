import SwiftUI

/// Screen 5: biography, photo, website and email, with an Add to Voting Guide button.
/// Data: GET /api/candidates/{id}; button: POST /api/savedcandidates (or DELETE to remove).
struct CandidateDetailView: View {
    @Environment(VotingGuideViewModel.self) private var votingGuide
    @State private var viewModel: CandidateDetailViewModel

    init(candidate: Candidate) {
        _viewModel = State(initialValue: CandidateDetailViewModel(candidate: candidate))
    }

    private var candidate: Candidate { viewModel.candidate }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                guideButton
                contactSection
                biographySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(candidate.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
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
        .padding(.top, 8)
    }

    @ViewBuilder
    private var guideButton: some View {
        let isSaved = votingGuide.isSaved(candidate.candidateId)
        let isPending = votingGuide.isPending(candidate.candidateId)

        Button {
            Task {
                if isSaved {
                    await votingGuide.remove(candidateId: candidate.candidateId)
                } else {
                    await votingGuide.add(candidate)
                }
            }
        } label: {
            HStack {
                if isPending {
                    ProgressView()
                } else {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle.fill")
                }
                Text(isSaved ? "In Your Voting Guide" : "Add to Voting Guide")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .tint(isSaved ? Color.green : Color.accentColor)
        .controlSize(.large)
        .disabled(isPending)
        .accessibilityHint(isSaved ? "Removes this candidate from your voting guide" : "")
        .animation(.default, value: isSaved)

        if isSaved {
            Text("Tap again to remove from your guide.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, -16)
        }
    }

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
            let hasBio = candidate.biography?.isEmpty == false
            Text(hasBio ? (candidate.biography ?? "") : "This candidate hasn't provided a biography yet.")
                .foregroundStyle(hasBio ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailCard<Content: View>: View {
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
