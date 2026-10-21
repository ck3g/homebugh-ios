//
//  CurrenciesLocalStore.swift
//  HomeBugh
//
//  Local cache of currencies (from GET /currencies), used to resolve a
//  currency_id to its name/unit when pulling accounts.
//

import Foundation
import GRDB

struct CurrencyRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "currencies"

    var id: Int
    var name: String
    var unit: String
}

struct CurrenciesLocalStore {

    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Replaces the cached currency set with the given list.
    func replaceAll(_ currencies: [Currency]) throws {
        try dbQueue.write { db in
            try CurrencyRecord.deleteAll(db)
            for currency in currencies {
                try CurrencyRecord(id: currency.id, name: currency.name, unit: currency.unit).insert(db)
            }
        }
    }

    /// Returns the currency for a given id, if cached.
    func currency(id: Int) throws -> Currency? {
        try dbQueue.read { db in
            try CurrencyRecord.fetchOne(db, key: id).map {
                Currency(id: $0.id, name: $0.name, unit: $0.unit)
            }
        }
    }

    func all() throws -> [Currency] {
        try dbQueue.read { db in
            try CurrencyRecord.order(Column("id")).fetchAll(db)
                .map { Currency(id: $0.id, name: $0.name, unit: $0.unit) }
        }
    }
}
