import SwiftUI

/// Screen 4: candidate photo, name, position and municipality, with search and filtering.
/// Data: GET /api/candidates (and /api/candidates/search?name= while searching).
struct CandidateDirectoryView: View {
    @State private var viewModel = CandidateDirectoryViewModel()

    var body: some View {
        content
            .navigationTitle("Candidates")
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search by name")
            .toolbar { filterMenu }
            .safeAreaInset(edge: .top, spacing: 0) { activeFilterBar }
            .task {
                await viewModel.loadFilterOptions()
            }
            .task(id: viewModel.searchText) {
                // Runs on appear and after each keystroke (debounced); the previous task is cancelled.
                if viewModel.candidates.isEmpty && viewModel.trimmedSearch.isEmpty {
                    await viewModel.loadCandidates()
                } else {
                    await viewModel.searchTextChanged()
                }
            }
            .refreshable { await viewModel.loadCandidates() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading where viewModel.candidates.isEmpty:
            LoadingStateView(message: "Loading candidates…")
        case .failed(let message) where viewModel.candidates.isEmpty:
            ErrorStateView(message: message) { await viewModel.loadCandidates() }
        default:
            let results = viewModel.filteredCandidates
            if results.isEmpty {
                if !viewModel.trimmedSearch.isEmpty {
                    ContentUnavailableView.search(text: viewModel.trimmedSearch)
                } else {
                    ContentUnavailableView {
                        Label("No Candidates", systemImage: "person.3")
                    } description: {
                        Text("No candidates match these filters.")
                    } actions: {
                        if viewModel.hasActiveFilters {
                            Button("Clear Filters") { viewModel.clearFilters() }
                        }
                    }
                }
            } else {
                List(results) { candidate in
                    NavigationLink(value: candidate) {
                        CandidateRow(candidate: candidate)
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: results)
            }
        }
    }

    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Municipality", selection: $viewModel.selectedMunicipalityId) {
                    Text("All municipalities").tag(Int?.none)
                    ForEach(viewModel.municipalities) { municipality in
                        Text(municipality.name).tag(Int?.some(municipality.municipalityId))
                    }
                }
                .pickerStyle(.menu)

                Picker("Position", selection: $viewModel.selectedPositionName) {
                    Text("All positions").tag(String?.none)
                    ForEach(viewModel.positionNames, id: \.self) { name in
                        Text(name).tag(String?.some(name))
                    }
                }
                .pickerStyle(.menu)

                if viewModel.hasActiveFilters {
                    Divider()
                    Button("Clear Filters", systemImage: "xmark.circle", role: .destructive) {
                        viewModel.clearFilters()
                    }
                }
            } label: {
                Label("Filter",
                      systemImage: viewModel.hasActiveFilters
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
            }
        }
    }

    /// Chips showing the active filters, tappable to remove.
    @ViewBuilder
    private var activeFilterBar: some View {
        if viewModel.hasActiveFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let name = viewModel.selectedMunicipalityName {
                        FilterChip(title: name) { viewModel.selectedMunicipalityId = nil }
                    }
                    if let position = viewModel.selectedPositionName {
                        FilterChip(title: position) { viewModel.selectedPositionName = nil }
                    }
                    Text("\(viewModel.filteredCandidates.count) results")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.bar)
        }
    }
}

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove filter \(title)")
    }
}
