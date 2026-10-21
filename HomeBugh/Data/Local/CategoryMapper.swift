//
//  CategoryMapper.swift
//  HomeBugh
//
//  Converts between CategoryRecord (GRDB) and the Category domain model.
//

import Foundation

enum CategoryMapper {

    static func toRecord(_ category: Category) -> CategoryRecord {
        CategoryRecord(
            id: category.id.uuidString,
            remoteId: category.remoteId,
            clientUuid: category.clientUuid.uuidString,
            remoteServerId: category.remoteServerId,
            name: category.name,
            categoryTypeId: category.categoryType.rawValue,
            inactive: category.inactive,
            status: category.status.rawValue,
            createdAt: category.createdAt,
            updatedAt: category.updatedAt,
            deletedAt: category.deletedAt,
            isDirty: category.isDirty
        )
    }

    static func toDomainModel(_ record: CategoryRecord) -> Category {
        Category(
            id: UUID(uuidString: record.id) ?? UUID(),
            remoteId: record.remoteId,
            clientUuid: UUID(uuidString: record.clientUuid) ?? UUID(),
            remoteServerId: record.remoteServerId,
            name: record.name,
            categoryType: CategoryType(rawValue: record.categoryTypeId) ?? .expense,
            inactive: record.inactive,
            status: CategoryStatus(rawValue: record.status) ?? .active,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: record.deletedAt,
            isDirty: record.isDirty
        )
    }
}
