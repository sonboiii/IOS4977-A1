import Foundation
import Observation

@MainActor
@Observable
final class MunicipalitiesViewModel {
    private(set) var municipalities: [Municipality] = []
    private(set) var state: LoadState = .idle

    private let service: any ElectionServicing

    init(service: any ElectionServicing = ElectionService.shared) {
        self.service = service
    }

    /// GET /api/municipalities
    func load() async {
        if municipalities.isEmpty { state = .loading }
        do {
            municipalities = try await service.municipalities()
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

/// A position with the candidates running for it.
struct PositionSection: Identifiable {
    let position: Position
    let candidates: [Candidate]
    var id: Int { position.positionId }
}

@MainActor
@Observable
final class MunicipalityDetailViewModel {
    let municipality: Municipality
    private(set) var detail: MunicipalityDetail?
    private(set) var sections: [PositionSection] = []
    private(set) var state: LoadState = .idle

    private let service: any ElectionServicing

    init(municipality: Municipality, service: any ElectionServicing = ElectionService.shared) {
        self.municipality = municipality
        self.service = service
    }

    /// GET /api/municipalities/{id} + GET /api/candidates?municipalityId={id}
    func load() async {
        if detail == nil { state = .loading }
        do {
            async let detailRequest = service.municipality(id: municipality.municipalityId)
            async let candidatesRequest = service.candidates(municipalityId: municipality.municipalityId,
                                                             positionId: nil)
            let (detail, candidates) = try await (detailRequest, candidatesRequest)

            self.detail = detail
            sections = detail.positions.map { position in
                PositionSection(position: position,
                                candidates: candidates.filter { $0.positionId == position.positionId })
            }
            state = .loaded
        } catch let error where error.isCancelledRequest {
            // ignore
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
