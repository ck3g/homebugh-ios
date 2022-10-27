//
//  AccountData.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10.11.2021.
//

import Foundation

struct Account: Codable, Hashable {
    var id: Int
    var name: String
    var balance: Double
    var currency: Currency
    var status: String
    var showInSummary: Bool
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.balance == rhs.balance
            && lhs.currency == rhs.currency
            && lhs.status == rhs.status
            && lhs.showInSummary == rhs.showInSummary
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
