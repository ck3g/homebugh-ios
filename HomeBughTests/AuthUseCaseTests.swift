//
//  AuthUseCaseTests.swift
//  HomeBughTests
//
//  Unit tests for DefaultAuthUseCase.
//

import XCTest
@testable import HomeBugh

final class AuthUseCaseTests: XCTestCase {

    private var tokenStore: FakeTokenStore!
    private var serverConfig: FakeServerConfigStore!
    private var authService: FakeAuthService!
    private var sut: DefaultAuthUseCase!

    override func setUp() {
        super.setUp()
        tokenStore = FakeTokenStore()
        serverConfig = FakeServerConfigStore()
        authService = FakeAuthService()
        sut = DefaultAuthUseCase(
            tokenStore: tokenStore,
            serverConfig: serverConfig,
            makeAuthService: { [authService] _ in authService! }
        )
    }

    override func tearDown() {
        sut = nil
        authService = nil
        serverConfig = nil
        tokenStore = nil
        super.tearDown()
    }

    func test_login_success_storesTokenAndServerURL() async throws {
        authService.loginResult = .success("token-123")
        let url = URL(string: "https://my-server.com")!

        try await sut.login(serverURL: url, email: "a@b.com", password: "secret")

        XCTAssertEqual(tokenStore.saved, "token-123")
        XCTAssertEqual(serverConfig.baseURL, url)
        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertEqual(authService.loginCalls.first?.email, "a@b.com")
    }

    func test_login_failure_doesNotStoreToken() async {
        authService.loginResult = .failure(APIError.unauthorized)

        do {
            try await sut.login(serverURL: URL(string: "https://x.com")!, email: "a", password: "b")
            XCTFail("Expected error")
        } catch {
            XCTAssertNil(tokenStore.saved)
            XCTAssertNil(serverConfig.baseURL)
            XCTAssertFalse(sut.isLoggedIn)
        }
    }

    func test_logout_clearsTokenAndServerURL() async throws {
        try tokenStore.save("existing")
        serverConfig.setBaseURL(URL(string: "https://x.com"))

        try await sut.logout()

        XCTAssertNil(tokenStore.read())
        XCTAssertNil(serverConfig.baseURL)
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertEqual(authService.logoutCalls.first, "existing")
    }

    func test_logout_clearsLocallyEvenIfServerRevocationFails() async throws {
        try tokenStore.save("existing")
        authService.logoutError = APIError.transport

        try await sut.logout()

        XCTAssertNil(tokenStore.read(), "Token must be cleared even if server logout fails")
    }
}
