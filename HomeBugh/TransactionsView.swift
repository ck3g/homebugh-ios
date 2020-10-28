//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct TransactionsView: View {
    
    let transactionsArray = [
        Transaction(date: "October 20, 2020", amount: "18,23$", category: "Sport", categoryType: "Spending", account: "Deutsche Bank", comment: "Magnesium"),
        Transaction(date: "October 20, 2020", amount: "5$", category: "Food", categoryType: "Spending", account: "Bar", comment: "")
    ]
    
    var body: some View {
        List(transactionsArray) { transaction in
            TransactionCell(transaction: transaction)
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
