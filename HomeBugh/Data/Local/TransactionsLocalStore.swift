//
//  TransactionsLocalStore.swift
//  HomeBugh
//
//  Local data access for transactions using GRDB.
//

import Foundation
import GRDB

struct TransactionsLocalStore {

    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func list(page: Int, pageSize: Int) throws -> [Transaction] {
        try dbQueue.read { db in
            let records = try TransactionRecord
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .limit(pageSize, offset: (page - 1) * pageSize)
                .fetchAll(db)

            return try records.map { record in
                let category = try CategoryRecord.fetchOne(db, key: record.categoryId)
                    .map { CategoryMapper.toDomainModel($0) }
                let account = try AccountRecord.fetchOne(db, key: record.accountId)
                    .map { AccountMapper.toDomainModel($0) }

                guard let category = category, let account = account else {
                    throw DatabaseError(message: "Missing category or account for transaction \(record.id)")
                }

                return TransactionMapper.toDomainModel(record, category: category, account: account)
            }
        }
    }

    func create(_ transaction: Transaction) throws {
        var record = TransactionMapper.toRecord(transaction)
        record.isDirty = true
        try dbQueue.write { db in
            try record.insert(db)
        }
    }

    func update(_ transaction: Transaction) throws {
        var record = TransactionMapper.toRecord(transaction)
        record.updatedAt = Date()
        record.isDirty = true
        try dbQueue.write { db in
            try record.update(db)
        }
    }

    func delete(id: UUID) throws {
        try dbQueue.write { db in
            if var record = try TransactionRecord.fetchOne(db, key: id.uuidString) {
                record.deletedAt = Date()
                record.isDirty = true
                try record.update(db)
            }
        }
    }
}
