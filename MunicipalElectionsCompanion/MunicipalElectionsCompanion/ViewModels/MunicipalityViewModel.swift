import Foundation
import Observation

/// The municipality the user lives in (Assignment 2, Part 3).
/// Stored in Firestore (`UserProfiles/<email>`) and used to scope every API request.
@MainActor
@Observable
final class MunicipalityViewModel {
    private(set) var profile: UserProfile?
    private(set) var state: LoadState = .idle
    /// Options for the picker (GET /api/municipalities).
    private(set) var municipalities: [Municipality] = []
    private(set) var municipalitiesState: LoadState = .idle
    private(set) var isSaving = false
    var saveError: String?

    private let firestore: any FirestoreServicing
    private let elections: any ElectionServicing

    init(firestore: any FirestoreServicing = FirestoreService.shared,
         elections: any ElectionServicing = ElectionService.shared) {
        self.firestore = firestore
        self.elections = elections
    }

    /// The configured municipality name, e.g. "Burnaby" — sent to the API as ?city=.
    var city: String? { profile?.municipalityName }

    /// True on first login, before a municipality has been chosen.
    var needsSelection: Bool { state == .loaded && profile == nil }

    /// Reads the user's profile from Firestore.
    func load(userEmail: String) async {
        state = .loading
        do {
            profile = try await firestore.profile(userEmail: userEmail)
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            state = .failed(FirebaseServiceError.userMessage(for: error))
        }
    }

    func loadMunicipalities() async {
        if municipalities.isEmpty { municipalitiesState = .loading }
        do {
            municipalities = try await elections.municipalities()
            municipalitiesState = .loaded
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            municipalitiesState = .failed(error.localizedDescription)
        }
    }

    /// Saves the new municipality to Firestore. Views keyed on `city` then reload their data.
    @discardableResult
    func select(_ municipality: Municipality, userEmail: String) async -> Bool {
        guard municipality.name != city else { return true }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        let updated = UserProfile(userEmail: userEmail.lowercased(),
                                  municipalityId: municipality.municipalityId,
                                  municipalityName: municipality.name,
                                  dateModified: Date())
        do {
            try await firestore.saveProfile(updated)
            profile = updated
            return true
        } catch {
            saveError = FirebaseServiceError.userMessage(for: error)
            return false
        }
    }

    func reset() {
        profile = nil
        state = .idle
        saveError = nil
    }
}
