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
}
