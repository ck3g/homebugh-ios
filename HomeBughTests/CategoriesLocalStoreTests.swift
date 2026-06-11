//
//  CategoriesLocalStoreTests.swift
//  HomeBughTests
//
//  Integration tests for CategoriesLocalStore using in-memory GRDB.
//

import XCTest
@testable import HomeBugh

final class CategoriesLocalStoreTests: XCTestCase {

    private var database: AppDatabase!
    private var sut: CategoriesLocalStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        sut = CategoriesLocalStore(dbQueue: database.dbQueue)
    }

    override func tearDown() {
        sut = nil
        database = nil
        super.tearDown()
    }

    // MARK: - Create & List

    func testCreateAndListCategory() throws {
        let category = TestFactory.makeCategory(name: "Food")
        try sut.create(category)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Food")
        XCTAssertEqual(result.first?.categoryType, .expense)
    }

    func testCreateSetsIsDirtyFlag() throws {
        let category = TestFactory.makeCategory(name: "Test")
        try sut.create(category)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertTrue(result.first?.isDirty ?? false)
    }

    // MARK: - List Ordering

    func testListOrdersByInactiveThenName() throws {
        try sut.create(TestFactory.makeCategory(name: "Zebra", inactive: false))
        try sut.create(TestFactory.makeCategory(name: "Alpha", inactive: false))
        try sut.create(TestFactory.makeCategory(name: "Inactive One", inactive: true))

        let result = try sut.list(page: 1, pageSize: 20)
        // Active first (sorted by name), then inactive
        XCTAssertEqual(result.map(\.name), ["Alpha", "Zebra", "Inactive One"])
    }

    // MARK: - List Active

    func testListActiveExcludesInactive() throws {
        try sut.create(TestFactory.makeCategory(name: "Active", inactive: false))
        try sut.create(TestFactory.makeCategory(name: "Inactive", inactive: true))

        let result = try sut.listActive(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Active")
    }

    // MARK: - Pagination

    func testListPagination() throws {
        for i in 1...5 {
            try sut.create(TestFactory.makeCategory(name: "Cat \(i)"))
        }

        let page1 = try sut.list(page: 1, pageSize: 2)
        let page2 = try sut.list(page: 2, pageSize: 2)
        let page3 = try sut.list(page: 3, pageSize: 2)

        XCTAssertEqual(page1.count, 2)
        XCTAssertEqual(page2.count, 2)
        XCTAssertEqual(page3.count, 1)
    }

    // MARK: - Update

    func testUpdateCategory() throws {
        let id = UUID()
        try sut.create(TestFactory.makeCategory(id: id, name: "Old"))

        var updated = TestFactory.makeCategory(id: id, name: "New")
        updated.updatedAt = Date()
        try sut.update(updated)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.first?.name, "New")
        XCTAssertTrue(result.first?.isDirty ?? false)
    }

    // MARK: - Delete

    func testDeleteSoftDeletesCategory() throws {
        let id = UUID()
        try sut.create(TestFactory.makeCategory(id: id, name: "ToDelete"))

        try sut.delete(id: id)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertTrue(result.isEmpty, "Soft-deleted category should not appear in list")
    }

    func testDeleteFailsWhenCategoryHasTransactions() throws {
        let categoryId = UUID()
        try sut.create(TestFactory.makeCategory(id: categoryId, name: "HasTransactions"))

        // Insert a transaction referencing this category
        let accountId = UUID()
        let accountStore = AccountsLocalStore(dbQueue: database.dbQueue)
        try accountStore.create(TestFactory.makeAccount(id: accountId))

        let transactionStore = TransactionsLocalStore(dbQueue: database.dbQueue)
        try transactionStore.create(TestFactory.makeTransaction(
            category: TestFactory.makeCategory(id: categoryId),
            account: TestFactory.makeAccount(id: accountId)
        ))

        XCTAssertThrowsError(try sut.delete(id: categoryId)) { error in
            XCTAssertTrue(error is CategoryDeleteError)
        }
    }

    // MARK: - Fetch All

    func testFetchAllExcludesDeleted() throws {
        try sut.create(TestFactory.makeCategory(name: "Active"))
        let deletedId = UUID()
        try sut.create(TestFactory.makeCategory(id: deletedId, name: "Deleted"))
        try sut.delete(id: deletedId)

        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Active")
    }
}
