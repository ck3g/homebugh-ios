//
//  TransactionData.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 27.10.2022.
//

import Foundation
import SwiftUI

struct Transaction: Codable, Hashable {
    var id: Int
    var amount: Double
    var comment: String
    var category: Category
    var account: Account
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id &&
                lhs.amount == rhs.amount &&
                lhs.comment == rhs.comment &&
                lhs.category == rhs.category &&
                lhs.account == rhs.account
    }
}

struct TransactionData: Codable {
    var transactions: [Transaction]
    var metadata: Metadata
}
