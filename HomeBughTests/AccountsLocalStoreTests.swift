//
//  AccountsLocalStoreTests.swift
//  HomeBughTests
//
//  Integration tests for AccountsLocalStore using in-memory GRDB.
//

import XCTest
@testable import HomeBugh

final class AccountsLocalStoreTests: XCTestCase {

    private var database: AppDatabase!
    private var sut: AccountsLocalStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        sut = AccountsLocalStore(dbQueue: database.dbQueue)
    }

    override func tearDown() {
        sut = nil
        database = nil
        super.tearDown()
    }

    // MARK: - Create & List

    func testCreateAndListAccount() throws {
        let account = TestFactory.makeAccount(name: "Deutsche Bank", balance: 5000.0)
        try sut.create(account)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Deutsche Bank")
        XCTAssertEqual(result.first?.balance ?? 0, 5000.0, accuracy: 0.01)
    }

    func testCreateSetsIsDirtyFlag() throws {
        try sut.create(TestFactory.makeAccount())

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertTrue(result.first?.isDirty ?? false)
    }

    // MARK: - List Ordering

    func testListOrdersByName() throws {
        try sut.create(TestFactory.makeAccount(name: "Zebra Bank"))
        try sut.create(TestFactory.makeAccount(name: "Alpha Bank"))

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.map(\.name), ["Alpha Bank", "Zebra Bank"])
    }

    // MARK: - Pagination

    func testListPagination() throws {
        for i in 1...5 {
            try sut.create(TestFactory.makeAccount(name: "Account \(i)"))
        }

        let page1 = try sut.list(page: 1, pageSize: 2)
        let page2 = try sut.list(page: 2, pageSize: 2)
        let page3 = try sut.list(page: 3, pageSize: 2)

        XCTAssertEqual(page1.count, 2)
        XCTAssertEqual(page2.count, 2)
        XCTAssertEqual(page3.count, 1)
    }

    // MARK: - Update

    func testUpdateAccount() throws {
        let id = UUID()
        try sut.create(TestFactory.makeAccount(id: id, name: "Old Name", balance: 100.0))

        var updated = TestFactory.makeAccount(id: id, name: "New Name", balance: 200.0)
        updated.updatedAt = Date()
        try sut.update(updated)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.first?.name, "New Name")
        XCTAssertEqual(result.first?.balance ?? 0, 200.0, accuracy: 0.01)
        XCTAssertTrue(result.first?.isDirty ?? false)
    }

    // MARK: - Delete

    func testDeleteSoftDeletesAccount() throws {
        let id = UUID()
        try sut.create(TestFactory.makeAccount(id: id, name: "ToDelete"))

        try sut.delete(id: id)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertTrue(result.isEmpty, "Soft-deleted account should not appear in list")
    }

    func testDeleteDoesNotAffectOtherAccounts() throws {
        let deleteId = UUID()
        try sut.create(TestFactory.makeAccount(id: deleteId, name: "Delete Me"))
        try sut.create(TestFactory.makeAccount(name: "Keep Me"))

        try sut.delete(id: deleteId)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Keep Me")
    }

    // MARK: - Fetch All

    func testFetchAllExcludesDeleted() throws {
        try sut.create(TestFactory.makeAccount(name: "Active"))
        let deletedId = UUID()
        try sut.create(TestFactory.makeAccount(id: deletedId, name: "Deleted"))
        try sut.delete(id: deletedId)

        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Active")
    }
}
