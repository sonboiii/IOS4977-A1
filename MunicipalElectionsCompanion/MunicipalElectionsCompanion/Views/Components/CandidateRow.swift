import SwiftUI

/// Candidate photo, name, position and municipality.
struct CandidateRow: View {
    @Environment(VotingGuideViewModel.self) private var votingGuide
    let candidate: Candidate
    var showsMunicipality = true

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(url: candidate.photoURL, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.name)
                    .font(.headline)
                Text(candidate.positionName)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                if showsMunicipality {
                    Label(candidate.municipalityName, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if votingGuide.isSaved(candidate.candidateId) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("In your voting guide")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
