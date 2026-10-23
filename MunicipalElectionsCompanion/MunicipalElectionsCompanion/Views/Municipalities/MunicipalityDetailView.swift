import SwiftUI

/// A municipality's details and the candidates running for each position.
/// Data: GET /api/municipalities/{id} and GET /api/candidates?municipalityId={id}
struct MunicipalityDetailView: View {
    @State private var viewModel: MunicipalityDetailViewModel

    init(municipality: Municipality) {
        _viewModel = State(initialValue: MunicipalityDetailViewModel(municipality: municipality))
    }

    var body: some View {
        List {
            Section {
                header
            }

            switch viewModel.state {
            case .idle, .loading:
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            case .failed(let message):
                Section {
                    ErrorBanner(message: message)
                    Button("Try Again") { Task { await viewModel.load() } }
                }
            case .loaded:
                ForEach(viewModel.sections) { section in
                    Section {
                        if section.candidates.isEmpty {
                            Text("No candidates yet")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(section.candidates) { candidate in
                            NavigationLink(value: candidate) {
                                CandidateRow(candidate: candidate, showsMunicipality: false)
                            }
                        }
                    } header: {
                        HStack {
                            Text(section.position.name)
                            Spacer()
                            Text(section.position.seatsText)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.municipality.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RemoteImage(url: viewModel.municipality.logoURL,
                            placeholderSystemImage: "building.columns.fill",
                            size: 72,
                            cornerRadius: 14)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.municipality.name)
                        .font(.title2.bold())
                    Text(viewModel.municipality.province)
                        .foregroundStyle(.secondary)
                }
            }

            Label("Election day: \(viewModel.municipality.formattedElectionDate)", systemImage: "calendar")
                .font(.subheadline.weight(.medium))

            if let description = viewModel.detail?.description ?? viewModel.municipality.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
