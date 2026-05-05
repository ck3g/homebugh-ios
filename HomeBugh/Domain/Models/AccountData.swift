//
//  AccountData.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10.11.2021.
//

import Foundation

struct Account: Codable, Hashable, Identifiable {
    var id: UUID
    var remoteId: Int?
    var name: String
    var balance: Double
    var currency: Currency
    var status: String
    var showInSummary: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isDirty: Bool

    init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        name: String,
        balance: Double,
        currency: Currency,
        status: String,
        showInSummary: Bool,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        isDirty: Bool = false
    ) {
        self.id = id
        self.remoteId = remoteId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.status = status
        self.showInSummary = showInSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.isDirty = isDirty
    }

    enum CodingKeys: String, CodingKey {
        case remoteId = "id"
        case name
        case balance
        case currency
        case status
        case showInSummary
        case createdAt
        case updatedAt
        case deletedAt
        case isDirty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let remoteId = try container.decodeIfPresent(Int.self, forKey: .remoteId)
        let name = try container.decode(String.self, forKey: .name)
        let balance = try container.decode(Double.self, forKey: .balance)
        let currency = try container.decode(Currency.self, forKey: .currency)
        let status = try container.decode(String.self, forKey: .status)
        let showInSummary = try container.decode(Bool.self, forKey: .showInSummary)
        let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        let updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        let deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        let isDirty = try container.decodeIfPresent(Bool.self, forKey: .isDirty) ?? false

        self.init(
            remoteId: remoteId,
            name: name,
            balance: balance,
            currency: currency,
            status: status,
            showInSummary: showInSummary,
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
        try container.encode(balance, forKey: .balance)
        try container.encode(currency, forKey: .currency)
        try container.encode(status, forKey: .status)
        try container.encode(showInSummary, forKey: .showInSummary)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(isDirty, forKey: .isDirty)
    }
}

struct Currency: Codable, Hashable {
    var id: Int
    var name: String
    var unit: String
}

struct AccountData: Codable {
    var accounts: [Account]
    var metadata: Metadata
}

struct Metadata: Codable {
    var currentPage: Int
    var pageSize: Int
    var firstPage: Int
    var lastPage: Int
    var totalRecords: Int
}
