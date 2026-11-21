import Foundation

/// Errors from the Firebase layer, with user-friendly messages.
enum FirebaseServiceError: LocalizedError {
    case notSignedIn
    case authenticationFailed
    case duplicateSelection
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You're not signed in to the cloud service. Please sign out and sign in again."
        case .authenticationFailed:
            return "Couldn't sign in to the cloud service with this password. Please contact support."
        case .duplicateSelection:
            return "This candidate is already in your selections."
        case .invalidData:
            return "The cloud service sent data the app couldn't read."
        }
    }

    /// Turns Firestore / Firebase Auth / decoding errors into a message suitable for the UI.
    static func userMessage(for error: Error) -> String {
        if let known = error as? FirebaseServiceError { return known.errorDescription ?? "" }
        if error is DecodingError { return FirebaseServiceError.invalidData.errorDescription ?? "" }

        let nsError = error as NSError
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 14: // unavailable
                return "Can't reach the cloud database. Check your connection and try again."
            case 4: // deadlineExceeded
                return "The cloud database took too long to respond. Please try again."
            case 7: // permissionDenied
                return "You don't have permission to access this data."
            case 16: // unauthenticated
                return "Your cloud session has expired. Please sign out and sign in again."
            case 5: // notFound
                return "That selection no longer exists. Pull to refresh."
            default:
                return "The cloud database had a problem (\(nsError.code)). Please try again."
            }
        }
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17020: // networkError
                return "Can't reach the cloud service. Check your connection and try again."
            case 17010: // tooManyRequests
                return "Too many attempts. Please wait a moment and try again."
            default:
                return "Couldn't sign in to the cloud service (\(nsError.code))."
            }
        }
        if let urlError = error as? URLError {
            return APIError.network(urlError).errorDescription ?? urlError.localizedDescription
        }
        return error.localizedDescription
    }
}
