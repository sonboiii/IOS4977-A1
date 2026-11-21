import Foundation
import Observation

/// Home screen: the configured municipality's election (date, offices, seats).
@MainActor
@Observable
final class HomeViewModel {
    private(set) var election: MunicipalityDetail?
    private(set) var state: LoadState = .idle
    private var loadedCity: String?

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    /// GET /api/elections?city=
    func load(city: String) async {
        if city != loadedCity {
            election = nil
            loadedCity = city
        }
        if election == nil { state = .loading }
        do {
            let fresh = try await service.election(city: city)
            guard city == loadedCity else { return }
            election = fresh
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
