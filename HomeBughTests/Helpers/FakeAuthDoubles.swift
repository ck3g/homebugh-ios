//
//  FakeAuthDoubles.swift
//  HomeBughTests
//
//  Fakes for the auth stack: in-memory token store, stubbed auth service,
//  and a stubbed HTTP client.
//

import Foundation
@testable import HomeBugh

final class FakeTokenStore: TokenStore {
    private(set) var saved: String?
    private(set) var deleteCalled = false

    var hasToken: Bool { saved != nil }

    func save(_ token: String) throws { saved = token }
    func read() -> String? { saved }
    func delete() throws { saved = nil; deleteCalled = true }
}

final class FakeServerConfigStore: ServerConfigStoring {
    private(set) var baseURL: URL?
    func setBaseURL(_ url: URL?) { baseURL = url }
}

final class FakeAuthService: AuthServicing {
    var loginResult: Result<String, Error> = .failure(APIError.transport)
    var logoutError: Error?
    private(set) var loginCalls: [(email: String, password: String)] = []
    private(set) var logoutCalls: [String] = []

    func login(email: String, password: String) async throws -> String {
        loginCalls.append((email, password))
        return try loginResult.get()
    }

    func logout(token: String) async throws {
        logoutCalls.append(token)
        if let logoutError { throw logoutError }
    }
}
