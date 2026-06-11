//
//  TransactionsLocalStoreTests.swift
//  HomeBughTests
//
//  Integration tests for TransactionsLocalStore using in-memory GRDB.
//

import XCTest
@testable import HomeBugh

final class TransactionsLocalStoreTests: XCTestCase {

    private var database: AppDatabase!
    private var sut: TransactionsLocalStore!
    private var categoriesStore: CategoriesLocalStore!
    private var accountsStore: AccountsLocalStore!

    // Shared test fixtures
    private var testCategory: HomeBugh.Category!
    private var testAccount: Account!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        sut = TransactionsLocalStore(dbQueue: database.dbQueue)
        categoriesStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        accountsStore = AccountsLocalStore(dbQueue: database.dbQueue)

        // Transactions require a category and account to exist (foreign keys)
        testCategory = TestFactory.makeCategory(name: "Food")
        try categoriesStore.create(testCategory)

        testAccount = TestFactory.makeAccount(name: "Deutsche Bank")
        try accountsStore.create(testAccount)
    }

    override func tearDown() {
        sut = nil
        categoriesStore = nil
        accountsStore = nil
        database = nil
        testCategory = nil
        testAccount = nil
        super.tearDown()
    }

    // MARK: - Create & List

    func testCreateAndListTransaction() throws {
        let transaction = TestFactory.makeTransaction(
            amount: 42.50,
            comment: "Lunch",
            category: testCategory,
            account: testAccount
        )
        try sut.create(transaction)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.amount ?? 0, 42.50, accuracy: 0.01)
        XCTAssertEqual(result.first?.comment, "Lunch")
        XCTAssertEqual(result.first?.category.name, "Food")
        XCTAssertEqual(result.first?.account.name, "Deutsche Bank")
    }

    func testCreateSetsIsDirtyFlag() throws {
        let transaction = TestFactory.makeTransaction(
            category: testCategory,
            account: testAccount
        )
        try sut.create(transaction)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertTrue(result.first?.isDirty ?? false)
    }

    // MARK: - List Ordering

    func testListOrdersByCreatedAtDescending() throws {
        let older = TestFactory.makeTransaction(
            amount: 10.0,
            category: testCategory,
            account: testAccount,
            createdAt: Date(timeIntervalSinceNow: -3600)
        )
        let newer = TestFactory.makeTransaction(
            amount: 20.0,
            category: testCategory,
            account: testAccount,
            createdAt: Date()
        )
        try sut.create(older)
        try sut.create(newer)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.first?.amount ?? 0, 20.0, accuracy: 0.01)
        XCTAssertEqual(result.last?.amount ?? 0, 10.0, accuracy: 0.01)
    }

    // MARK: - Pagination

    func testListPagination() throws {
        for i in 1...5 {
            try sut.create(TestFactory.makeTransaction(
                amount: Double(i),
                category: testCategory,
                account: testAccount
            ))
        }

        let page1 = try sut.list(page: 1, pageSize: 2)
        let page2 = try sut.list(page: 2, pageSize: 2)
        let page3 = try sut.list(page: 3, pageSize: 2)

        XCTAssertEqual(page1.count, 2)
        XCTAssertEqual(page2.count, 2)
        XCTAssertEqual(page3.count, 1)
    }

    // MARK: - Update

    func testUpdateTransaction() throws {
        let id = UUID()
        let transaction = TestFactory.makeTransaction(
            id: id,
            amount: 10.0,
            comment: "Old",
            category: testCategory,
            account: testAccount
        )
        try sut.create(transaction)

        var updated = TestFactory.makeTransaction(
            id: id,
            amount: 99.0,
            comment: "New",
            category: testCategory,
            account: testAccount
        )
        updated.updatedAt = Date()
        try sut.update(updated)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.amount ?? 0, 99.0, accuracy: 0.01)
        XCTAssertEqual(result.first?.comment, "New")
        XCTAssertTrue(result.first?.isDirty ?? false)
    }

    // MARK: - Delete

    func testDeleteSoftDeletesTransaction() throws {
        let id = UUID()
        let transaction = TestFactory.makeTransaction(
            id: id,
            category: testCategory,
            account: testAccount
        )
        try sut.create(transaction)

        try sut.delete(id: id)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertTrue(result.isEmpty, "Soft-deleted transaction should not appear in list")
    }

    func testDeleteDoesNotAffectOtherTransactions() throws {
        let deleteId = UUID()
        try sut.create(TestFactory.makeTransaction(
            id: deleteId,
            amount: 10.0,
            category: testCategory,
            account: testAccount
        ))
        try sut.create(TestFactory.makeTransaction(
            amount: 20.0,
            category: testCategory,
            account: testAccount
        ))

        try sut.delete(id: deleteId)

        let result = try sut.list(page: 1, pageSize: 20)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.amount ?? 0, 20.0, accuracy: 0.01)
    }
}
