//
//  AuthTokenStorageTests.swift
//  HomeBughTests
//
//  Unit tests for AuthTokenStorage.
//

import XCTest
@testable import HomeBugh

final class AuthTokenStorageTests: XCTestCase {

    private var fakeStorage: FakeUnderlyingStorage!
    private var sut: AuthTokenStorage!

    override func setUp() {
        super.setUp()
        fakeStorage = FakeUnderlyingStorage()
        sut = AuthTokenStorage(fakeStorage)
    }

    override func tearDown() {
        sut = nil
        fakeStorage = nil
        super.tearDown()
    }

    // MARK: - checkToken

    func testCheckTokenReturnsFalseWhenNotSet() {
        XCTAssertFalse(sut.checkToken())
    }

    func testCheckTokenReturnsTrueWhenSet() {
        sut.setToken(Token(token: "abc123"))
        XCTAssertTrue(sut.checkToken())
    }

    // MARK: - getToken

    func testGetTokenReturnsEmptyStringWhenNotSet() {
        XCTAssertEqual(sut.getToken(), "")
    }

    func testGetTokenReturnsTokenValue() {
        sut.setToken(Token(token: "abc123"))
        XCTAssertEqual(sut.getToken(), "abc123")
    }

    // MARK: - Persistence

    func testTokenPersistsAcrossInstances() {
        sut.setToken(Token(token: "persisted"))

        // Create a new instance with the same underlying storage
        let newInstance = AuthTokenStorage(fakeStorage)
        XCTAssertTrue(newInstance.checkToken())
        XCTAssertEqual(newInstance.getToken(), "persisted")
    }

    func testOverwriteTokenReplacesOldValue() {
        sut.setToken(Token(token: "old"))
        sut.setToken(Token(token: "new"))
        XCTAssertEqual(sut.getToken(), "new")
    }

    func testOverwrittenTokenPersistsCorrectly() {
        sut.setToken(Token(token: "old"))
        sut.setToken(Token(token: "new"))

        let newInstance = AuthTokenStorage(fakeStorage)
        XCTAssertEqual(newInstance.getToken(), "new")
    }
}

// MARK: - Fake

private final class FakeUnderlyingStorage: UnderlyingStorage {

    private var objects: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? {
        objects[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        guard let value = value else { return }
        objects[defaultName] = value
    }
}
