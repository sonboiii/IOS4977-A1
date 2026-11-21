import Foundation
import Observation

@MainActor
@Observable
final class CandidateDetailViewModel {
    private(set) var candidate: Candidate
    private(set) var isRefreshing = false
    /// Set when the API says this candidate isn't in the configured municipality.
    private(set) var isUnavailable = false

    private let service: any ElectionServicing

    init(candidate: Candidate, service: any ElectionServicing = ElectionService.shared) {
        self.candidate = candidate
        self.service = service
    }

    /// GET /api/candidates/{id}?city= — refreshes the data passed in from the list.
    func refresh(city: String) async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            candidate = try await service.candidate(id: candidate.candidateId, city: city)
            isUnavailable = false
        } catch APIError.server(let status, _) where status == 404 {
            isUnavailable = true
        } catch {
            // Keep showing the data passed in from the list.
        }
    }
}

/// Add / edit form for a candidate selection (keeps in-progress notes across rotation).
@MainActor
@Observable
final class SelectionEditorViewModel: Identifiable {
    let candidate: Candidate
    let existing: CandidateSelection?
    var notes: String
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    init(candidate: Candidate, existing: CandidateSelection?) {
        self.candidate = candidate
        self.existing = existing
        notes = existing?.notes ?? ""
    }

    var isNew: Bool { existing == nil }
    var characterCount: Int { notes.count }
    var isOverLimit: Bool { characterCount > CandidateSelection.maxNotesLength }
    var hasChanges: Bool { notes != (existing?.notes ?? "") }

    func notesChanged() {
        errorMessage = Validators.notes(notes)
    }

    /// Validates, then creates or updates the selection. Returns true when the sheet can close.
    func save(using selections: CandidateSelectionsViewModel) async -> Bool {
        if let error = selections.validationError(for: candidate, notes: notes, isNew: isNew) {
            errorMessage = error
            return false
        }
        isSaving = true
        defer { isSaving = false }

        let succeeded: Bool
        if let existing {
            succeeded = await selections.update(existing, notes: notes)
        } else {
            succeeded = await selections.add(candidate, notes: notes)
        }
        if !succeeded {
            // Show the error inside the sheet rather than as an alert behind it.
            errorMessage = selections.actionError
            selections.actionError = nil
        }
        return succeeded
    }
}
