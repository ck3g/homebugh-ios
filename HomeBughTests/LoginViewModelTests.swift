//
//  LoginViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for LoginViewModel.
//

import Combine
import XCTest
@testable import HomeBugh

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var tokenStore: FakeTokenStore!
    private var serverConfig: FakeServerConfigStore!
    private var authService: FakeAuthService!
    private var useCase: DefaultAuthUseCase!
    private var sut: LoginViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        tokenStore = FakeTokenStore()
        serverConfig = FakeServerConfigStore()
        authService = FakeAuthService()
        useCase = DefaultAuthUseCase(
            tokenStore: tokenStore,
            serverConfig: serverConfig,
            makeAuthService: { [authService] _ in authService! }
        )
        sut = LoginViewModel(authUseCase: useCase)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        useCase = nil
        authService = nil
        serverConfig = nil
        tokenStore = nil
        super.tearDown()
    }

    // MARK: - Validation

    func test_isValid_requiresServerURLEmailAndPassword() {
        XCTAssertFalse(sut.isValid)
        sut.serverURL = "https://x.com"
        sut.email = "a@b.com"
        sut.password = "secret"
        XCTAssertTrue(sut.isValid)
    }

    func test_isValid_rejectsInvalidServerURL() {
        sut.serverURL = "not a url"
        sut.email = "a@b.com"
        sut.password = "secret"
        XCTAssertFalse(sut.isValid)
    }

    // MARK: - Login

    func test_login_success_setsDidLogin() async {
        authService.loginResult = .success("token-xyz")
        sut.serverURL = "https://x.com"
        sut.email = "a@b.com"
        sut.password = "secret"

        await whenDidLogin { sut.login() }

        XCTAssertTrue(sut.didLogin)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(tokenStore.saved, "token-xyz")
    }

    func test_login_unauthorized_setsErrorMessage() async {
        authService.loginResult = .failure(APIError.unauthorized)
        sut.serverURL = "https://x.com"
        sut.email = "a@b.com"
        sut.password = "wrong"

        await whenError { sut.login() }

        XCTAssertEqual(sut.errorMessage, "Invalid email or password.")
        XCTAssertFalse(sut.didLogin)
    }

    func test_login_transportError_setsErrorMessage() async {
        authService.loginResult = .failure(APIError.transport)
        sut.serverURL = "https://x.com"
        sut.email = "a@b.com"
        sut.password = "secret"

        await whenError { sut.login() }

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.didLogin)
    }

    // MARK: - Helpers

    private func whenDidLogin(_ action: () -> Void, timeout: TimeInterval = 2.0) async {
        let exp = expectation(description: "didLogin")
        exp.assertForOverFulfill = false
        var cancellable: AnyCancellable?
        cancellable = sut.$didLogin.dropFirst().sink { value in
            if value { exp.fulfill(); cancellable?.cancel() }
        }
        action()
        await fulfillment(of: [exp], timeout: timeout)
        cancellable?.cancel()
    }

    private func whenError(_ action: () -> Void, timeout: TimeInterval = 2.0) async {
        let exp = expectation(description: "error")
        exp.assertForOverFulfill = false
        var cancellable: AnyCancellable?
        cancellable = sut.$errorMessage.dropFirst().sink { value in
            if value != nil { exp.fulfill(); cancellable?.cancel() }
        }
        action()
        await fulfillment(of: [exp], timeout: timeout)
        cancellable?.cancel()
    }
}
