//
//  CategoryRecord.swift
//  HomeBugh
//
//  GRDB record for the categories table.
//

import Foundation
import GRDB

struct CategoryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "categories"

    var id: String          // UUID as string
    var remoteId: Int?
    var name: String
    var categoryTypeName: String
    var categoryTypeId: Int
    var inactive: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool

    // MARK: - Convert from domain model

    init(from category: Category) {
        self.id = category.id.uuidString
        self.remoteId = category.remoteId
        self.name = category.name
        self.categoryTypeName = category.categoryType.name
        self.categoryTypeId = category.categoryType.id
        self.inactive = category.inactive
        self.createdAt = category.createdAt
        self.updatedAt = category.updatedAt
        self.deletedAt = category.deletedAt
        self.isDirty = category.isDirty
    }

    // MARK: - Convert to domain model

    func toDomainModel() -> Category {
        Category(
            id: UUID(uuidString: id) ?? UUID(),
            remoteId: remoteId,
            name: name,
            categoryType: CategoryType(id: categoryTypeId, name: categoryTypeName),
            inactive: inactive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isDirty: isDirty
        )
    }
}
