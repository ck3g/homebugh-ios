//
//  HTTPSyncTransport.swift
//  HomeBugh
//
//  SyncTransport backed by the HTTP client, targeting POST /api/v1/sync.
//

import Foundation

final class HTTPSyncTransport: SyncTransport {

    private enum Path {
        static let sync = "sync"
    }

    private let httpClient: HTTPClient
    private let token: String

    init(httpClient: HTTPClient, token: String) {
        self.httpClient = httpClient
        self.token = token
    }

    func sync(_ request: SyncRequestDTO) async throws -> SyncResponseDTO {
        try await httpClient.send(
            method: .post,
            path: Path.sync,
            body: request,
            token: token
        )
    }
}
