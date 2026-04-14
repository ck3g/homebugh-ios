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

    // MARK: - Convert from domain model

    init(from account: Account) {
        self.id = account.id.uuidString
        self.remoteId = account.remoteId
        self.name = account.name
        self.balance = account.balance
        self.currencyId = account.currency.id
        self.currencyName = account.currency.name
        self.currencyUnit = account.currency.unit
        self.status = account.status
        self.showInSummary = account.showInSummary
        self.createdAt = account.createdAt
        self.updatedAt = account.updatedAt
        self.deletedAt = account.deletedAt
        self.isDirty = account.isDirty
    }

    // MARK: - Convert to domain model

    func toDomainModel() -> Account {
        Account(
            id: UUID(uuidString: id) ?? UUID(),
            remoteId: remoteId,
            name: name,
            balance: balance,
            currency: Currency(id: currencyId, name: currencyName, unit: currencyUnit),
            status: status,
            showInSummary: showInSummary,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isDirty: isDirty
        )
    }
}
