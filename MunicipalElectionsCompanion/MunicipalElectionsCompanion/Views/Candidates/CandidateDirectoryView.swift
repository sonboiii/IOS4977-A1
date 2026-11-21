import SwiftUI

/// Candidate Directory for the configured municipality, with search and an office filter.
/// Data: GET /api/candidates?city= (and /api/candidates/search?name=&city= while searching).
///
/// Adaptive layout, chosen from the available width:
/// - iPhone portrait (narrow): single-column scrolling list.
/// - iPhone landscape: two columns, with a biography excerpt and website on each card.
/// - iPad portrait / landscape: a multi-column grid that adds columns as space grows.
struct CandidateDirectoryView: View {
    @Environment(MunicipalityViewModel.self) private var municipality
    @Bindable var viewModel: CandidateDirectoryViewModel

    private var city: String { municipality.city ?? "" }

    var body: some View {
        GeometryReader { proxy in
            content(layout: DirectoryLayout(width: proxy.size.width))
        }
        .navigationTitle("\(city) Candidates")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search \(city) candidates")
        .toolbar { filterMenu }
        .safeAreaInset(edge: .top, spacing: 0) { activeFilterBar }
        .task(id: city) {
            await viewModel.loadCandidates(city: city)
        }
        .onChange(of: viewModel.searchText) {
            searchTask?.cancel()
            searchTask = Task { await viewModel.searchTextChanged(city: city) }
        }
    }

    @State private var searchTask: Task<Void, Never>?

    @ViewBuilder
    private func content(layout: DirectoryLayout) -> some View {
        switch viewModel.state {
        case .idle, .loading where viewModel.candidates.isEmpty:
            LoadingStateView(message: "Loading \(city) candidates…")
        case .failed(let message) where viewModel.candidates.isEmpty:
            ErrorStateView(message: message) { await viewModel.loadCandidates(city: city) }
        default:
            let results = viewModel.filteredCandidates
            if results.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: layout.gridItems, spacing: 12) {
                        ForEach(results) { candidate in
                            NavigationLink(value: candidate) {
                                CandidateCard(candidate: candidate, detailed: layout.showsDetails)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, layout.horizontalPadding)
                    .padding(.vertical, 12)
                    .animation(.default, value: results)
                }
                .background(Color(.systemGroupedBackground))
                .refreshable { await viewModel.loadCandidates(city: city) }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !viewModel.trimmedSearch.isEmpty {
            ContentUnavailableView.search(text: viewModel.trimmedSearch)
        } else {
            ContentUnavailableView {
                Label("No Candidates", systemImage: "person.3")
            } description: {
                Text("No \(city) candidates match these filters.")
            } actions: {
                if viewModel.hasActiveFilters {
                    Button("Clear Filters") { viewModel.clearFilters() }
                }
            }
        }
    }

    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Office", selection: $viewModel.selectedPositionName) {
                    Text("All offices").tag(String?.none)
                    ForEach(viewModel.positionNames, id: \.self) { name in
                        Text(name).tag(String?.some(name))
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Label("Filter",
                      systemImage: viewModel.hasActiveFilters
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
            }
        }
    }

    /// Chip showing the active office filter, tappable to remove.
    @ViewBuilder
    private var activeFilterBar: some View {
        if let position = viewModel.selectedPositionName {
            HStack(spacing: 8) {
                FilterChip(title: position) { viewModel.selectedPositionName = nil }
                Text("\(viewModel.filteredCandidates.count) results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

/// Column count and card style for the available width.
struct DirectoryLayout {
    let width: CGFloat

    /// One column on narrow screens (iPhone portrait), then one per ~280pt.
    var columns: Int {
        width < 500 ? 1 : max(2, Int(width / 280))
    }

    /// Wider layouts have room for a biography excerpt and website.
    var showsDetails: Bool { columns > 1 }

    var horizontalPadding: CGFloat { columns == 1 ? 12 : 20 }

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: columns)
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
