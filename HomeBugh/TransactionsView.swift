//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

class Transactions: ObservableObject {
  @Published var items = [
    Transaction(date: "October 20, 2020", amount: "18,23$", category: "Sport", categoryType: "Spending", account: "Deutsche Bank", comment: "Magnesium"),
    Transaction(date: "October 20, 2020", amount: "5$", category: "Food", categoryType: "Spending", account: "Bar", comment: "")
]
}

struct TransactionsView: View {
    
    @ObservedObject var transactions = Transactions()
    
    @State private var addTransactionViewVisible = false
    
    var body: some View {
        NavigationView {
            List(transactions.items) { transaction in
                TransactionCell(transaction: transaction)
            }
            .navigationBarTitle("Transactions")
            .navigationBarItems(trailing:
                                    Button(action: {
                                        self.addTransactionViewVisible = true
                                    }) {
                                        Image(systemName: "plus")
                                    }
            )
        }
        .sheet(isPresented: $addTransactionViewVisible) {
            AddTransactionView(transactions: self.transactions)
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
