import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home, candidates, selections, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .candidates: "Candidates"
        case .selections: "My Selections"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .candidates: "person.3"
        case .selections: "checklist"
        case .profile: "person.crop.circle"
        }
    }
}

/// Adaptive navigation (Assignment 2, Part 6):
/// - iPhone (compact width, portrait and landscape): TabView with a NavigationStack per tab.
/// - iPad (regular width, portrait and landscape): NavigationSplitView with a sidebar.
///
/// Navigation paths and screen view models live here, above the layout switch, so the
/// current screen, scroll position data and loaded results survive rotation and size changes.
struct MainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(CandidateSelectionsViewModel.self) private var selections

    @State private var section: AppSection = .home
    @State private var homePath = NavigationPath()
    @State private var candidatesPath = NavigationPath()
    @State private var selectionsPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    @State private var homeViewModel = HomeViewModel()
    @State private var directoryViewModel = CandidateDirectoryViewModel()
    @State private var splitVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                splitLayout
            } else {
                tabLayout
            }
        }
        .alert("Candidate Selections",
               isPresented: Binding(get: { selections.actionError != nil },
                                    set: { if !$0 { selections.actionError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(selections.actionError ?? "")
        }
    }

    // MARK: iPhone

    private var tabLayout: some View {
        TabView(selection: $section) {
            ForEach(AppSection.allCases) { item in
                stack(for: item)
                    .tabItem { Label(item.title, systemImage: item.systemImage) }
                    .badge(item == .selections ? selections.count : 0)
                    .tag(item)
            }
        }
    }

    // MARK: iPad

    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $splitVisibility) {
            List(selection: Binding<AppSection?>(get: { section },
                                                 set: { if let value = $0 { section = value } })) {
                Section {
                    ForEach(AppSection.allCases) { item in
                        NavigationLink(value: item) {
                            Label(item.title, systemImage: item.systemImage)
                        }
                        .badge(item == .selections ? selections.count : 0)
                    }
                } header: {
                    if let city = municipality.city {
                        Label("City: \(city)", systemImage: "building.2")
                            .textCase(nil)
                    }
                }
            }
            .navigationTitle("Elections")
        } detail: {
            stack(for: section)
                .id(section)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: Shared

    @ViewBuilder
    private func stack(for item: AppSection) -> some View {
        switch item {
        case .home:
            NavigationStack(path: $homePath) {
                HomeView(viewModel: homeViewModel) { section = $0 }
                    .candidateDestinations()
            }
        case .candidates:
            NavigationStack(path: $candidatesPath) {
                CandidateDirectoryView(viewModel: directoryViewModel)
                    .candidateDestinations()
            }
        case .selections:
            NavigationStack(path: $selectionsPath) {
                MyCandidateSelectionsView()
                    .candidateDestinations()
            }
        case .profile:
            NavigationStack(path: $profilePath) {
                ProfileView()
            }
        }
    }
}

private extension View {
    func candidateDestinations() -> some View {
        navigationDestination(for: Candidate.self) { CandidateDetailView(candidate: $0) }
    }
}
