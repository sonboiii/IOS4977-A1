import Foundation
import Observation

@MainActor
@Observable
final class CandidateDetailViewModel {
    private(set) var candidate: Candidate
    private(set) var isRefreshing = false

    private let service: any ElectionServicing

    init(candidate: Candidate, service: any ElectionServicing = ElectionService.shared) {
        self.candidate = candidate
        self.service = service
    }

    /// GET /api/candidates/{id} — refreshes the row data passed in from the list.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        if let fresh = try? await service.candidate(id: candidate.candidateId) {
            candidate = fresh
        }
    }
}
