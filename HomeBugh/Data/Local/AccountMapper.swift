//
//  AccountMapper.swift
//  HomeBugh
//
//  Converts between AccountRecord (GRDB) and the Account domain model.
//

import Foundation

enum AccountMapper {

    static func toRecord(_ account: Account) -> AccountRecord {
        AccountRecord(
            id: account.id.uuidString,
            remoteId: account.remoteId,
            name: account.name,
            balance: account.balance,
            currencyId: account.currency.id,
            currencyName: account.currency.name,
            currencyUnit: account.currency.unit,
            status: account.status,
            showInSummary: account.showInSummary,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt,
            deletedAt: account.deletedAt,
            isDirty: account.isDirty
        )
    }

    static func toDomainModel(_ record: AccountRecord) -> Account {
        Account(
            id: UUID(uuidString: record.id) ?? UUID(),
            remoteId: record.remoteId,
            name: record.name,
            balance: record.balance,
            currency: Currency(
                id: record.currencyId,
                name: record.currencyName,
                unit: record.currencyUnit
            ),
            status: record.status,
            showInSummary: record.showInSummary,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: record.deletedAt,
            isDirty: record.isDirty
        )
    }
}
