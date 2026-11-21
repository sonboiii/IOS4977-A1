import Foundation

/// Election data from the ASP.NET Core Web API. Every election query is scoped to a municipality
/// with `?city=`, so the app never receives data for other municipalities (Assignment 2, Part 3).
/// View models depend on this protocol, which keeps them testable.
protocol ElectionServicing {
    /// All municipalities — used only by the municipality picker.
    func municipalities() async throws -> [Municipality]

    /// GET /api/elections?city= — election date plus the offices and their seat counts.
    func election(city: String) async throws -> MunicipalityDetail

    /// GET /api/offices?city=
    func offices(city: String) async throws -> [Position]

    /// GET /api/candidates?city=
    func candidates(city: String) async throws -> [Candidate]

    /// GET /api/candidates/search?name=&city=
    func searchCandidates(name: String, city: String) async throws -> [Candidate]

    /// GET /api/candidates/{id}?city= — 404 when the candidate belongs to another municipality.
    func candidate(id: Int, city: String) async throws -> Candidate
}

struct ElectionService: ElectionServicing {
    static let shared = ElectionService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func municipalities() async throws -> [Municipality] {
        try await client.get("api/municipalities")
    }

    func election(city: String) async throws -> MunicipalityDetail {
        let elections: [MunicipalityDetail] = try await client.get("api/elections", query: cityQuery(city))
        guard let election = elections.first else {
            throw APIError.server(status: 404, message: "No election was found for \(city).")
        }
        return election
    }

    func offices(city: String) async throws -> [Position] {
        try await client.get("api/offices", query: cityQuery(city))
    }

    func candidates(city: String) async throws -> [Candidate] {
        try await client.get("api/candidates", query: cityQuery(city))
    }

    func searchCandidates(name: String, city: String) async throws -> [Candidate] {
        try await client.get("api/candidates/search",
                             query: [URLQueryItem(name: "name", value: name)] + cityQuery(city))
    }

    func candidate(id: Int, city: String) async throws -> Candidate {
        try await client.get("api/candidates/\(id)", query: cityQuery(city))
    }

    private func cityQuery(_ city: String) -> [URLQueryItem] {
        [URLQueryItem(name: "city", value: city)]
    }
}
