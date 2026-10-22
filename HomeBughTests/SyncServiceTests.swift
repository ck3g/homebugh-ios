//
//  SyncServiceTests.swift
//  HomeBughTests
//
//  End-to-end tests for SyncService: currency refresh, push, then pull,
//  using in-memory GRDB and fakes.
//

import XCTest
@testable import HomeBugh

final class SyncServiceTests: XCTestCase {

    private var database: AppDatabase!
    private var accountsStore: AccountsLocalStore!
    private var categoriesStore: CategoriesLocalStore!
    private var transactionsStore: TransactionsLocalStore!
    private var currenciesStore: CurrenciesLocalStore!
    private var metadataStore: SyncMetadataStore!
    private var transport: FakeSyncTransport!
    private var currenciesService: FakeCurrenciesService!
    private var sut: SyncService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        accountsStore = AccountsLocalStore(dbQueue: database.dbQueue)
        categoriesStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        transactionsStore = TransactionsLocalStore(dbQueue: database.dbQueue)
        currenciesStore = CurrenciesLocalStore(dbQueue: database.dbQueue)
        metadataStore = SyncMetadataStore(dbQueue: database.dbQueue)
        transport = FakeSyncTransport()
        currenciesService = FakeCurrenciesService()

        let pushService = SyncPushService(
            accountsStore: accountsStore, categoriesStore: categoriesStore,
            transactionsStore: transactionsStore, transport: transport
        )
        let pullService = SyncPullService(
            accountsStore: accountsStore, categoriesStore: categoriesStore,
            transactionsStore: transactionsStore, currenciesStore: currenciesStore,
            metadataStore: metadataStore, transport: transport
        )
        sut = SyncService(
            pushService: pushService, pullService: pullService,
            currenciesService: currenciesService, currenciesStore: currenciesStore,
            metadataStore: metadataStore, token: "token"
        )
    }

    override func tearDown() {
        sut = nil
        currenciesService = nil
        transport = nil
        metadataStore = nil
        currenciesStore = nil
        transactionsStore = nil
        categoriesStore = nil
        accountsStore = nil
        database = nil
        super.tearDown()
    }

    func test_sync_refreshesCurrencies() async throws {
        currenciesService.currencies = [Currency(id: 1, name: "Euro", unit: "€")]
        transport.responses = [SyncResponseDTO(pushed: nil, pull: emptyPull())]

        _ = try await sut.sync()

        XCTAssertEqual(try currenciesStore.currency(id: 1)?.unit, "€")
    }

    func test_sync_pushesThenPulls() async throws {
        // One dirty category to push, and a server category to pull.
        try categoriesStore.create(TestFactory.makeCategory(name: "Local"))
        transport.responses = [
            // Push phase 1 (categories/accounts) response:
            SyncResponseDTO(pushed: nil, pull: nil),
            // Pull phase response:
            SyncResponseDTO(pushed: nil, pull: PullDTO(
                categories: [PulledCategoryDTO(
                    id: 50, name: "FromServer", categoryTypeId: 2, inactive: false,
                    status: "active", clientUuid: nil,
                    createdAt: Date(timeIntervalSince1970: 100), updatedAt: Date(timeIntervalSince1970: 100)
                )],
                accounts: nil, transactions: nil, deletions: nil, hasMore: false, cursor: Date()
            )),
        ]

        _ = try await sut.sync()

        let names = try categoriesStore.fetchAll().map(\.name).sorted()
        XCTAssertEqual(names, ["FromServer", "Local"], "Both local (pushed) and server (pulled) categories present")
    }

    func test_sync_returnsRejections() async throws {
        let category = TestFactory.makeCategory(name: "Dup")
        try categoriesStore.create(category)
        transport.responses = [
            SyncResponseDTO(pushed: PushedDTO(
                categories: PushedResourceDTO(
                    created: nil, updated: nil, deleted: nil,
                    rejected: [PushedRejectedDTO(clientUuid: category.clientUuid.uuidString, id: nil,
                                                 operation: "create", reason: "Name taken")]
                ),
                accounts: nil, transactions: nil
            ), pull: nil),
            SyncResponseDTO(pushed: nil, pull: emptyPull()),
        ]

        let result = try await sut.sync()

        XCTAssertTrue(result.hasRejections)
        XCTAssertEqual(result.rejections.first?.reason, "Name taken")
    }

    func test_sync_currencyFailureDoesNotBlockSync() async throws {
        currenciesService.error = APIError.transport
        transport.responses = [SyncResponseDTO(pushed: nil, pull: emptyPull())]

        // Should not throw even though currency fetch fails.
        _ = try await sut.sync()
    }

    private func emptyPull() -> PullDTO {
        PullDTO(categories: nil, accounts: nil, transactions: nil, deletions: nil, hasMore: false, cursor: Date())
    }
}

// MARK: - Fake currencies service

final class FakeCurrenciesService: CurrenciesServicing {
    var currencies: [Currency] = []
    var error: Error?

    func fetchCurrencies(token: String) async throws -> [Currency] {
        if let error { throw error }
        return currencies
    }
}
