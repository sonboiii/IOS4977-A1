import Foundation
import FirebaseFirestore

/// Firestore access for candidate selections and the user's municipality.
/// Every query is filtered by the signed-in user's email; the security rules
/// (firestore.rules at the repo root) enforce the same thing on the server.
protocol FirestoreServicing {
    // CandidateSelections
    func selections(userEmail: String, municipality: String) async throws -> [CandidateSelection]
    func create(_ selection: CandidateSelection) async throws
    func updateNotes(selectionId: String, notes: String, modified: Date) async throws
    func deleteSelection(id: String) async throws

    // UserProfiles
    func profile(userEmail: String) async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
}

final class FirestoreService: FirestoreServicing {
    static let shared = FirestoreService()

    enum Collection {
        static let selections = "CandidateSelections"
        static let profiles = "UserProfiles"
    }

    /// Resolved lazily so FirebaseApp.configure() has run before Firestore is first used.
    private var db: Firestore { Firestore.firestore() }

    // MARK: CandidateSelections

    /// READ: the user's selections for one municipality.
    func selections(userEmail: String, municipality: String) async throws -> [CandidateSelection] {
        let snapshot = try await db.collection(Collection.selections)
            .whereField("userEmail", isEqualTo: userEmail.lowercased())
            .whereField("municipalityName", isEqualTo: municipality)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: CandidateSelection.self) }
    }

    /// CREATE: refuses to overwrite an existing selection (duplicates are not permitted).
    func create(_ selection: CandidateSelection) async throws {
        let reference = db.collection(Collection.selections).document(selection.id)
        let existing = try await reference.getDocument()
        if existing.exists {
            throw FirebaseServiceError.duplicateSelection
        }
        try await reference.setData(try Firestore.Encoder().encode(selection))
    }

    /// UPDATE: only the notes and the modified date change.
    func updateNotes(selectionId: String, notes: String, modified: Date) async throws {
        try await db.collection(Collection.selections).document(selectionId).updateData([
            "notes": notes,
            "dateModified": Timestamp(date: modified)
        ])
    }

    /// DELETE
    func deleteSelection(id: String) async throws {
        try await db.collection(Collection.selections).document(id).delete()
    }

    // MARK: UserProfiles

    func profile(userEmail: String) async throws -> UserProfile? {
        let document = try await db.collection(Collection.profiles)
            .document(userEmail.lowercased())
            .getDocument()
        guard document.exists else { return nil }
        return try document.data(as: UserProfile.self)
    }

    func saveProfile(_ profile: UserProfile) async throws {
        try await db.collection(Collection.profiles)
            .document(profile.userEmail.lowercased())
            .setData(try Firestore.Encoder().encode(profile), merge: true)
    }
}
