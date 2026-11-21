import SwiftUI

/// Candidate photo, name, position and municipality. `detailed` adds a biography excerpt
/// and website for wider layouts (iPhone landscape, iPad).
struct CandidateCard: View {
    @Environment(CandidateSelectionsViewModel.self) private var selections
    let candidate: Candidate
    var detailed = false

    var body: some View {
        HStack(alignment: detailed ? .top : .center, spacing: 14) {
            RemoteImage(url: candidate.photoURL, size: detailed ? 72 : 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(candidate.positionName)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                Label(candidate.municipalityName, systemImage: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if detailed {
                    if let bio = candidate.biography, !bio.isEmpty {
                        Text(bio)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .padding(.top, 4)
                    }
                    if let website = candidate.website, !website.isEmpty {
                        Label(website, systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if selections.selection(for: candidate.candidateId) != nil {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("In your selections")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
