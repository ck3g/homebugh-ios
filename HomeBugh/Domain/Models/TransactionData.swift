//
//  TransactionData.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 27.10.2022.
//

import Foundation
import SwiftUI

struct Transaction: Codable, Hashable, Identifiable {
    var id: UUID
    var remoteId: Int?
    var amount: Double
    var comment: String
    var category: Category
    var account: Account
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool

    init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        amount: Double,
        comment: String,
        category: Category,
        account: Account,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        isDirty: Bool = false
    ) {
        self.id = id
        self.remoteId = remoteId
        self.amount = amount
        self.comment = comment
        self.category = category
        self.account = account
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.isDirty = isDirty
    }

    enum CodingKeys: String, CodingKey {
        case remoteId = "id"
        case amount
        case comment
        case category
        case account
        case createdAt
        case updatedAt
        case deletedAt
        case isDirty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let remoteId = try container.decodeIfPresent(Int.self, forKey: .remoteId)
        let amount = try container.decode(Double.self, forKey: .amount)
        let comment = try container.decode(String.self, forKey: .comment)
        let category = try container.decode(Category.self, forKey: .category)
        let account = try container.decode(Account.self, forKey: .account)
        let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        let updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        let deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        let isDirty = try container.decodeIfPresent(Bool.self, forKey: .isDirty) ?? false

        self.init(
            remoteId: remoteId,
            amount: amount,
            comment: comment,
            category: category,
            account: account,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isDirty: isDirty
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(remoteId, forKey: .remoteId)
        try container.encode(amount, forKey: .amount)
        try container.encode(comment, forKey: .comment)
        try container.encode(category, forKey: .category)
        try container.encode(account, forKey: .account)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(isDirty, forKey: .isDirty)
    }
}

struct TransactionData: Codable {
    var transactions: [Transaction]
    var metadata: Metadata
}
