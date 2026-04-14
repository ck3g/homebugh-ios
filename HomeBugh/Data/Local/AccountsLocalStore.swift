//
//  AccountsLocalStore.swift
//  HomeBugh
//
//  Local data access for accounts using GRDB.
//

import Foundation
import GRDB

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
            return records.map { $0.toDomainModel() }
        }
    }

    func create(_ account: Account) throws {
        var record = AccountRecord(from: account)
        record.isDirty = true
        try dbQueue.write { db in
            try record.insert(db)
        }
    }

    func update(_ account: Account) throws {
        var record = AccountRecord(from: account)
        record.updatedAt = Date()
        record.isDirty = true
        try dbQueue.write { db in
            try record.update(db)
        }
    }

    func delete(id: UUID) throws {
        try dbQueue.write { db in
            if var record = try AccountRecord.fetchOne(db, key: id.uuidString) {
                record.deletedAt = Date()
                record.isDirty = true
                try record.update(db)
            }
        }
    }

    func fetchAll() throws -> [Account] {
        try dbQueue.read { db in
            let records = try AccountRecord
                .filter(Column("deletedAt") == nil)
                .order(Column("name"))
                .fetchAll(db)
            return records.map { $0.toDomainModel() }
        }
    }
}
