import SwiftUI

/// Municipality logo, name and election date (used by the municipality picker).
struct MunicipalityRow: View {
    let municipality: Municipality

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(url: municipality.logoURL,
                        placeholderSystemImage: "building.columns.fill",
                        size: 60,
                        cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(municipality.name)
                    .font(.headline)
                Label(municipality.formattedElectionDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(municipality.candidateCount) candidates · \(municipality.province)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
