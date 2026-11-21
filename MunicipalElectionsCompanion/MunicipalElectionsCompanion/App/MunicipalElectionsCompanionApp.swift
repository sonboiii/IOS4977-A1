import SwiftUI
import FirebaseCore

@main
struct MunicipalElectionsCompanionApp: App {
    // App-wide state shared through the environment.
    @State private var session: SessionManager
    @State private var municipality: MunicipalityViewModel
    @State private var selections: CandidateSelectionsViewModel

    init() {
        // Reads GoogleService-Info.plist. Must run before any Firebase service is used,
        // which is why the state objects are created here rather than inline.
        FirebaseApp.configure()
        _session = State(initialValue: SessionManager())
        _municipality = State(initialValue: MunicipalityViewModel())
        _selections = State(initialValue: CandidateSelectionsViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(municipality)
                .environment(selections)
        }
    }
}

/// Sign-in flow → first-time municipality choice → main app.
struct RootView: View {
    @Environment(SessionManager.self) private var session
    @Environment(MunicipalityViewModel.self) private var municipality
    @Environment(CandidateSelectionsViewModel.self) private var selections

    var body: some View {
        Group {
            if !session.isAuthenticated {
                NavigationStack {
                    LoginView()
                }
            } else if municipality.needsSelection {
                NavigationStack {
                    MunicipalityPickerView(isFirstRun: true)
                }
            } else if municipality.city != nil {
                MainView()
            } else if let message = municipality.state.errorMessage {
                ErrorStateView(message: message) {
                    if let email = session.userEmail { await municipality.load(userEmail: email) }
                }
            } else {
                LoadingStateView(message: "Loading your profile…")
            }
        }
        .transition(.opacity)
        .animation(.default, value: session.isAuthenticated)
        .animation(.default, value: municipality.city)
        .task(id: session.userEmail) {
            // Load (or clear) the user's municipality whenever the signed-in user changes.
            if let email = session.userEmail {
                await municipality.load(userEmail: email)
            } else {
                municipality.reset()
                selections.reset()
            }
        }
        .task(id: municipality.city) {
            // Changing municipality reloads the selections for the new one only.
            if let email = session.userEmail, let city = municipality.city {
                await selections.load(userEmail: email, city: city)
            }
        }
    }
}
