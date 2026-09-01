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
        let delta = balanceDelta(amount: transaction.amount, categoryType: transaction.category.categoryType)
        try dbQueue.write { db in
            try record.insert(db)
            try applyBalanceDelta(delta, toAccount: record.accountId, in: db)
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

    /// Soft-deletes the transaction and reverses its effect on the account balance.
    func delete(id: UUID) throws {
        try dbQueue.write { db in
            guard var record = try TransactionRecord.fetchOne(db, key: id.uuidString) else { return }

            if let categoryRecord = try CategoryRecord.fetchOne(db, key: record.categoryId),
               let categoryType = CategoryType(rawValue: categoryRecord.categoryTypeId) {
                // Reverse the original delta.
                let delta = -balanceDelta(amount: record.amount, categoryType: categoryType)
                try applyBalanceDelta(delta, toAccount: record.accountId, in: db)
            }

            record.deletedAt = Date()
            record.isDirty = true
            try record.update(db)
        }
    }

    // MARK: - Balance side effects

    /// Signed amount to apply to the account balance: income adds, expense subtracts.
    private func balanceDelta(amount: Double, categoryType: CategoryType) -> Double {
        categoryType.isExpense ? -amount : amount
    }

    /// Applies a signed delta to the account's balance and marks it dirty.
    private func applyBalanceDelta(_ delta: Double, toAccount accountId: String, in db: Database) throws {
        guard var account = try AccountRecord.fetchOne(db, key: accountId) else { return }
        account.balance += delta
        account.updatedAt = Date()
        account.isDirty = true
        try account.update(db)
    }
}
