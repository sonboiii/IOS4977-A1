import SwiftUI

@main
struct MunicipalElectionsCompanionApp: App {
    // App-wide state shared through the environment.
    @State private var session = SessionManager()
    @State private var votingGuide = VotingGuideViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(votingGuide)
        }
    }
}

/// Shows the sign-in flow or the main app depending on whether a valid JWT is stored.
struct RootView: View {
    @Environment(SessionManager.self) private var session
    @Environment(VotingGuideViewModel.self) private var votingGuide

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    LoginView()
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: session.isAuthenticated)
        .task(id: session.user?.id) {
            // Load (or clear) the voting guide whenever the signed-in user changes.
            if session.isAuthenticated {
                await votingGuide.load()
            } else {
                votingGuide.reset()
            }
        }
    }
}
