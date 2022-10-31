//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct TransactionsView: View {
    
    @EnvironmentObject var transactions: Transactions
    
    @State private var addTransactionViewVisible = false
    @State private var showingAlert = false
    @State private var deleteIndexSet: IndexSet?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(transactions.items, id: \.self) { transaction in
                    TransactionCell(transaction: transaction)
                        .onAppear {
                            transactions.loadMoreContentIfNeeded(currentItem: transaction)
                        }
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
            AddTransactionView()
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
