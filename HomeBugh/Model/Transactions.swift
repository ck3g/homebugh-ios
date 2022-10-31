//
//  Transactions.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 27.10.2022.
//

import SwiftUI

final class Transactions: ObservableObject {
    
    @Published var transactionData: TransactionData?
    @Published var items = [
        Transaction(id: 0,
                    amount: "18,23$",
                    comment: "Magnesium",
                    category: Category(id: 0, name: "Food", categoryType: CategoryType(id: 0, name: "Spending"), inactive: false),
                    account: Account(id: 0, name: "Deutsche Bank", balance: 100000.0, currency: Currency(id: 0, name: "Euro", unit: "Euro"), status: "active", showInSummary: true)),
        Transaction(id: 1,
                    amount: "5$",
                    comment: "",
                    category: Category(id: 1, name: "Food", categoryType: CategoryType(id: 1, name: "Spending"), inactive: false),
                    account: Account(id: 1, name: "Bar", balance: 1000.0, currency: Currency(id: 1, name: "Euro", unit: "Euro"), status: "active", showInSummary: true))
    ]
    
    //    var totalPrice: Double {
    //        items.reduce(0) { $0 + $1.price}
    //    }
    //
    //    func add(_ appetizer: Appetizer) {
    //        items.append(appetizer)
    //    }
    //
    //    func deleteItems(at offsets: IndexSet) {
    //        items.remove(atOffsets: offsets)
    //    }
}
