//
//  AuthUseCase.swift
//  HomeBugh
//
//  Business operations for connecting to / disconnecting from a server.
//  ViewModels depend on this protocol, not on AuthService/TokenStore directly.
//

import Foundation

protocol AuthUseCase {
    /// Configures the server, logs in, and stores the token. Returns on success.
    func login(serverURL: URL, email: String, password: String) async throws
    /// Revokes the token on the server (best effort) and clears local credentials.
    func logout() async throws
    /// Whether a server session is currently active.
    var isLoggedIn: Bool { get }
}

final class DefaultAuthUseCase: AuthUseCase {

    private let tokenStore: TokenStore
    private let serverConfig: ServerConfigStoring
    private let makeAuthService: (URL) -> AuthServicing

    /// - Parameter makeAuthService: builds an AuthService bound to a given base URL.
    ///   Injected so the use case can target the server the user just entered.
    init(
        tokenStore: TokenStore,
        serverConfig: ServerConfigStoring,
        makeAuthService: @escaping (URL) -> AuthServicing
    ) {
        self.tokenStore = tokenStore
        self.serverConfig = serverConfig
        self.makeAuthService = makeAuthService
    }

    var isLoggedIn: Bool {
        tokenStore.hasToken
    }

    func login(serverURL: URL, email: String, password: String) async throws {
        let service = makeAuthService(serverURL)
        let token = try await service.login(email: email, password: password)
        serverConfig.setBaseURL(serverURL)
        try tokenStore.save(token)
    }

    func logout() async throws {
        if let token = tokenStore.read() {
            let baseURL = serverConfig.baseURL ?? URL(string: "https://invalid.local")!
            let service = makeAuthService(baseURL)
            // Best effort: revoke on server, but always clear locally.
            try? await service.logout(token: token)
        }
        try tokenStore.delete()
        serverConfig.setBaseURL(nil)
    }
}
