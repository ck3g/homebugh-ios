//
//  TransactionsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct TransactionsView: View {

    @EnvironmentObject var repositoryProvider: RepositoryProvider
    @StateObject private var viewModel: TransactionsViewModel

    @State private var addTransactionViewVisible = false
    @State private var transactionToDelete: Transaction?

    init(viewModel: TransactionsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .idle:
                    EmptyView()

                case .loading:
                    ProgressView()

                case .loaded(let transactions):
                    if transactions.isEmpty {
                        EmptyState(imageName: "",
                                   message: "No transactions yet.")
                    } else {
                        List {
                            ForEach(transactions, id: \.id) { transaction in
                                TransactionCell(transaction: transaction)
                                    .onAppear {
                                        viewModel.loadMoreContentIfNeeded(currentItem: transaction)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            transactionToDelete = transaction
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                            }
                        }
                    }

                case .error(let message):
                    EmptyState(imageName: "",
                               message: "No transactions yet.")
                        .onAppear {
                            errorMessage = message
                            showErrorAlert = true
                        }
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
            AddTransactionView(viewModel: {
                let vm = repositoryProvider.makeAddTransactionViewModel()
                vm.onTransactionAdded = { transaction in
                    viewModel.add(transaction)
                }
                return vm
            }())
        }
        .alert("Delete transaction",
               isPresented: Binding(
                   get: { transactionToDelete != nil },
                   set: { if !$0 { transactionToDelete = nil } }
               )
        ) {
            Button("Yes", role: .destructive) {
                if let transaction = transactionToDelete {
                    viewModel.delete(transaction)
                    transactionToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete the transaction?")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            viewModel.refresh()
        }
    }
}
