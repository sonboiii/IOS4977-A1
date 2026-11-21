import Foundation

enum APIError: LocalizedError {
    /// Network-level failure (offline, timeout, DNS, TLS...).
    case network(URLError)
    /// 401 – bad credentials, or an expired/missing token on a protected endpoint.
    case unauthorized(String?)
    /// Any other non-2xx response, with the API's problem-details message when available.
    case server(status: Int, message: String)
    /// The response body didn't match the Codable model.
    case decoding(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .network(let error):
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "You appear to be offline. Check your connection and try again."
            case .timedOut:
                return "The server took too long to respond. Please try again."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "Couldn't reach the elections server. Please try again later."
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return "A secure connection to the server couldn't be made."
            default:
                return "A network error occurred (\(error.localizedDescription))."
            }
        case .unauthorized(let message):
            return message ?? "Your session has expired. Please sign in again."
        case .server(let status, let message):
            return status >= 500
                ? "The server had a problem (\(status)). Please try again later."
                : message
        case .decoding:
            return "The server sent data the app couldn't read."
        case .invalidResponse:
            return "The server sent an invalid response."
        }
    }

    /// True when the request was cancelled (e.g. the user kept typing in search). Not shown to the user.
    var isCancellation: Bool {
        if case .network(let error) = self { return error.code == .cancelled }
        return false
    }
}

extension Error {
    /// Cancellation from either Swift concurrency or URLSession.
    var isCancelledRequest: Bool {
        if self is CancellationError { return true }
        if let apiError = self as? APIError { return apiError.isCancellation }
        return (self as? URLError)?.code == .cancelled
    }
}
