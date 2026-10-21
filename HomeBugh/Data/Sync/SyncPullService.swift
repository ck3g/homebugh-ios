//
//  SyncPullService.swift
//  HomeBugh
//
//  Pulls server changes, upserts them locally (last-write-wins), processes
//  deletions, and pages through results until the server reports no more.
//

import Foundation

final class SyncPullService {

    private enum ResourceType {
        static let category = "Category"
        static let account = "Account"
        static let transaction = "Transaction"
    }

    private let accountsStore: AccountsLocalStore
    private let categoriesStore: CategoriesLocalStore
    private let transactionsStore: TransactionsLocalStore
    private let currenciesStore: CurrenciesLocalStore
    private let metadataStore: SyncMetadataStore
    private let transport: SyncTransport

    init(
        accountsStore: AccountsLocalStore,
        categoriesStore: CategoriesLocalStore,
        transactionsStore: TransactionsLocalStore,
        currenciesStore: CurrenciesLocalStore,
        metadataStore: SyncMetadataStore,
        transport: SyncTransport
    ) {
        self.accountsStore = accountsStore
        self.categoriesStore = categoriesStore
        self.transactionsStore = transactionsStore
        self.currenciesStore = currenciesStore
        self.metadataStore = metadataStore
        self.transport = transport
    }

    /// Pulls all server changes since `lastSyncedAt`, paging via the cursor.
    /// Persists the final cursor as the new last-synced timestamp.
    func pull(lastSyncedAt: Date?) async throws {
        var cursor = lastSyncedAt
        var latestTimestamp = lastSyncedAt

        while true {
            let request = SyncRequestDTO(lastSyncedAt: cursor, changes: nil)
            let response = try await transport.sync(request)

            guard let pull = response.pull else { break }

            try apply(pull)

            if let responseCursor = pull.cursor {
                latestTimestamp = responseCursor
            }

            if pull.hasMore, let nextCursor = pull.cursor {
                cursor = nextCursor
            } else {
                break
            }
        }

        try metadataStore.setLastSyncedAt(latestTimestamp ?? Date())
    }

    // MARK: - Apply a single pull page

    private func apply(_ pull: PullDTO) throws {
        // Dependency order: categories + accounts first, then transactions.
        for dto in pull.categories ?? [] {
            try categoriesStore.upsertFromServer(categoryRecord(from: dto))
        }
        for dto in pull.accounts ?? [] {
            let currency = try currenciesStore.currency(id: dto.currencyId)
            try accountsStore.upsertFromServer(accountRecord(from: dto, currency: currency))
        }
        for dto in pull.transactions ?? [] {
            if let record = try transactionRecord(from: dto) {
                try transactionsStore.upsertFromServer(record)
            }
        }
        for deletion in pull.deletions ?? [] {
            try applyDeletion(deletion)
        }
    }

    private func applyDeletion(_ deletion: PulledDeletionDTO) throws {
        switch deletion.resourceType {
        case ResourceType.category:
            try categoriesStore.hardDeleteByRemoteId(deletion.resourceId)
        case ResourceType.account:
            try accountsStore.hardDeleteByRemoteId(deletion.resourceId)
        case ResourceType.transaction:
            try transactionsStore.hardDeleteByRemoteId(deletion.resourceId)
        default:
            break
        }
    }

    // MARK: - DTO -> Record mapping

    private func categoryRecord(from dto: PulledCategoryDTO) -> CategoryRecord {
        CategoryRecord(
            id: UUID().uuidString,
            remoteId: dto.id,
            clientUuid: dto.clientUuid ?? UUID().uuidString,
            remoteServerId: nil,
            name: dto.name,
            categoryTypeId: dto.categoryTypeId,
            inactive: dto.inactive,
            status: dto.status,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: nil,
            isDirty: false
        )
    }

    private func accountRecord(from dto: PulledAccountDTO, currency: Currency?) -> AccountRecord {
        AccountRecord(
            id: UUID().uuidString,
            remoteId: dto.id,
            clientUuid: dto.clientUuid ?? UUID().uuidString,
            remoteServerId: nil,
            name: dto.name,
            balance: dto.balance, // server is authoritative for balance
            currencyId: dto.currencyId,
            currencyName: currency?.name ?? "",
            currencyUnit: currency?.unit ?? "",
            status: dto.status,
            showInSummary: dto.showInSummary,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: nil,
            isDirty: false
        )
    }

    /// Builds a transaction record, translating server FK ids to local UUIDs.
    /// Returns nil if the referenced account or category is not yet local.
    private func transactionRecord(from dto: PulledTransactionDTO) throws -> TransactionRecord? {
        guard let accountLocalId = try localAccountId(forRemoteId: dto.accountId),
              let categoryLocalId = try localCategoryId(forRemoteId: dto.categoryId) else {
            return nil
        }
        return TransactionRecord(
            id: UUID().uuidString,
            remoteId: dto.id,
            clientUuid: dto.clientUuid ?? UUID().uuidString,
            remoteServerId: nil,
            amount: dto.amount,
            comment: dto.comment,
            categoryId: categoryLocalId,
            accountId: accountLocalId,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: nil,
            isDirty: false
        )
    }

    // MARK: - Server id -> local id lookups

    private func localAccountId(forRemoteId remoteId: Int) throws -> String? {
        try accountsStore.fetchAll()
            .first { $0.remoteId == remoteId }?
            .id.uuidString
    }

    private func localCategoryId(forRemoteId remoteId: Int) throws -> String? {
        try categoriesStore.fetchAll()
            .first { $0.remoteId == remoteId }?
            .id.uuidString
    }
}
