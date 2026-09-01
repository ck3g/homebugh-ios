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
    var categoryTypeId: Int
    var inactive: Bool
    var status: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool
}
