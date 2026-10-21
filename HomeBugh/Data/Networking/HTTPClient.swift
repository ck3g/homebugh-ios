//
//  HTTPClient.swift
//  HomeBugh
//
//  Async HTTP client for the Homebugh API. Handles base URL, bearer token,
//  snake_case JSON coding, and HTTP status -> APIError mapping.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case patch = "PATCH"
}

protocol HTTPClient {
    /// Sends a request and decodes the JSON response into `Response`.
    func send<Request: Encodable, Response: Decodable>(
        method: HTTPMethod,
        path: String,
        body: Request?,
        token: String?
    ) async throws -> Response

    /// Sends a request that returns no decodable body (e.g. logout).
    func send<Request: Encodable>(
        method: HTTPMethod,
        path: String,
        body: Request?,
        token: String?
    ) async throws
}

/// Convenience for calls with no request body.
struct EmptyBody: Encodable {}

final class URLSessionHTTPClient: HTTPClient {

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public API

    func send<Request: Encodable, Response: Decodable>(
        method: HTTPMethod,
        path: String,
        body: Request?,
        token: String?
    ) async throws -> Response {
        let data = try await perform(method: method, path: path, body: body, token: token)
        do {
            return try Self.makeDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    func send<Request: Encodable>(
        method: HTTPMethod,
        path: String,
        body: Request?,
        token: String?
    ) async throws {
        _ = try await perform(method: method, path: path, body: body, token: token)
    }

    // MARK: - Request execution

    private func perform<Request: Encodable>(
        method: HTTPMethod,
        path: String,
        body: Request?,
        token: String?
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try Self.makeEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport
        }

        try Self.validate(statusCode: http.statusCode, data: data)
        return data
    }

    // MARK: - Status mapping

    private static func validate(statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            let payload = try? makeDecoder().decode(ValidationErrorPayload.self, from: data)
            throw APIError.validation(message: payload?.error, details: payload?.details)
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.server(statusCode: statusCode)
        default:
            throw APIError.unexpected(statusCode: statusCode)
        }
    }

    // MARK: - Coding

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

/// Shape of a 422 validation error response.
private struct ValidationErrorPayload: Decodable {
    let error: String?
    let details: [String: [String]]?
}
