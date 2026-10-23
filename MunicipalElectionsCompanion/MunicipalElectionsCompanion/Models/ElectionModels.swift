import Foundation

/// GET /api/municipalities
struct Municipality: Codable, Identifiable, Hashable {
    let municipalityId: Int
    let name: String
    let province: String
    /// "yyyy-MM-dd"
    let electionDate: String
    let description: String?
    let logoUrl: String?
    let candidateCount: Int

    var id: Int { municipalityId }
    var logoURL: URL? { logoUrl.flatMap(URL.init(string:)) }
    var formattedElectionDate: String { DateParsing.displayDate(fromDay: electionDate) }
}

/// GET /api/municipalities/{id}
struct MunicipalityDetail: Codable {
    let municipalityId: Int
    let name: String
    let province: String
    let electionDate: String
    let description: String?
    let logoUrl: String?
    let candidateCount: Int
    let positions: [Position]

    var logoURL: URL? { logoUrl.flatMap(URL.init(string:)) }
    var formattedElectionDate: String { DateParsing.displayDate(fromDay: electionDate) }
}

/// GET /api/positions
struct Position: Codable, Identifiable, Hashable {
    let positionId: Int
    let name: String
    let seatsAvailable: Int
    let municipalityId: Int
    let municipalityName: String
    let candidateCount: Int

    var id: Int { positionId }

    var seatsText: String {
        seatsAvailable == 1 ? "1 seat" : "\(seatsAvailable) seats"
    }
}

/// GET /api/candidates
struct Candidate: Codable, Identifiable, Hashable {
    let candidateId: Int
    let name: String
    let biography: String?
    let photoUrl: String?
    let website: String?
    let email: String?
    let positionId: Int
    let positionName: String
    let municipalityId: Int
    let municipalityName: String

    var id: Int { candidateId }
    var photoURL: URL? { photoUrl.flatMap(URL.init(string:)) }

    var websiteURL: URL? {
        guard let website, !website.isEmpty else { return nil }
        return URL(string: website.hasPrefix("http") ? website : "https://\(website)")
    }

    var emailURL: URL? {
        guard let email, !email.isEmpty else { return nil }
        return URL(string: "mailto:\(email)")
    }
}

/// GET /api/savedcandidates
struct SavedCandidate: Codable, Identifiable, Hashable {
    let savedCandidateId: Int
    let candidateId: Int
    /// ISO-8601 UTC timestamp.
    let dateSaved: String
    let candidate: Candidate

    var id: Int { savedCandidateId }
    var savedDate: Date? { DateParsing.date(fromISO: dateSaved) }
}

struct SaveCandidateRequest: Encodable {
    let candidateId: Int
}

/// RFC 7807 problem details returned by the API on errors.
struct ProblemDetails: Decodable {
    let title: String?
    let detail: String?
    let status: Int?
    let errors: [String: [String]]?

    var message: String? {
        if let errors, !errors.isEmpty {
            return errors.values.flatMap { $0 }.joined(separator: "\n")
        }
        return detail ?? title
    }
}
