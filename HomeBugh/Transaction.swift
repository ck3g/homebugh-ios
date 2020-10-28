//
//  Transaction.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/22/20.
//

import Foundation

struct Transaction: Identifiable {
    var id = UUID()
    var date: String
    var amount: String
    var category: String
    var categoryType: String
    var account: String
    var comment: String
}
