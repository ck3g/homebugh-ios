//
//  TransactionRecord.swift
//  HomeBugh
//
//  GRDB record for the transactions table.
//

import Foundation
import GRDB

struct TransactionRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "transactions"

    var id: String          // UUID as string
    var remoteId: Int?
    var amount: Double
    var comment: String
    var categoryId: String  // UUID of the related category
    var accountId: String   // UUID of the related account
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool

    // MARK: - Convert from domain model

    init(from transaction: Transaction) {
        self.id = transaction.id.uuidString
        self.remoteId = transaction.remoteId
        self.amount = transaction.amount
        self.comment = transaction.comment
        self.categoryId = transaction.category.id.uuidString
        self.accountId = transaction.account.id.uuidString
        self.createdAt = transaction.createdAt
        self.updatedAt = transaction.updatedAt
        self.deletedAt = transaction.deletedAt
        self.isDirty = transaction.isDirty
    }

    // MARK: - Convert to domain model (requires category and account)

    func toDomainModel(category: Category, account: Account) -> Transaction {
        Transaction(
            id: UUID(uuidString: id) ?? UUID(),
            remoteId: remoteId,
            amount: amount,
            comment: comment,
            category: category,
            account: account,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isDirty: isDirty
        )
    }
}
