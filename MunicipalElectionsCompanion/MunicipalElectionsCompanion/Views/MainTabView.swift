import SwiftUI

struct MainTabView: View {
    @Environment(VotingGuideViewModel.self) private var votingGuide

    var body: some View {
        TabView {
            NavigationStack {
                MunicipalitiesView()
                    .navigationDestination(for: Municipality.self) { MunicipalityDetailView(municipality: $0) }
                    .navigationDestination(for: Candidate.self) { CandidateDetailView(candidate: $0) }
            }
            .tabItem { Label("Municipalities", systemImage: "building.2") }

            NavigationStack {
                CandidateDirectoryView()
                    .navigationDestination(for: Candidate.self) { CandidateDetailView(candidate: $0) }
            }
            .tabItem { Label("Candidates", systemImage: "person.3") }

            NavigationStack {
                VotingGuideView()
                    .navigationDestination(for: Candidate.self) { CandidateDetailView(candidate: $0) }
            }
            .tabItem { Label("My Guide", systemImage: "checklist") }
            .badge(votingGuide.count)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        // Add/remove failures from any screen.
        .alert("Voting Guide",
               isPresented: Binding(get: { votingGuide.actionError != nil },
                                    set: { if !$0 { votingGuide.actionError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(votingGuide.actionError ?? "")
        }
    }
}
