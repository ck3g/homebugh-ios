//
//  CategoriesLocalStore.swift
//  HomeBugh
//
//  Local data access for categories using GRDB.
//

import Foundation
import GRDB

struct CategoriesLocalStore {

    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Returns all categories (active first, then inactive) for the category list screen.
    func list(page: Int, pageSize: Int) throws -> [Category] {
        try dbQueue.read { db in
            let records = try CategoryRecord
                .filter(Column("deletedAt") == nil)
                .order(Column("inactive"), Column("name"))
                .limit(pageSize, offset: (page - 1) * pageSize)
                .fetchAll(db)
            return records.map { $0.toDomainModel() }
        }
    }

    /// Returns only active categories for use in pickers (e.g. add transaction).
    func listActive(page: Int, pageSize: Int) throws -> [Category] {
        try dbQueue.read { db in
            let records = try CategoryRecord
                .filter(Column("deletedAt") == nil)
                .filter(Column("inactive") == false)
                .order(Column("name"))
                .limit(pageSize, offset: (page - 1) * pageSize)
                .fetchAll(db)
            return records.map { $0.toDomainModel() }
        }
    }

    func create(_ category: Category) throws {
        var record = CategoryRecord(from: category)
        record.isDirty = true
        try dbQueue.write { db in
            try record.insert(db)
        }
    }

    func update(_ category: Category) throws {
        var record = CategoryRecord(from: category)
        record.updatedAt = Date()
        record.isDirty = true
        try dbQueue.write { db in
            try record.update(db)
        }
    }

    func delete(id: UUID) throws {
        try dbQueue.write { db in
            if var record = try CategoryRecord.fetchOne(db, key: id.uuidString) {
                record.deletedAt = Date()
                record.isDirty = true
                try record.update(db)
            }
        }
    }

    func fetchAll() throws -> [Category] {
        try dbQueue.read { db in
            let records = try CategoryRecord
                .filter(Column("deletedAt") == nil)
                .order(Column("name"))
                .fetchAll(db)
            return records.map { $0.toDomainModel() }
        }
    }
}
