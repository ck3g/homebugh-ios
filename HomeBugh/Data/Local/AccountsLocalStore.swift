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
}
