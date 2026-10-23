import SwiftUI

/// Screen 3: municipality logo, name and election date. Data: GET /api/municipalities
struct MunicipalitiesView: View {
    @State private var viewModel = MunicipalitiesViewModel()

    var body: some View {
        content
            .navigationTitle("Municipalities")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading where viewModel.municipalities.isEmpty:
            LoadingStateView(message: "Loading municipalities…")
        case .failed(let message) where viewModel.municipalities.isEmpty:
            ErrorStateView(message: message) { await viewModel.load() }
        default:
            if viewModel.municipalities.isEmpty {
                ContentUnavailableView("No Municipalities",
                                       systemImage: "building.2",
                                       description: Text("No elections have been published yet."))
            } else {
                List(viewModel.municipalities) { municipality in
                    NavigationLink(value: municipality) {
                        MunicipalityRow(municipality: municipality)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

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
