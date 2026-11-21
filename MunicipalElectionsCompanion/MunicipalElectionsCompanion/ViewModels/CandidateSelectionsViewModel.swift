import Foundation
import Observation

/// The signed-in user's candidate selections for their municipality, stored in Firestore.
/// Shared app-wide so Candidate Details, My Candidate Selections and Profile stay in sync.
@MainActor
@Observable
final class CandidateSelectionsViewModel {
    private(set) var selections: [CandidateSelection] = []
    private(set) var state: LoadState = .idle
    /// Offices for the municipality, used for the "no more candidates than seats" rule.
    private(set) var offices: [Position] = []
    private(set) var lastSynchronized: Date?
    /// Candidate ids with a write in flight.
    private(set) var pendingCandidateIds: Set<Int> = []
    /// Error from a create/update/delete, shown as an alert.
    var actionError: String?

    private var userEmail: String?
    private(set) var city: String?

    private let firestore: any FirestoreServicing
    private let elections: any ElectionServicing
    private let defaults: UserDefaults

    init(firestore: any FirestoreServicing = FirestoreService.shared,
         elections: any ElectionServicing = ElectionService.shared,
         defaults: UserDefaults = .standard) {
        self.firestore = firestore
        self.elections = elections
        self.defaults = defaults
    }

    var count: Int { selections.count }

    // MARK: Lookups

    func selection(for candidateId: Int) -> CandidateSelection? {
        selections.first { $0.candidateId == candidateId }
    }

    func isPending(_ candidateId: Int) -> Bool {
        pendingCandidateIds.contains(candidateId)
    }

    func seats(forPositionId positionId: Int) -> Int? {
        offices.first { $0.positionId == positionId }?.seatsAvailable
    }

    func selectedCount(forPositionId positionId: Int) -> Int {
        selections.filter { $0.positionId == positionId }.count
    }

    /// Selections grouped by office, in the API's office order (Mayor, Councillor, School Trustee).
    var groupedByPosition: [(positionId: Int, positionName: String, items: [CandidateSelection])] {
        let groups = Dictionary(grouping: selections, by: \.positionId)
        return groups
            .map { positionId, items in
                (positionId: positionId,
                 positionName: items.first?.positionName ?? "",
                 items: items.sorted { $0.candidateName < $1.candidateName })
            }
            .sorted { $0.positionId < $1.positionId }
    }

    // MARK: Loading

    /// Loads the selections for a user and municipality. Called again whenever the municipality
    /// changes, so selections from the previous municipality are no longer shown.
    func load(userEmail: String, city: String) async {
        let email = userEmail.lowercased()
        if email != self.userEmail || city != self.city {
            selections = []
            offices = []
            state = .loading
        }
        self.userEmail = email
        self.city = city
        lastSynchronized = defaults.object(forKey: syncKey(email)) as? Date

        await refresh()
    }

    /// READ from Firestore (pull to refresh), plus the office seat limits from the API.
    func refresh() async {
        guard let userEmail, let city else { return }
        if selections.isEmpty { state = .loading }

        async let officesTask: Void = loadOffices(city: city)
        do {
            let fetched = try await firestore.selections(userEmail: userEmail, municipality: city)
            guard city == self.city else { return } // municipality changed while loading
            selections = fetched
            state = .loaded
            markSynchronized()
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            state = .failed(FirebaseServiceError.userMessage(for: error))
        }
        await officesTask
    }

    private func loadOffices(city: String) async {
        if let fresh = try? await elections.offices(city: city), city == self.city {
            offices = fresh
        }
    }

    // MARK: Validation

    /// Returns a message when a selection can't be saved, or nil when it's valid.
    func validationError(for candidate: Candidate, notes: String, isNew: Bool) -> String? {
        guard let userEmail, !userEmail.isEmpty else {
            return FirebaseServiceError.notSignedIn.errorDescription
        }
        guard let city, candidate.municipalityName == city else {
            return "\(candidate.name) isn't running in your municipality."
        }
        if candidate.name.isEmpty || candidate.positionName.isEmpty {
            return "Candidate information is missing. Pull to refresh and try again."
        }
        if let notesError = Validators.notes(notes) {
            return notesError
        }
        guard isNew else { return nil }

        if selection(for: candidate.candidateId) != nil {
            return FirebaseServiceError.duplicateSelection.errorDescription
        }
        if let seats = seats(forPositionId: candidate.positionId),
           selectedCount(forPositionId: candidate.positionId) >= seats {
            let noun = seats == 1 ? "1 \(candidate.positionName)" : "\(seats) \(candidate.positionName) candidates"
            return "You can choose at most \(noun) in \(city). Remove one before adding another."
        }
        return nil
    }

    // MARK: CRUD

    /// CREATE
    @discardableResult
    func add(_ candidate: Candidate, notes: String) async -> Bool {
        guard let userEmail, !isPending(candidate.candidateId) else { return false }
        if offices.isEmpty, let city { await loadOffices(city: city) }
        if offices.isEmpty {
            actionError = "Couldn't load the seat limits for your municipality. Check your connection and try again."
            return false
        }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = validationError(for: candidate, notes: trimmed, isNew: true) {
            actionError = error
            return false
        }

        pendingCandidateIds.insert(candidate.candidateId)
        defer { pendingCandidateIds.remove(candidate.candidateId) }

        let selection = CandidateSelection(candidate: candidate, userEmail: userEmail, notes: trimmed)
        do {
            try await firestore.create(selection)
            selections.append(selection)
            markSynchronized()
            return true
        } catch {
            actionError = FirebaseServiceError.userMessage(for: error)
            if (error as? FirebaseServiceError) == .duplicateSelection { await refresh() }
            return false
        }
    }

    /// UPDATE (notes)
    @discardableResult
    func update(_ selection: CandidateSelection, notes: String) async -> Bool {
        guard !isPending(selection.candidateId) else { return false }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = Validators.notes(trimmed) {
            actionError = error
            return false
        }

        pendingCandidateIds.insert(selection.candidateId)
        defer { pendingCandidateIds.remove(selection.candidateId) }

        let now = Date()
        do {
            try await firestore.updateNotes(selectionId: selection.id, notes: trimmed, modified: now)
            if let index = selections.firstIndex(where: { $0.id == selection.id }) {
                selections[index].notes = trimmed
                selections[index].dateModified = now
            }
            markSynchronized()
            return true
        } catch {
            actionError = FirebaseServiceError.userMessage(for: error)
            return false
        }
    }

    /// DELETE — removed from the list immediately, restored if Firestore fails.
    func delete(_ selection: CandidateSelection) async {
        guard !isPending(selection.candidateId) else { return }
        pendingCandidateIds.insert(selection.candidateId)
        defer { pendingCandidateIds.remove(selection.candidateId) }

        let previous = selections
        selections.removeAll { $0.id == selection.id }
        do {
            try await firestore.deleteSelection(id: selection.id)
            markSynchronized()
        } catch {
            selections = previous
            actionError = FirebaseServiceError.userMessage(for: error)
        }
    }

    func reset() {
        selections = []
        offices = []
        state = .idle
        pendingCandidateIds = []
        actionError = nil
        userEmail = nil
        city = nil
        lastSynchronized = nil
    }

    // MARK: Sync timestamp

    private func markSynchronized() {
        let now = Date()
        lastSynchronized = now
        if let userEmail { defaults.set(now, forKey: syncKey(userEmail)) }
    }

    private func syncKey(_ email: String) -> String { "lastSync.\(email)" }
}
