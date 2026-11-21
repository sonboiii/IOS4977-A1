import Foundation

/// A document in the Firestore `CandidateSelections` collection.
///
/// The document ID is `<userEmail>_<candidateId>`, so the same user can never store the
/// same candidate twice. `Date` fields are stored as Firestore Timestamps.
struct CandidateSelection: Codable, Identifiable, Hashable {
    var id: String
    var userEmail: String
    var candidateId: Int
    var candidateName: String
    var candidatePhotoUrl: String?
    var positionId: Int
    var positionName: String
    var municipalityId: Int
    var municipalityName: String
    var notes: String
    var dateCreated: Date
    var dateModified: Date

    static let maxNotesLength = 500

    static func documentId(userEmail: String, candidateId: Int) -> String {
        "\(userEmail.lowercased())_\(candidateId)"
    }

    init(candidate: Candidate, userEmail: String, notes: String, now: Date = Date()) {
        let email = userEmail.lowercased()
        id = Self.documentId(userEmail: email, candidateId: candidate.candidateId)
        self.userEmail = email
        candidateId = candidate.candidateId
        candidateName = candidate.name
        candidatePhotoUrl = candidate.photoUrl
        positionId = candidate.positionId
        positionName = candidate.positionName
        municipalityId = candidate.municipalityId
        municipalityName = candidate.municipalityName
        self.notes = notes
        dateCreated = now
        dateModified = now
    }

    var photoURL: URL? { candidatePhotoUrl.flatMap(URL.init(string:)) }

    /// Enough of a Candidate to open the detail screen, which then loads the full record from the API.
    var candidateStub: Candidate {
        Candidate(candidateId: candidateId,
                  name: candidateName,
                  biography: nil,
                  photoUrl: candidatePhotoUrl,
                  website: nil,
                  email: nil,
                  positionId: positionId,
                  positionName: positionName,
                  municipalityId: municipalityId,
                  municipalityName: municipalityName)
    }
}

/// A document in the Firestore `UserProfiles` collection (document ID = the user's email).
/// Holds the municipality the user lives in.
struct UserProfile: Codable, Equatable {
    var userEmail: String
    var municipalityId: Int
    var municipalityName: String
    var dateModified: Date
}
