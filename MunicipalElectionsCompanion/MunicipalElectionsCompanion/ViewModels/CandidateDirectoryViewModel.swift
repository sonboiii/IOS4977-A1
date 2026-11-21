import Foundation
import Observation

/// Candidate Directory for the configured municipality (GET /api/candidates?city=).
@MainActor
@Observable
final class CandidateDirectoryViewModel {
    // Inputs
    var searchText = ""
    /// Office filter ("Mayor", "Councillor", "School Trustee").
    var selectedPositionName: String?

    // Outputs
    private(set) var candidates: [Candidate] = []
    private(set) var state: LoadState = .idle
    private(set) var loadedCity: String?

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    var trimmedSearch: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasActiveFilters: Bool { selectedPositionName != nil }

    /// Office names in the order the API returns them.
    var positionNames: [String] {
        var seen = Set<String>()
        return candidates
            .sorted { $0.positionId < $1.positionId }
            .map(\.positionName)
            .filter { seen.insert($0).inserted }
    }

    var filteredCandidates: [Candidate] {
        candidates.filter { selectedPositionName == nil || $0.positionName == selectedPositionName }
    }

    /// GET /api/candidates?city=, or /api/candidates/search?name=&city= while searching.
    func loadCandidates(city: String) async {
        if city != loadedCity {
            // Municipality changed: drop the previous municipality's candidates straight away.
            candidates = []
            selectedPositionName = nil
            loadedCity = city
        }
        if candidates.isEmpty { state = .loading }
        do {
            let term = trimmedSearch
            let fresh: [Candidate]
            if term.isEmpty {
                fresh = try await service.candidates(city: city)
            } else {
                fresh = try await service.searchCandidates(name: term, city: city)
            }
            guard city == loadedCity else { return }
            candidates = fresh
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // A newer search replaced this one.
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Called on every keystroke; waits briefly so the API isn't hit for each character.
    func searchTextChanged(city: String) async {
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return // cancelled by the next keystroke
        }
        await loadCandidates(city: city)
    }

    func clearFilters() {
        selectedPositionName = nil
    }
}
