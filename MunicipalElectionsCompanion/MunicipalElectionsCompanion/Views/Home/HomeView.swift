import SwiftUI

/// Home: the app title, the configured municipality, its election date and the offices up
/// for election with seat counts and how many the user has chosen. Data: GET /api/elections?city=
struct HomeView: View {
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(CandidateSelectionsViewModel.self) private var selections
    @Bindable var viewModel: HomeViewModel
    /// Switches to another tab / sidebar section.
    var navigate: (AppSection) -> Void = { _ in }

    @State private var showingPicker = false

    private var city: String { municipality.city ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                content
            }
            .padding()
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: city) { await viewModel.load(city: city) }
        .refreshable {
            await viewModel.load(city: city)
            await selections.refresh()
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack { MunicipalityPickerView() }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            RemoteImage(url: viewModel.election?.logoURL,
                        placeholderSystemImage: "building.columns.fill",
                        size: 64,
                        cornerRadius: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text("Municipal Elections Companion")
                    .font(.title2.bold())
                Text("City: \(city)")
                    .font(.headline)
                    .foregroundStyle(.tint)
                if let election = viewModel.election {
                    Label(election.formattedElectionDate, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Button("Change") { showingPicker = true }
                .buttonStyle(.bordered)
                .accessibilityLabel("Change municipality")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading where viewModel.election == nil:
            ProgressView("Loading the \(city) election…")
                .frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let message) where viewModel.election == nil:
            ErrorStateView(message: message) { await viewModel.load(city: city) }
                .frame(minHeight: 260)
        default:
            if let election = viewModel.election {
                if let description = election.description, !description.isEmpty {
                    Text(description)
                        .foregroundStyle(.secondary)
                }

                Text("Offices up for election")
                    .font(.headline)

                // 1 column on iPhone portrait, more as the width grows (landscape / iPad).
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                    ForEach(election.positions) { office in
                        OfficeCard(office: office,
                                   chosen: selections.selectedCount(forPositionId: office.positionId))
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        navigate(.candidates)
                    } label: {
                        Label("Browse \(election.candidateCount) Candidates", systemImage: "person.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        navigate(.selections)
                    } label: {
                        Label("My Selections (\(selections.count))", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
        }
    }
}

private struct OfficeCard: View {
    let office: Position
    let chosen: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(office.name)
                .font(.headline)
            Text("\(office.seatsText) · \(office.candidateCount) candidates")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(min(chosen, office.seatsAvailable)),
                         total: Double(max(office.seatsAvailable, 1)))
            Text("You've chosen \(chosen) of \(office.seatsAvailable)")
                .font(.caption)
                .foregroundStyle(chosen >= office.seatsAvailable ? Color.green : Color.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
