//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct TransactionsView: View {

    @ObservedObject var viewModel: TransactionsViewModel

    @State private var addTransactionViewVisible = false
    @State private var showingAlert = false
    @State private var deleteIndexSet: IndexSet?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.items, id: \.id) { transaction in
                    TransactionCell(transaction: transaction)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: transaction)
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
                            viewModel.deleteItems(at: indexSet)
                        },
                        secondaryButton: .cancel())
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addTransactionViewVisible = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $addTransactionViewVisible) {
            AddTransactionView().environmentObject(viewModel)
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadMoreContent()
            }
        }
    }
}
