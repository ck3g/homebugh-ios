//
//  AppDatabase.swift
//  HomeBugh
//
//  GRDB DatabaseQueue setup and migrations.
//

import Foundation
import GRDB

struct AppDatabase {

    /// The database queue used for all local persistence.
    let dbQueue: DatabaseQueue

    /// Creates (or opens) the database at the default app location.
    init(_ dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    /// Default on-disk database stored in Application Support (included in iCloud backup).
    static func makeDefault() throws -> AppDatabase {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbURL = appSupportURL.appendingPathComponent("homebugh.sqlite")
        let dbQueue = try DatabaseQueue(path: dbURL.path)
        return try AppDatabase(dbQueue)
    }

    /// In-memory database for previews and tests.
    static func makeEmpty() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue(configuration: Configuration())
        return try AppDatabase(dbQueue)
    }

    // MARK: - Migrations

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_createTables") { db in

            // Categories table
            try db.create(table: "categories") { t in
                t.column("id", .text).notNull().primaryKey()
                t.column("remoteId", .integer)
                t.column("name", .text).notNull()
                t.column("categoryTypeName", .text).notNull()
                t.column("categoryTypeId", .integer).notNull()
                t.column("inactive", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
                t.column("isDirty", .boolean).notNull().defaults(to: false)
            }

            // Accounts table
            try db.create(table: "accounts") { t in
                t.column("id", .text).notNull().primaryKey()
                t.column("remoteId", .integer)
                t.column("name", .text).notNull()
                t.column("balance", .double).notNull().defaults(to: 0.0)
                t.column("currencyId", .integer).notNull()
                t.column("currencyName", .text).notNull()
                t.column("currencyUnit", .text).notNull()
                t.column("status", .text).notNull()
                t.column("showInSummary", .boolean).notNull().defaults(to: true)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
                t.column("isDirty", .boolean).notNull().defaults(to: false)
            }

            // Transactions table
            try db.create(table: "transactions") { t in
                t.column("id", .text).notNull().primaryKey()
                t.column("remoteId", .integer)
                t.column("amount", .double).notNull()
                t.column("comment", .text).notNull().defaults(to: "")
                t.column("categoryId", .text).notNull()
                    .references("categories", onDelete: .restrict)
                t.column("accountId", .text).notNull()
                    .references("accounts", onDelete: .restrict)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
                t.column("isDirty", .boolean).notNull().defaults(to: false)
            }
        }

        return migrator
    }
}
