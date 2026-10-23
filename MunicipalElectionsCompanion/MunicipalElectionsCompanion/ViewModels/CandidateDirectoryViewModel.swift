import Foundation
import Observation

@MainActor
@Observable
final class CandidateDirectoryViewModel {
    // Inputs
    var searchText = ""
    var selectedMunicipalityId: Int?
    /// Position filter by name ("Mayor", "Councillor", "School Trustee") so it works across municipalities.
    var selectedPositionName: String?

    // Outputs
    private(set) var candidates: [Candidate] = []
    private(set) var municipalities: [Municipality] = []
    private(set) var positionNames: [String] = []
    private(set) var state: LoadState = .idle

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    var trimmedSearch: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasActiveFilters: Bool { selectedMunicipalityId != nil || selectedPositionName != nil }

    var selectedMunicipalityName: String? {
        municipalities.first { $0.municipalityId == selectedMunicipalityId }?.name
    }

    /// Candidates after the municipality / position filters are applied.
    var filteredCandidates: [Candidate] {
        candidates.filter { candidate in
            (selectedMunicipalityId == nil || candidate.municipalityId == selectedMunicipalityId) &&
            (selectedPositionName == nil || candidate.positionName == selectedPositionName)
        }
    }

    /// Filter options: GET /api/municipalities and GET /api/positions (loaded once).
    func loadFilterOptions() async {
        guard municipalities.isEmpty else { return }
        do {
            async let municipalitiesRequest = service.municipalities()
            async let positionsRequest = service.positions(municipalityId: nil)
            let (municipalities, positions) = try await (municipalitiesRequest, positionsRequest)
            self.municipalities = municipalities
            // Unique names, in the order the API returns them (Mayor, Councillor, School Trustee).
            var seen = Set<String>()
            positionNames = positions.map(\.name).filter { seen.insert($0).inserted }
        } catch {
            // Filters are optional; the list still works without them.
        }
    }

    /// GET /api/candidates, or GET /api/candidates/search?name= when the user is searching.
    func loadCandidates() async {
        if candidates.isEmpty { state = .loading }
        do {
            let term = trimmedSearch
            if term.isEmpty {
                candidates = try await service.candidates(municipalityId: nil, positionId: nil)
            } else {
                candidates = try await service.searchCandidates(name: term)
            }
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // A newer search replaced this one.
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Called on every keystroke; waits briefly so the API isn't hit for each character.
    func searchTextChanged() async {
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return // cancelled by the next keystroke
        }
        await loadCandidates()
    }

    func clearFilters() {
        selectedMunicipalityId = nil
        selectedPositionName = nil
    }
}
