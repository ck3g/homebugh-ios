//
//  HTTPClientTests.swift
//  HomeBughTests
//
//  Tests URLSessionHTTPClient decoding and HTTP status -> APIError mapping
//  using a stubbed URLProtocol.
//

import XCTest
@testable import HomeBugh

final class HTTPClientTests: XCTestCase {

    private var sut: URLSessionHTTPClient!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        sut = URLSessionHTTPClient(baseURL: URL(string: "https://example.com/api/v1")!, session: session)
    }

    override func tearDown() {
        StubURLProtocol.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Success

    func testDecodesSuccessResponse() async throws {
        StubURLProtocol.stub(statusCode: 200, json: #"{"token":"abc","user_id":7}"#)

        let response: LoginResponse = try await sut.send(
            method: .post, path: "token", body: EmptyBody(), token: nil
        )

        XCTAssertEqual(response.token, "abc")
        XCTAssertEqual(response.userId, 7)
    }

    func testSnakeCaseIsConverted() async throws {
        StubURLProtocol.stub(statusCode: 200, json: #"{"token":"t","user_id":42}"#)

        let response: LoginResponse = try await sut.send(
            method: .post, path: "token", body: EmptyBody(), token: nil
        )

        XCTAssertEqual(response.userId, 42, "user_id should map to userId")
    }

    func testSendsBearerToken() async throws {
        StubURLProtocol.stub(statusCode: 200, json: #"{"token":"t","user_id":1}"#)

        let _: LoginResponse = try await sut.send(
            method: .get, path: "accounts", body: EmptyBody(), token: "my-token"
        )

        XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization"),
                       "Bearer my-token")
    }

    // MARK: - Error mapping

    func testMaps401ToUnauthorized() async {
        StubURLProtocol.stub(statusCode: 401, json: #"{"error":"Unauthorized"}"#)
        await assertThrows(.unauthorized)
    }

    func testMaps403ToForbidden() async {
        StubURLProtocol.stub(statusCode: 403, json: "{}")
        await assertThrows(.forbidden)
    }

    func testMaps404ToNotFound() async {
        StubURLProtocol.stub(statusCode: 404, json: #"{"error":"Not found"}"#)
        await assertThrows(.notFound)
    }

    func testMaps422ToValidationWithDetails() async {
        StubURLProtocol.stub(
            statusCode: 422,
            json: #"{"error":"Validation failed","details":{"name":["has already been taken"]}}"#
        )
        do {
            let _: LoginResponse = try await sut.send(method: .post, path: "x", body: EmptyBody(), token: nil)
            XCTFail("Expected error")
        } catch let APIError.validation(message, details) {
            XCTAssertEqual(message, "Validation failed")
            XCTAssertEqual(details?["name"], ["has already been taken"])
        } catch {
            XCTFail("Expected .validation, got \(error)")
        }
    }

    func testMaps429ToRateLimited() async {
        StubURLProtocol.stub(statusCode: 429, json: #"{"error":"Rate limit exceeded"}"#)
        await assertThrows(.rateLimited)
    }

    func testMaps500ToServer() async {
        StubURLProtocol.stub(statusCode: 500, json: "{}")
        do {
            let _: LoginResponse = try await sut.send(method: .get, path: "x", body: EmptyBody(), token: nil)
            XCTFail("Expected error")
        } catch let APIError.server(code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Expected .server, got \(error)")
        }
    }

    func testMalformedJSONThrowsDecoding() async {
        StubURLProtocol.stub(statusCode: 200, json: "not json")
        await assertThrows(.decoding)
    }

    // MARK: - Helpers

    private func assertThrows(_ expected: APIError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            let _: LoginResponse = try await sut.send(method: .get, path: "x", body: EmptyBody(), token: nil)
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch let error as APIError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected APIError, got \(error)", file: file, line: line)
        }
    }
}

/// Minimal response type used by the tests (mirrors the login response shape).
private struct LoginResponse: Decodable {
    let token: String
    let userId: Int
}

// MARK: - Stub URLProtocol

final class StubURLProtocol: URLProtocol {

    private static var stubbedStatusCode = 200
    private static var stubbedData = Data()
    private(set) static var lastRequest: URLRequest?

    static func stub(statusCode: Int, json: String) {
        stubbedStatusCode = statusCode
        stubbedData = Data(json.utf8)
    }

    static func reset() {
        stubbedStatusCode = 200
        stubbedData = Data()
        lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.stubbedStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.stubbedData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
