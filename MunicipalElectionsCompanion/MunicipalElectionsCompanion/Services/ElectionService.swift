import Foundation

/// One method per API endpoint. View models depend on this protocol, which keeps them testable.
protocol ElectionServicing {
    // Auth
    func login(email: String, password: String) async throws -> AuthResponse
    func register(name: String, email: String, password: String) async throws -> AuthResponse
    func currentUser() async throws -> User

    // Municipalities
    func municipalities() async throws -> [Municipality]
    func municipality(id: Int) async throws -> MunicipalityDetail

    // Positions
    func positions(municipalityId: Int?) async throws -> [Position]

    // Candidates
    func candidates(municipalityId: Int?, positionId: Int?) async throws -> [Candidate]
    func candidate(id: Int) async throws -> Candidate
    func searchCandidates(name: String) async throws -> [Candidate]

    // Voting guide (authenticated)
    func savedCandidates() async throws -> [SavedCandidate]
    func saveCandidate(candidateId: Int) async throws -> SavedCandidate
    func removeSavedCandidate(savedCandidateId: Int) async throws
}

struct ElectionService: ElectionServicing {
    static let shared = ElectionService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        try await client.post("api/auth/login", body: LoginRequest(email: email, password: password))
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try await client.post("api/auth/register",
                              body: RegisterRequest(name: name, email: email, password: password))
    }

    func currentUser() async throws -> User {
        try await client.get("api/auth/me", authorized: true)
    }

    // MARK: Municipalities

    func municipalities() async throws -> [Municipality] {
        try await client.get("api/municipalities")
    }

    func municipality(id: Int) async throws -> MunicipalityDetail {
        try await client.get("api/municipalities/\(id)")
    }

    // MARK: Positions

    func positions(municipalityId: Int? = nil) async throws -> [Position] {
        var query: [URLQueryItem] = []
        if let municipalityId { query.append(URLQueryItem(name: "municipalityId", value: String(municipalityId))) }
        return try await client.get("api/positions", query: query)
    }

    // MARK: Candidates

    func candidates(municipalityId: Int? = nil, positionId: Int? = nil) async throws -> [Candidate] {
        var query: [URLQueryItem] = []
        if let municipalityId { query.append(URLQueryItem(name: "municipalityId", value: String(municipalityId))) }
        if let positionId { query.append(URLQueryItem(name: "positionId", value: String(positionId))) }
        return try await client.get("api/candidates", query: query)
    }

    func candidate(id: Int) async throws -> Candidate {
        try await client.get("api/candidates/\(id)")
    }

    func searchCandidates(name: String) async throws -> [Candidate] {
        try await client.get("api/candidates/search", query: [URLQueryItem(name: "name", value: name)])
    }

    // MARK: Voting guide

    func savedCandidates() async throws -> [SavedCandidate] {
        try await client.get("api/savedcandidates", authorized: true)
    }

    func saveCandidate(candidateId: Int) async throws -> SavedCandidate {
        try await client.post("api/savedcandidates",
                              body: SaveCandidateRequest(candidateId: candidateId),
                              authorized: true)
    }

    func removeSavedCandidate(savedCandidateId: Int) async throws {
        try await client.delete("api/savedcandidates/\(savedCandidateId)")
    }
}
