//
//  SyncPullServiceTests.swift
//  HomeBughTests
//
//  Tests for SyncPullService: upsert (last-write-wins), deletions, cursor
//  paging, balance overwrite, and FK mapping, using in-memory GRDB + fake transport.
//

import XCTest
@testable import HomeBugh

final class SyncPullServiceTests: XCTestCase {

    private var database: AppDatabase!
    private var accountsStore: AccountsLocalStore!
    private var categoriesStore: CategoriesLocalStore!
    private var transactionsStore: TransactionsLocalStore!
    private var currenciesStore: CurrenciesLocalStore!
    private var metadataStore: SyncMetadataStore!
    private var transport: FakeSyncTransport!
    private var sut: SyncPullService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        accountsStore = AccountsLocalStore(dbQueue: database.dbQueue)
        categoriesStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        transactionsStore = TransactionsLocalStore(dbQueue: database.dbQueue)
        currenciesStore = CurrenciesLocalStore(dbQueue: database.dbQueue)
        metadataStore = SyncMetadataStore(dbQueue: database.dbQueue)
        transport = FakeSyncTransport()
        sut = SyncPullService(
            accountsStore: accountsStore,
            categoriesStore: categoriesStore,
            transactionsStore: transactionsStore,
            currenciesStore: currenciesStore,
            metadataStore: metadataStore,
            transport: transport
        )
    }

    override func tearDown() {
        sut = nil
        transport = nil
        metadataStore = nil
        currenciesStore = nil
        transactionsStore = nil
        categoriesStore = nil
        accountsStore = nil
        database = nil
        super.tearDown()
    }

    // MARK: - Upsert new

    func test_pull_insertsNewCategory() async throws {
        transport.responses = [pullResponse(categories: [
            pulledCategory(id: 10, name: "Transport", updatedAt: date(100))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        let stored = try categoriesStore.fetchAll()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.name, "Transport")
        XCTAssertEqual(stored.first?.remoteId, 10)
        XCTAssertFalse(stored.first?.isDirty ?? true)
    }

    func test_pull_insertsNewAccountWithServerBalance() async throws {
        transport.responses = [pullResponse(accounts: [
            pulledAccount(id: 5, name: "Savings", balance: 1234.5, updatedAt: date(100))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        let stored = try accountsStore.fetchAll().first
        XCTAssertEqual(stored?.balance ?? 0, 1234.5, accuracy: 0.01)
        XCTAssertEqual(stored?.remoteId, 5)
    }

    func test_pull_resolvesCurrencyNameAndUnitFromCache() async throws {
        try currenciesStore.replaceAll([Currency(id: 1, name: "Euro", unit: "€")])
        transport.responses = [pullResponse(accounts: [
            pulledAccount(id: 5, name: "Cash", balance: 0, updatedAt: date(100))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        let stored = try accountsStore.fetchAll().first
        XCTAssertEqual(stored?.currency.name, "Euro")
        XCTAssertEqual(stored?.currency.unit, "€")
    }

    // MARK: - Last-write-wins

    func test_pull_updatesExistingWhenServerIsNewer() async throws {
        // Seed a synced account with an old timestamp.
        let id = UUID()
        var account = TestFactory.makeAccount(id: id, name: "Old", balance: 0)
        account.updatedAt = date(100)
        try accountsStore.create(account)
        try accountsStore.markSynced(id: id.uuidString, remoteId: 5)

        transport.responses = [pullResponse(accounts: [
            pulledAccount(id: 5, name: "New", balance: 10, updatedAt: date(200))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        let stored = try accountsStore.fetchAll().first { $0.remoteId == 5 }
        XCTAssertEqual(stored?.name, "New", "Server newer -> local updated")
    }

    func test_pull_skipsUpdateWhenLocalIsNewer() async throws {
        let id = UUID()
        var account = TestFactory.makeAccount(id: id, name: "LocalNewer", balance: 0)
        account.updatedAt = date(300)
        try accountsStore.create(account)
        try accountsStore.markSynced(id: id.uuidString, remoteId: 5)

        transport.responses = [pullResponse(accounts: [
            pulledAccount(id: 5, name: "ServerOlder", balance: 10, updatedAt: date(100))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        let stored = try accountsStore.fetchAll().first { $0.remoteId == 5 }
        XCTAssertEqual(stored?.name, "LocalNewer", "Local newer -> server update skipped")
    }

    // MARK: - Deletions

    func test_pull_appliesDeletion() async throws {
        let id = UUID()
        try accountsStore.create(TestFactory.makeAccount(id: id, name: "Gone", balance: 0))
        try accountsStore.markSynced(id: id.uuidString, remoteId: 9)

        transport.responses = [pullResponse(deletions: [
            PulledDeletionDTO(resourceType: "Account", resourceId: 9, deletedAt: date(100))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        XCTAssertTrue(try accountsStore.fetchAll().isEmpty, "Deleted account should be removed")
    }

    // MARK: - FK mapping

    func test_pull_mapsTransactionForeignKeysFromServerIds() async throws {
        // Seed local account + category already synced with server ids.
        let accountId = UUID()
        let categoryId = UUID()
        try accountsStore.create(TestFactory.makeAccount(id: accountId, name: "Cash", balance: 0))
        try accountsStore.markSynced(id: accountId.uuidString, remoteId: 100)
        try categoriesStore.create(TestFactory.makeCategory(id: categoryId, name: "Food"))
        try categoriesStore.markSynced(id: categoryId.uuidString, remoteId: 200)

        transport.responses = [pullResponse(transactions: [
            pulledTransaction(id: 1, amount: 10, accountId: 100, categoryId: 200, updatedAt: date(100))
        ])]

        try await sut.pull(lastSyncedAt: nil)

        let stored = try transactionsStore.list(page: 1, pageSize: 10).first
        XCTAssertEqual(stored?.remoteId, 1)
        XCTAssertEqual(stored?.account.id, accountId)
        XCTAssertEqual(stored?.category.id, categoryId)
    }

    // MARK: - Cursor paging

    func test_pull_pagesUntilHasMoreIsFalse() async throws {
        transport.responses = [
            pullResponse(categories: [pulledCategory(id: 1, name: "A", updatedAt: date(100))],
                         hasMore: true, cursor: date(100)),
            pullResponse(categories: [pulledCategory(id: 2, name: "B", updatedAt: date(200))],
                         hasMore: false, cursor: date(200)),
        ]

        try await sut.pull(lastSyncedAt: nil)

        XCTAssertEqual(transport.sentRequests.count, 2, "Should page twice")
        XCTAssertEqual(try categoriesStore.fetchAll().count, 2)
    }

    func test_pull_persistsLastSyncedAt() async throws {
        transport.responses = [pullResponse(categories: [], hasMore: false, cursor: date(500))]

        try await sut.pull(lastSyncedAt: nil)

        XCTAssertEqual(try metadataStore.lastSyncedAt()?.timeIntervalSince1970 ?? 0,
                       date(500).timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func date(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    private func pullResponse(
        categories: [PulledCategoryDTO]? = nil,
        accounts: [PulledAccountDTO]? = nil,
        transactions: [PulledTransactionDTO]? = nil,
        deletions: [PulledDeletionDTO]? = nil,
        hasMore: Bool = false,
        cursor: Date? = nil
    ) -> SyncResponseDTO {
        SyncResponseDTO(
            pushed: nil,
            pull: PullDTO(
                categories: categories, accounts: accounts, transactions: transactions,
                deletions: deletions, hasMore: hasMore, cursor: cursor
            )
        )
    }

    private func pulledCategory(id: Int, name: String, updatedAt: Date) -> PulledCategoryDTO {
        PulledCategoryDTO(id: id, name: name, categoryTypeId: 2, inactive: false,
                          status: "active", clientUuid: nil, createdAt: updatedAt, updatedAt: updatedAt)
    }

    private func pulledAccount(id: Int, name: String, balance: Double, updatedAt: Date) -> PulledAccountDTO {
        PulledAccountDTO(id: id, name: name, balance: balance, currencyId: 1, status: "active",
                         showInSummary: true, clientUuid: nil, createdAt: updatedAt, updatedAt: updatedAt)
    }

    private func pulledTransaction(id: Int, amount: Double, accountId: Int, categoryId: Int, updatedAt: Date) -> PulledTransactionDTO {
        PulledTransactionDTO(id: id, amount: amount, comment: "", accountId: accountId,
                             categoryId: categoryId, clientUuid: nil, createdAt: updatedAt, updatedAt: updatedAt)
    }
}
