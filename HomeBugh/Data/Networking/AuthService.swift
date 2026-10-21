//
//  AuthService.swift
//  HomeBugh
//
//  Talks to the authentication endpoints (POST/DELETE /api/v1/token).
//

import Foundation

protocol AuthServicing {
    /// Logs in and returns the bearer token.
    func login(email: String, password: String) async throws -> String
    /// Revokes the current token on the server.
    func logout(token: String) async throws
}

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct LoginResponseDTO: Decodable {
    let token: String
    let userId: Int
}

final class AuthService: AuthServicing {

    private enum Path {
        static let token = "token"
    }

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func login(email: String, password: String) async throws -> String {
        let body = LoginRequestDTO(email: email, password: password)
        let response: LoginResponseDTO = try await httpClient.send(
            method: .post,
            path: Path.token,
            body: body,
            token: nil
        )
        return response.token
    }

    func logout(token: String) async throws {
        try await httpClient.send(
            method: .delete,
            path: Path.token,
            body: Optional<EmptyBody>.none,
            token: token
        )
    }
}
