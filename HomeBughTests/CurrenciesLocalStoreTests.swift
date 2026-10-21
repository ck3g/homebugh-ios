//
//  CurrenciesLocalStoreTests.swift
//  HomeBughTests
//
//  Tests for the currencies cache store.
//

import XCTest
@testable import HomeBugh

final class CurrenciesLocalStoreTests: XCTestCase {

    private var database: AppDatabase!
    private var sut: CurrenciesLocalStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        sut = CurrenciesLocalStore(dbQueue: database.dbQueue)
    }

    override func tearDown() {
        sut = nil
        database = nil
        super.tearDown()
    }

    func test_replaceAll_thenLookupById() throws {
        try sut.replaceAll([
            Currency(id: 1, name: "US Dollar", unit: "$"),
            Currency(id: 2, name: "Euro", unit: "€"),
        ])

        XCTAssertEqual(try sut.currency(id: 2)?.name, "Euro")
        XCTAssertEqual(try sut.currency(id: 2)?.unit, "€")
        XCTAssertNil(try sut.currency(id: 99))
    }

    func test_replaceAll_overwritesPreviousSet() throws {
        try sut.replaceAll([Currency(id: 1, name: "US Dollar", unit: "$")])
        try sut.replaceAll([Currency(id: 2, name: "Euro", unit: "€")])

        XCTAssertNil(try sut.currency(id: 1), "Old currency should be gone")
        XCTAssertEqual(try sut.all().count, 1)
        XCTAssertEqual(try sut.all().first?.id, 2)
    }
}
