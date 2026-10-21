//
//  SyncPushService.swift
//  HomeBugh
//
//  Pushes local changes to the server in two phases (parents then children),
//  translating local foreign keys to server ids and applying the results.
//

import Foundation

/// Sends a sync request and returns the decoded response.
protocol SyncTransport {
    func sync(_ request: SyncRequestDTO) async throws -> SyncResponseDTO
}

final class SyncPushService {

    private enum Constants {
        static let deletedCategoryStatus = CategoryStatus.deleted.rawValue
    }

    private let accountsStore: AccountsLocalStore
    private let categoriesStore: CategoriesLocalStore
    private let transactionsStore: TransactionsLocalStore
    private let transport: SyncTransport

    init(
        accountsStore: AccountsLocalStore,
        categoriesStore: CategoriesLocalStore,
        transactionsStore: TransactionsLocalStore,
        transport: SyncTransport
    ) {
        self.accountsStore = accountsStore
        self.categoriesStore = categoriesStore
        self.transactionsStore = transactionsStore
        self.transport = transport
    }

    /// Pushes all dirty records. Returns any rejections the server reported.
    @discardableResult
    func push(lastSyncedAt: Date?) async throws -> [PushedRejectedDTO] {
        var rejections: [PushedRejectedDTO] = []

        // Phase 1 — parents: categories + accounts.
        let categoryRecords = try categoriesStore.dirtyRecords()
        let accountRecords = try accountsStore.dirtyRecords()

        let parentChanges = SyncChangesDTO(
            categories: categoryChanges(categoryRecords),
            accounts: accountChanges(accountRecords),
            transactions: nil
        )

        if hasChanges(parentChanges) {
            let response = try await transport.sync(
                SyncRequestDTO(lastSyncedAt: lastSyncedAt, changes: parentChanges)
            )
            rejections += applyParentResults(response.pushed,
                                             categoryRecords: categoryRecords,
                                             accountRecords: accountRecords)
        }

        // Phase 2 — children: transactions (need server ids for their FKs).
        let transactionRecords = try transactionsStore.dirtyRecords()
        let accountRemoteIds = try currentAccountRemoteIds()
        let categoryRemoteIds = try currentCategoryRemoteIds()

        let childChanges = SyncChangesDTO(
            categories: nil,
            accounts: nil,
            transactions: transactionChanges(
                transactionRecords,
                accountRemoteIds: accountRemoteIds,
                categoryRemoteIds: categoryRemoteIds
            )
        )

        if hasChanges(childChanges) {
            let response = try await transport.sync(
                SyncRequestDTO(lastSyncedAt: lastSyncedAt, changes: childChanges)
            )
            rejections += applyTransactionResults(response.pushed, transactionRecords: transactionRecords)
        }

        return rejections
    }

    // MARK: - Change collection

    private func categoryChanges(_ records: [CategoryRecord]) -> ResourceChangesDTO<CategoryCreateDTO, CategoryUpdateDTO> {
        var created: [CategoryCreateDTO] = []
        var updated: [CategoryUpdateDTO] = []
        var deleted: [DeletedRefDTO] = []

        for record in records {
            let isDeleted = record.status == Constants.deletedCategoryStatus
            if isDeleted {
                if let remoteId = record.remoteId { deleted.append(DeletedRefDTO(id: remoteId)) }
            } else if let remoteId = record.remoteId {
                updated.append(CategoryUpdateDTO(
                    id: remoteId, name: record.name, inactive: record.inactive, updatedAt: record.updatedAt
                ))
            } else {
                created.append(CategoryCreateDTO(
                    clientUuid: record.clientUuid, name: record.name, categoryTypeId: record.categoryTypeId
                ))
            }
        }
        return ResourceChangesDTO(created: created, updated: updated, deleted: deleted)
    }

    private func accountChanges(_ records: [AccountRecord]) -> ResourceChangesDTO<AccountCreateDTO, AccountUpdateDTO> {
        var created: [AccountCreateDTO] = []
        var updated: [AccountUpdateDTO] = []
        var deleted: [DeletedRefDTO] = []

        for record in records {
            if record.deletedAt != nil {
                if let remoteId = record.remoteId { deleted.append(DeletedRefDTO(id: remoteId)) }
            } else if let remoteId = record.remoteId {
                updated.append(AccountUpdateDTO(
                    id: remoteId, name: record.name, showInSummary: record.showInSummary, updatedAt: record.updatedAt
                ))
            } else {
                created.append(AccountCreateDTO(
                    clientUuid: record.clientUuid, name: record.name,
                    currencyId: record.currencyId, showInSummary: record.showInSummary
                ))
            }
        }
        return ResourceChangesDTO(created: created, updated: updated, deleted: deleted)
    }

    private func transactionChanges(
        _ records: [TransactionRecord],
        accountRemoteIds: [String: Int],
        categoryRemoteIds: [String: Int]
    ) -> ResourceChangesDTO<TransactionCreateDTO, TransactionUpdateDTO> {
        var created: [TransactionCreateDTO] = []
        var updated: [TransactionUpdateDTO] = []
        var deleted: [DeletedRefDTO] = []

        for record in records {
            if record.deletedAt != nil {
                if let remoteId = record.remoteId { deleted.append(DeletedRefDTO(id: remoteId)) }
            } else if let remoteId = record.remoteId {
                updated.append(TransactionUpdateDTO(
                    id: remoteId, comment: record.comment, updatedAt: record.updatedAt
                ))
            } else if let accountServerId = accountRemoteIds[record.accountId],
                      let categoryServerId = categoryRemoteIds[record.categoryId] {
                // Only push if both parents are already on the server.
                created.append(TransactionCreateDTO(
                    clientUuid: record.clientUuid, amount: record.amount, comment: record.comment,
                    accountId: accountServerId, categoryId: categoryServerId
                ))
            }
        }
        return ResourceChangesDTO(created: created, updated: updated, deleted: deleted)
    }

    // MARK: - Result application

    private func applyParentResults(
        _ pushed: PushedDTO?,
        categoryRecords: [CategoryRecord],
        accountRecords: [AccountRecord]
    ) -> [PushedRejectedDTO] {
        var rejections: [PushedRejectedDTO] = []

        if let categories = pushed?.categories {
            applyResource(
                categories,
                recordsByClientUuid: Dictionary(categoryRecords.map { ($0.clientUuid, $0.id) }, uniquingKeysWith: { a, _ in a }),
                recordsByRemoteId: Dictionary(categoryRecords.compactMap { r in r.remoteId.map { ($0, r.id) } }, uniquingKeysWith: { a, _ in a }),
                markSynced: { try? self.categoriesStore.markSynced(id: $0, remoteId: $1) },
                clearDirty: { try? self.categoriesStore.clearDirty(id: $0) },
                hardDelete: { try? self.categoriesStore.hardDelete(id: $0) },
                into: &rejections
            )
        }
        if let accounts = pushed?.accounts {
            applyResource(
                accounts,
                recordsByClientUuid: Dictionary(accountRecords.map { ($0.clientUuid, $0.id) }, uniquingKeysWith: { a, _ in a }),
                recordsByRemoteId: Dictionary(accountRecords.compactMap { r in r.remoteId.map { ($0, r.id) } }, uniquingKeysWith: { a, _ in a }),
                markSynced: { try? self.accountsStore.markSynced(id: $0, remoteId: $1) },
                clearDirty: { try? self.accountsStore.clearDirty(id: $0) },
                hardDelete: { try? self.accountsStore.hardDelete(id: $0) },
                into: &rejections
            )
        }
        return rejections
    }

    private func applyTransactionResults(_ pushed: PushedDTO?, transactionRecords: [TransactionRecord]) -> [PushedRejectedDTO] {
        var rejections: [PushedRejectedDTO] = []
        if let transactions = pushed?.transactions {
            applyResource(
                transactions,
                recordsByClientUuid: Dictionary(transactionRecords.map { ($0.clientUuid, $0.id) }, uniquingKeysWith: { a, _ in a }),
                recordsByRemoteId: Dictionary(transactionRecords.compactMap { r in r.remoteId.map { ($0, r.id) } }, uniquingKeysWith: { a, _ in a }),
                markSynced: { try? self.transactionsStore.markSynced(id: $0, remoteId: $1) },
                clearDirty: { try? self.transactionsStore.clearDirty(id: $0) },
                hardDelete: { try? self.transactionsStore.hardDelete(id: $0) },
                into: &rejections
            )
        }
        return rejections
    }

    private func applyResource(
        _ pushed: PushedResourceDTO,
        recordsByClientUuid: [String: String],
        recordsByRemoteId: [Int: String],
        markSynced: (String, Int) -> Void,
        clearDirty: (String) -> Void,
        hardDelete: (String) -> Void,
        into rejections: inout [PushedRejectedDTO]
    ) {
        for created in pushed.created ?? [] where created.status == "ok" {
            if let localId = recordsByClientUuid[created.clientUuid] {
                markSynced(localId, created.serverId)
            }
        }
        for updated in pushed.updated ?? [] where updated.status == "ok" {
            if let localId = recordsByRemoteId[updated.id] {
                clearDirty(localId)
            }
        }
        for deleted in pushed.deleted ?? [] where deleted.status == "ok" {
            if let localId = recordsByRemoteId[deleted.id] {
                hardDelete(localId)
            }
        }
        rejections += pushed.rejected ?? []
    }

    // MARK: - Helpers

    private func currentAccountRemoteIds() throws -> [String: Int] {
        var map: [String: Int] = [:]
        for record in try accountsStore.dirtyRecords() {
            if let remoteId = record.remoteId { map[record.id] = remoteId }
        }
        // Also include non-dirty accounts that may be FK targets.
        for account in try accountsStore.fetchAll() {
            if let remoteId = account.remoteId { map[account.id.uuidString] = remoteId }
        }
        return map
    }

    private func currentCategoryRemoteIds() throws -> [String: Int] {
        var map: [String: Int] = [:]
        for category in try categoriesStore.fetchAll() {
            if let remoteId = category.remoteId { map[category.id.uuidString] = remoteId }
        }
        return map
    }

    private func hasChanges(_ changes: SyncChangesDTO) -> Bool {
        (changes.categories?.isEmpty == false) ||
        (changes.accounts?.isEmpty == false) ||
        (changes.transactions?.isEmpty == false)
    }
}
