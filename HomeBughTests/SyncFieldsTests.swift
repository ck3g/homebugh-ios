//
//  SyncFieldsTests.swift
//  HomeBughTests
//
//  Tests that sync fields (clientUuid, remoteServerId) survive mapping and
//  persistence, and that SyncMetadataStore round-trips lastSyncedAt.
//

import XCTest
@testable import HomeBugh

final class SyncFieldsTests: XCTestCase {

    private var database: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
    }

    override func tearDown() {
        database = nil
        super.tearDown()
    }

    // MARK: - Model defaults

    func testNewModelsGenerateClientUuid() {
        let account = TestFactory.makeAccount()
        let category = TestFactory.makeCategory()
        let transaction = TestFactory.makeTransaction()

        XCTAssertNotNil(account.clientUuid)
        XCTAssertNotNil(category.clientUuid)
        XCTAssertNotNil(transaction.clientUuid)
        XCTAssertNil(account.remoteServerId)
        XCTAssertNil(category.remoteServerId)
        XCTAssertNil(transaction.remoteServerId)
    }

    // MARK: - Mapper round-trips

    func testAccountMapperPreservesSyncFields() {
        let clientUuid = UUID()
        let account = Account(
            clientUuid: clientUuid,
            remoteServerId: "homebugh.info",
            name: "Cash",
            balance: 10,
            currency: Currency(id: 1, name: "EUR", unit: "EUR"),
            status: AccountStatus.active,
            showInSummary: true
        )

        let roundTripped = AccountMapper.toDomainModel(AccountMapper.toRecord(account))

        XCTAssertEqual(roundTripped.clientUuid, clientUuid)
        XCTAssertEqual(roundTripped.remoteServerId, "homebugh.info")
    }

    func testCategoryMapperPreservesSyncFields() {
        let clientUuid = UUID()
        let category = Category(
            clientUuid: clientUuid,
            remoteServerId: "homebugh.info",
            name: "Food",
            categoryType: .expense,
            inactive: false
        )

        let roundTripped = CategoryMapper.toDomainModel(CategoryMapper.toRecord(category))

        XCTAssertEqual(roundTripped.clientUuid, clientUuid)
        XCTAssertEqual(roundTripped.remoteServerId, "homebugh.info")
    }

    func testTransactionMapperPreservesSyncFields() {
        let clientUuid = UUID()
        let category = TestFactory.makeCategory()
        let account = TestFactory.makeAccount()
        let transaction = Transaction(
            clientUuid: clientUuid,
            remoteServerId: "homebugh.info",
            amount: 10,
            comment: "",
            category: category,
            account: account
        )

        let record = TransactionMapper.toRecord(transaction)
        let roundTripped = TransactionMapper.toDomainModel(record, category: category, account: account)

        XCTAssertEqual(roundTripped.clientUuid, clientUuid)
        XCTAssertEqual(roundTripped.remoteServerId, "homebugh.info")
    }

    // MARK: - Persistence preserves clientUuid

    func testAccountStorePreservesClientUuid() throws {
        let store = AccountsLocalStore(dbQueue: database.dbQueue)
        let clientUuid = UUID()
        let account = Account(
            clientUuid: clientUuid,
            name: "Cash",
            balance: 0,
            currency: Currency(id: 1, name: "EUR", unit: "EUR"),
            status: AccountStatus.active,
            showInSummary: true
        )
        try store.create(account)

        let stored = try store.list(page: 1, pageSize: 10).first
        XCTAssertEqual(stored?.clientUuid, clientUuid)
    }

    // MARK: - SyncMetadataStore

    func testSyncMetadataDefaultsToNil() throws {
        let store = SyncMetadataStore(dbQueue: database.dbQueue)
        XCTAssertNil(try store.lastSyncedAt())
    }

    func testSyncMetadataRoundTrips() throws {
        let store = SyncMetadataStore(dbQueue: database.dbQueue)
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        try store.setLastSyncedAt(date)

        XCTAssertEqual(try store.lastSyncedAt()?.timeIntervalSince1970 ?? 0,
                       date.timeIntervalSince1970, accuracy: 0.001)
    }

    func testSyncMetadataOverwrites() throws {
        let store = SyncMetadataStore(dbQueue: database.dbQueue)
        try store.setLastSyncedAt(Date(timeIntervalSince1970: 1_000))
        try store.setLastSyncedAt(Date(timeIntervalSince1970: 2_000))

        XCTAssertEqual(try store.lastSyncedAt()?.timeIntervalSince1970 ?? 0, 2_000, accuracy: 0.001)
    }
}
