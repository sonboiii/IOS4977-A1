import Foundation

extension Notification.Name {
    /// Posted when a protected request returns 401, so the session can sign the user out.
    static let sessionExpired = Notification.Name("sessionExpired")
}

/// Thin async/await wrapper around URLSession for the Municipal Elections API.
final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: TokenStore
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL = AppConfig.apiBaseURL,
         session: URLSession = .shared,
         tokenStore: TokenStore = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
    }

    // MARK: - Verbs

    func get<T: Decodable>(_ path: String,
                           query: [URLQueryItem] = [],
                           authorized: Bool = false) async throws -> T {
        let request = try makeRequest("GET", path, query: query, body: nil, authorized: authorized)
        return try decode(try await perform(request))
    }

    func post<T: Decodable>(_ path: String,
                            body: any Encodable,
                            authorized: Bool = false) async throws -> T {
        let request = try makeRequest("POST", path, query: [], body: body, authorized: authorized)
        return try decode(try await perform(request))
    }

    func delete(_ path: String, authorized: Bool = true) async throws {
        let request = try makeRequest("DELETE", path, query: [], body: nil, authorized: authorized)
        _ = try await perform(request)
    }

    // MARK: - Internals

    private func makeRequest(_ method: String,
                             _ path: String,
                             query: [URLQueryItem],
                             body: (any Encodable)?,
                             authorized: Bool) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        if authorized {
            guard let token = tokenStore.token else {
                throw APIError.unauthorized(nil)
            }
            // Protected endpoints require: Authorization: Bearer <jwt>
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.network(error)
        }
        let (data, response) = result

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401:
            let message = problemMessage(from: data)
            if request.value(forHTTPHeaderField: "Authorization") != nil {
                // Token rejected (expired or invalid) — sign the user out.
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
                throw APIError.unauthorized(nil)
            }
            throw APIError.unauthorized(message)
        default:
            let message = problemMessage(from: data)
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode).capitalized
            throw APIError.server(status: http.statusCode, message: message)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding \(T.self) failed:", error)
            #endif
            throw APIError.decoding(error)
        }
    }

    private func problemMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        return (try? decoder.decode(ProblemDetails.self, from: data))?.message
    }
}
