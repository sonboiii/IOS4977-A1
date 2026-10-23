import Foundation
import Observation

/// The signed-in user's personal voting guide. Shared app-wide so the
/// Candidate Details button and the My Voting Guide tab stay in sync.
@MainActor
@Observable
final class VotingGuideViewModel {
    private(set) var saved: [SavedCandidate] = []
    private(set) var state: LoadState = .idle
    /// Candidate ids with an add/remove request in flight (disables the button).
    private(set) var pendingCandidateIds: Set<Int> = []
    /// Error from an add/remove action, shown as an alert.
    var actionError: String?

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    var count: Int { saved.count }

    /// Saved candidates grouped by municipality for the guide screen.
    var groupedByMunicipality: [(municipality: String, items: [SavedCandidate])] {
        let groups = Dictionary(grouping: saved) { entry in entry.candidate.municipalityName }
        return groups
            .map { name, entries in
                (municipality: name,
                 items: entries.sorted { lhs, rhs in lhs.candidate.positionId < rhs.candidate.positionId })
            }
            .sorted { lhs, rhs in lhs.municipality < rhs.municipality }
    }

    func isSaved(_ candidateId: Int) -> Bool {
        saved.contains { $0.candidateId == candidateId }
    }

    func isPending(_ candidateId: Int) -> Bool {
        pendingCandidateIds.contains(candidateId)
    }

    /// GET /api/savedcandidates
    func load() async {
        if saved.isEmpty { state = .loading }
        do {
            saved = try await service.savedCandidates()
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// POST /api/savedcandidates
    func add(_ candidate: Candidate) async {
        guard !isSaved(candidate.candidateId), !isPending(candidate.candidateId) else { return }
        pendingCandidateIds.insert(candidate.candidateId)
        defer { pendingCandidateIds.remove(candidate.candidateId) }

        do {
            let entry = try await service.saveCandidate(candidateId: candidate.candidateId)
            saved.insert(entry, at: 0)
        } catch APIError.server(let status, _) where status == 409 {
            // Already saved on another device — just resync.
            await load()
        } catch {
            actionError = error.localizedDescription
        }
    }

    /// DELETE /api/savedcandidates/{id}
    func remove(_ entry: SavedCandidate) async {
        let candidateId = entry.candidateId
        guard !isPending(candidateId) else { return }
        pendingCandidateIds.insert(candidateId)
        defer { pendingCandidateIds.remove(candidateId) }

        // Optimistic removal so swipe-to-delete feels instant; restored on failure.
        let previous = saved
        saved.removeAll { $0.savedCandidateId == entry.savedCandidateId }

        do {
            try await service.removeSavedCandidate(savedCandidateId: entry.savedCandidateId)
        } catch APIError.server(let status, _) where status == 404 {
            // Already gone on the server — keep it removed.
        } catch {
            saved = previous
            actionError = error.localizedDescription
        }
    }

    /// Remove by candidate (used by the toggle on Candidate Details).
    func remove(candidateId: Int) async {
        guard let entry = saved.first(where: { $0.candidateId == candidateId }) else { return }
        await remove(entry)
    }

    func reset() {
        saved = []
        state = .idle
        pendingCandidateIds = []
        actionError = nil
    }
}
