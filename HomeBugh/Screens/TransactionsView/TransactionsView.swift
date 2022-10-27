//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

class Transactions: ObservableObject {
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
}

struct TransactionsView: View {
    
    @ObservedObject var transactions = Transactions()
    
    @State private var addTransactionViewVisible = false
    @State private var showingAlert = false
    @State private var deleteIndexSet: IndexSet?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(transactions.items, id: \.self) { transaction in
                    TransactionCell(transaction: transaction)
                }
                .onDelete(perform: { indexSet in
                    self.showingAlert = true
                    self.deleteIndexSet = indexSet
                })

                .alert(isPresented: self.$showingAlert) {
                    let indexSet = self.deleteIndexSet!
                    return Alert(
                        title: Text("Delete transaction"),
                        message: Text("Are you sure you want to delete the transaction?"),
                        primaryButton: .default(Text("Yes")) {
                            self.transactions.items.remove(atOffsets: indexSet)
                        },
                        secondaryButton: .cancel())
                }
            }
            .navigationTitle("Transactions")
            .navigationBarItems(trailing:
                                    Button(action: {
                                        self.addTransactionViewVisible = true
                                    }) {
                                        Image(systemName: "plus")
                                    }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $addTransactionViewVisible) {
            AddTransactionView(transactions: self.transactions)
        }
    }
    
    func delete(at offsets: IndexSet) {
        transactions.items.remove(atOffsets: offsets)
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
