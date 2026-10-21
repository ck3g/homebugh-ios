//
//  TransactionMapper.swift
//  HomeBugh
//
//  Converts between TransactionRecord (GRDB) and the Transaction domain model.
//

import Foundation

enum TransactionMapper {

    static func toRecord(_ transaction: Transaction) -> TransactionRecord {
        TransactionRecord(
            id: transaction.id.uuidString,
            remoteId: transaction.remoteId,
            clientUuid: transaction.clientUuid.uuidString,
            remoteServerId: transaction.remoteServerId,
            amount: transaction.amount,
            comment: transaction.comment,
            categoryId: transaction.category.id.uuidString,
            accountId: transaction.account.id.uuidString,
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt,
            deletedAt: transaction.deletedAt,
            isDirty: transaction.isDirty
        )
    }

    /// Requires the related category and account, which are stored separately.
    static func toDomainModel(
        _ record: TransactionRecord,
        category: Category,
        account: Account
    ) -> Transaction {
        Transaction(
            id: UUID(uuidString: record.id) ?? UUID(),
            remoteId: record.remoteId,
            clientUuid: UUID(uuidString: record.clientUuid) ?? UUID(),
            remoteServerId: record.remoteServerId,
            amount: record.amount,
            comment: record.comment,
            category: category,
            account: account,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: record.deletedAt,
            isDirty: record.isDirty
        )
    }
}
