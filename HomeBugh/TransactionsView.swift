//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct TransactionsView: View {
    var body: some View {
        let transactionOne = Transaction(date: "October 20, 2020", amount: "18,23$", category: "Sport", account: "Deutsche Bank", comment: "Magnesium")
        let transactionTwo = Transaction(date: "October 20, 2020", amount: "5$", category: "Food", account: "Bar", comment: "")
        let transactionsArray = [transactionOne, transactionTwo]
        return List(transactionsArray) { transaction in
            TransactionCell(transaction: transaction)
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
