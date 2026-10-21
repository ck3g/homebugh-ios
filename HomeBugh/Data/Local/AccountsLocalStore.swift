//
//  AccountsLocalStore.swift
//  HomeBugh
//
//  Local data access for accounts using GRDB.
//

import Foundation
import GRDB

enum AccountDeleteError: LocalizedError, Equatable {
    case hasBalance

    var errorDescription: String? {
        switch self {
        case .hasBalance:
            return "Cannot delete account with a non-zero balance."
        }
    }
}

struct AccountsLocalStore {

    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func list(page: Int, pageSize: Int) throws -> [Account] {
        try dbQueue.read { db in
            let records = try AccountRecord
                .filter(Column("deletedAt") == nil)
                .order(Column("name"))
                .limit(pageSize, offset: (page - 1) * pageSize)
                .fetchAll(db)
            return records.map { AccountMapper.toDomainModel($0) }
        }
    }

    func create(_ account: Account) throws {
        var record = AccountMapper.toRecord(account)
        record.isDirty = true
        try dbQueue.write { db in
            try record.insert(db)
        }
    }

    func update(_ account: Account) throws {
        var record = AccountMapper.toRecord(account)
        record.updatedAt = Date()
        record.isDirty = true
        try dbQueue.write { db in
            try record.update(db)
        }
    }

    /// Returns all non-deleted accounts without pagination.
    func fetchAll() throws -> [Account] {
        try dbQueue.read { db in
            let records = try AccountRecord
                .filter(Column("deletedAt") == nil)
                .order(Column("name"))
                .fetchAll(db)
            return records.map { AccountMapper.toDomainModel($0) }
        }
    }

    /// Soft-delete: sets deletedAt. Fails if the account has a non-zero balance.
    func delete(id: UUID) throws {
        try dbQueue.write { db in
            if var record = try AccountRecord.fetchOne(db, key: id.uuidString) {
                if record.balance != 0 {
                    throw AccountDeleteError.hasBalance
                }
                record.deletedAt = Date()
                record.isDirty = true
                try record.update(db)
            }
        }
    }

    // MARK: - Sync support

    /// Returns all records with pending local changes (including soft-deleted ones).
    func dirtyRecords() throws -> [AccountRecord] {
        try dbQueue.read { db in
            try AccountRecord.filter(Column("isDirty") == true).fetchAll(db)
        }
    }

    /// Marks a record as synced: stores the server id and clears the dirty flag.
    func markSynced(id: String, remoteId: Int) throws {
        try dbQueue.write { db in
            if var record = try AccountRecord.fetchOne(db, key: id) {
                record.remoteId = remoteId
                record.isDirty = false
                try record.update(db)
            }
        }
    }

    /// Clears the dirty flag without changing the remote id (for updates).
    func clearDirty(id: String) throws {
        try dbQueue.write { db in
            if var record = try AccountRecord.fetchOne(db, key: id) {
                record.isDirty = false
                try record.update(db)
            }
        }
    }

    /// Permanently removes a record (after a confirmed server delete).
    func hardDelete(id: String) throws {
        try dbQueue.write { db in
            _ = try AccountRecord.deleteOne(db, key: id)
        }
    }

    /// Inserts or updates a record pulled from the server, keyed by remoteId.
    /// Last-write-wins: skips the update if the local copy is newer.
    func upsertFromServer(_ record: AccountRecord) throws {
        try dbQueue.write { db in
            if let existing = try AccountRecord
                .filter(Column("remoteId") == record.remoteId)
                .fetchOne(db) {
                guard record.updatedAt >= existing.updatedAt else { return }
                var merged = record
                merged.id = existing.id // preserve local primary key
                try merged.update(db)
            } else {
                try record.insert(db)
            }
        }
    }

    /// Removes a record identified by its server id (from a pull deletion).
    func hardDeleteByRemoteId(_ remoteId: Int) throws {
        try dbQueue.write { db in
            _ = try AccountRecord.filter(Column("remoteId") == remoteId).deleteAll(db)
        }
    }
}
