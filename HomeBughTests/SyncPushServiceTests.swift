//
//  SyncPushServiceTests.swift
//  HomeBughTests
//
//  Tests for SyncPushService: change collection, FK translation, result
//  application, and rejection handling, using in-memory GRDB and a fake transport.
//

import XCTest
@testable import HomeBugh

final class SyncPushServiceTests: XCTestCase {

    private var database: AppDatabase!
    private var accountsStore: AccountsLocalStore!
    private var categoriesStore: CategoriesLocalStore!
    private var transactionsStore: TransactionsLocalStore!
    private var transport: FakeSyncTransport!
    private var sut: SyncPushService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try AppDatabase.makeEmpty()
        accountsStore = AccountsLocalStore(dbQueue: database.dbQueue)
        categoriesStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        transactionsStore = TransactionsLocalStore(dbQueue: database.dbQueue)
        transport = FakeSyncTransport()
        sut = SyncPushService(
            accountsStore: accountsStore,
            categoriesStore: categoriesStore,
            transactionsStore: transactionsStore,
            transport: transport
        )
    }

    override func tearDown() {
        sut = nil
        transport = nil
        transactionsStore = nil
        categoriesStore = nil
        accountsStore = nil
        database = nil
        super.tearDown()
    }

    // MARK: - Change collection

    func test_push_sendsCreatedCategoryWithClientUuid() async throws {
        let category = TestFactory.makeCategory(name: "Gym")
        try categoriesStore.create(category)
        transport.responses = [SyncResponseDTO(pushed: nil, pull: nil)]

        try await sut.push(lastSyncedAt: nil)

        let created = transport.sentRequests.first?.changes?.categories?.created
        XCTAssertEqual(created?.count, 1)
        XCTAssertEqual(created?.first?.name, "Gym")
        XCTAssertEqual(created?.first?.clientUuid, category.clientUuid.uuidString)
    }

    func test_push_sendsUpdatedAccountWithRemoteId() async throws {
        // Seed a synced account, then dirty it with an update.
        let id = UUID()
        try accountsStore.create(TestFactory.makeAccount(id: id, name: "Old", balance: 0))
        try accountsStore.markSynced(id: id.uuidString, remoteId: 55)
        var updated = TestFactory.makeAccount(id: id, name: "New", balance: 0)
        updated.remoteId = 55
        try accountsStore.update(updated)
        transport.responses = [SyncResponseDTO(pushed: nil, pull: nil)]

        try await sut.push(lastSyncedAt: nil)

        let update = transport.sentRequests.first?.changes?.accounts?.updated.first
        XCTAssertEqual(update?.id, 55)
        XCTAssertEqual(update?.name, "New")
    }

    func test_push_sendsDeletedWithRemoteId() async throws {
        let id = UUID()
        try accountsStore.create(TestFactory.makeAccount(id: id, name: "Gone", balance: 0))
        try accountsStore.markSynced(id: id.uuidString, remoteId: 77)
        try accountsStore.delete(id: id)
        transport.responses = [SyncResponseDTO(pushed: nil, pull: nil)]

        try await sut.push(lastSyncedAt: nil)

        let deleted = transport.sentRequests.first?.changes?.accounts?.deleted
        XCTAssertEqual(deleted?.first?.id, 77)
    }

    // MARK: - FK translation (two-phase)

    func test_push_translatesTransactionForeignKeysToServerIds() async throws {
        let account = TestFactory.makeAccount(name: "Cash", balance: 0)
        let category = TestFactory.makeCategory(name: "Food")
        try accountsStore.create(account)
        try categoriesStore.create(category)
        try transactionsStore.create(TestFactory.makeTransaction(amount: 10, category: category, account: account))

        // Phase 1 returns server ids for the parents; phase 2 has no pushed section.
        transport.responses = [
            SyncResponseDTO(
                pushed: PushedDTO(
                    categories: PushedResourceDTO(
                        created: [PushedCreatedDTO(clientUuid: category.clientUuid.uuidString, serverId: 200, status: "ok")],
                        updated: nil, deleted: nil, rejected: nil
                    ),
                    accounts: PushedResourceDTO(
                        created: [PushedCreatedDTO(clientUuid: account.clientUuid.uuidString, serverId: 100, status: "ok")],
                        updated: nil, deleted: nil, rejected: nil
                    ),
                    transactions: nil
                ),
                pull: nil
            ),
            SyncResponseDTO(pushed: nil, pull: nil),
        ]

        try await sut.push(lastSyncedAt: nil)

        XCTAssertEqual(transport.sentRequests.count, 2, "Two phases: parents then children")
        let txCreate = transport.sentRequests.last?.changes?.transactions?.created.first
        XCTAssertEqual(txCreate?.accountId, 100, "account FK translated to server id")
        XCTAssertEqual(txCreate?.categoryId, 200, "category FK translated to server id")
    }

    // MARK: - Result application

    func test_push_storesServerIdAndClearsDirtyOnCreate() async throws {
        let account = TestFactory.makeAccount(name: "Cash", balance: 0)
        try accountsStore.create(account)
        transport.responses = [
            SyncResponseDTO(
                pushed: PushedDTO(
                    categories: nil,
                    accounts: PushedResourceDTO(
                        created: [PushedCreatedDTO(clientUuid: account.clientUuid.uuidString, serverId: 999, status: "ok")],
                        updated: nil, deleted: nil, rejected: nil
                    ),
                    transactions: nil
                ),
                pull: nil
            ),
        ]

        try await sut.push(lastSyncedAt: nil)

        let stored = try accountsStore.list(page: 1, pageSize: 10).first
        XCTAssertEqual(stored?.remoteId, 999)
        XCTAssertFalse(stored?.isDirty ?? true, "isDirty should be cleared after sync")
    }

    func test_push_hardDeletesOnConfirmedDelete() async throws {
        let id = UUID()
        try accountsStore.create(TestFactory.makeAccount(id: id, name: "Gone", balance: 0))
        try accountsStore.markSynced(id: id.uuidString, remoteId: 42)
        try accountsStore.delete(id: id)
        transport.responses = [
            SyncResponseDTO(
                pushed: PushedDTO(
                    categories: nil,
                    accounts: PushedResourceDTO(
                        created: nil, updated: nil,
                        deleted: [PushedDeletedDTO(id: 42, status: "ok")], rejected: nil
                    ),
                    transactions: nil
                ),
                pull: nil
            ),
        ]

        try await sut.push(lastSyncedAt: nil)

        let remaining = try accountsStore.dirtyRecords()
        XCTAssertTrue(remaining.isEmpty, "Record should be hard-deleted after confirmed delete")
    }

    // MARK: - Rejection handling

    func test_push_returnsRejections() async throws {
        let category = TestFactory.makeCategory(name: "Dup")
        try categoriesStore.create(category)
        transport.responses = [
            SyncResponseDTO(
                pushed: PushedDTO(
                    categories: PushedResourceDTO(
                        created: nil, updated: nil, deleted: nil,
                        rejected: [PushedRejectedDTO(
                            clientUuid: category.clientUuid.uuidString, id: nil,
                            operation: "create", reason: "Name has already been taken"
                        )]
                    ),
                    accounts: nil, transactions: nil
                ),
                pull: nil
            ),
        ]

        let rejections = try await sut.push(lastSyncedAt: nil)

        XCTAssertEqual(rejections.count, 1)
        XCTAssertEqual(rejections.first?.reason, "Name has already been taken")
    }

    // MARK: - No-op

    func test_push_withNoDirtyRecords_sendsNothing() async throws {
        try await sut.push(lastSyncedAt: nil)
        XCTAssertTrue(transport.sentRequests.isEmpty)
    }
}

// MARK: - Fake transport

final class FakeSyncTransport: SyncTransport {
    var responses: [SyncResponseDTO] = []
    private(set) var sentRequests: [SyncRequestDTO] = []
    private var index = 0

    func sync(_ request: SyncRequestDTO) async throws -> SyncResponseDTO {
        sentRequests.append(request)
        defer { index += 1 }
        guard index < responses.count else {
            return SyncResponseDTO(pushed: nil, pull: nil)
        }
        return responses[index]
    }
}
