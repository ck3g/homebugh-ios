//
//  CategoryList.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 28.10.2021.
//

import Foundation

struct Category: Codable, Hashable, Identifiable {
    var id: UUID
    var remoteId: Int?
    var name: String
    var categoryType: CategoryType
    var inactive: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool

    init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        name: String,
        categoryType: CategoryType,
        inactive: Bool,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        isDirty: Bool = false
    ) {
        self.id = id
        self.remoteId = remoteId
        self.name = name
        self.categoryType = categoryType
        self.inactive = inactive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.isDirty = isDirty
    }

    enum CodingKeys: String, CodingKey {
        case remoteId = "id"
        case name
        case categoryType
        case inactive
        case createdAt
        case updatedAt
        case deletedAt
        case isDirty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let remoteId = try container.decodeIfPresent(Int.self, forKey: .remoteId)
        let name = try container.decode(String.self, forKey: .name)
        let categoryType = try container.decode(CategoryType.self, forKey: .categoryType)
        let inactive = try container.decode(Bool.self, forKey: .inactive)
        let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        let updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        let deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        let isDirty = try container.decodeIfPresent(Bool.self, forKey: .isDirty) ?? false

        self.init(
            remoteId: remoteId,
            name: name,
            categoryType: categoryType,
            inactive: inactive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isDirty: isDirty
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(remoteId, forKey: .remoteId)
        try container.encode(name, forKey: .name)
        try container.encode(categoryType, forKey: .categoryType)
        try container.encode(inactive, forKey: .inactive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(isDirty, forKey: .isDirty)
    }
}

struct CategoryType: Codable, Hashable {
    var id: Int
    var name: String
}

struct CategoryData: Codable {
    var categories: [Category]
    var metadata: Metadata
}
