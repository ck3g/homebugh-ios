//
//  AccountRecord.swift
//  HomeBugh
//
//  GRDB record for the accounts table.
//

import Foundation
import GRDB

struct AccountRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "accounts"

    var id: String          // UUID as string
    var remoteId: Int?
    var name: String
    var balance: Double
    var currencyId: Int
    var currencyName: String
    var currencyUnit: String
    var status: String
    var showInSummary: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool
}
