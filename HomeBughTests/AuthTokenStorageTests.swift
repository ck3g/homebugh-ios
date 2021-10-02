import XCTest
@testable import HomeBugh

final class AuthTokenStorageTests: XCTestCase {
    func testCheckTokenWhenNotSet() {
        let storage = AuthTokenStorage(MockUnderlyingStorage())

        XCTAssertFalse(storage.checkToken())
    }

    func testCheckTokenWhenSet() {
        let storage = AuthTokenStorage(MockUnderlyingStorage())

        storage.setToken(.init(token: "token"))

        XCTAssertTrue(storage.checkToken())
    }
}

private final class MockUnderlyingStorage: UnderlyingStorage {
    init() {}

    private var objects: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? {
        return objects[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        guard let value = value else {
            return
        }
        objects[defaultName] = value
    }
}
