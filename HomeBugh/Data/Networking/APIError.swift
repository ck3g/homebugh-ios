//
//  APIError.swift
//  HomeBugh
//
//  Errors surfaced by the networking layer, mapped from HTTP status codes.
//

import Foundation

enum APIError: Error, Equatable {
    /// No network connection or the request could not be sent.
    case transport
    /// 401 — authentication failed or token expired.
    case unauthorized
    /// 403 — authenticated but not allowed (another user's data).
    case forbidden
    /// 404 — resource not found.
    case notFound
    /// 422 — validation errors, with optional per-field details.
    case validation(message: String?, details: [String: [String]]?)
    /// 429 — rate limited.
    case rateLimited
    /// 5xx — server error.
    case server(statusCode: Int)
    /// Response could not be decoded into the expected type.
    case decoding
    /// Any other unexpected status code.
    case unexpected(statusCode: Int)
}
