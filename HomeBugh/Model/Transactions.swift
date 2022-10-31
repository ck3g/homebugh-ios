//
//  Transactions.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 27.10.2022.
//

import SwiftUI

final class Transactions: ObservableObject {
    @Published var pageSize: Int = 10
    @Published private var page: Int = 1
    @Published var transactionData: TransactionData?
    @Published var items = [Transaction]()
    @Published var isLoadingPage = false
    @Published var errorMessage: String = ""
    @Published private var canLoadMorePages = true
    
    init() {
        loadMoreContent()
    }
    
    func loadMoreContentIfNeeded(currentItem item: Transaction?) {
        guard let item = item else {
            loadMoreContent()
            return
        }
        
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }
    
    private func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else {
            return
        }
        isLoadingPage = true
        getTransactions()
    }
    
    func getTransactions() {
        NetworkManager.shared.getTransactionsList(
            pageSize: pageSize,
            page: page
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingPage = false
                switch result {
                case .success(let transactionList):
                    self.items = self.items + transactionList.transactions
                    self.canLoadMorePages = transactionList.metadata.currentPage < transactionList.metadata.lastPage
                    self.page += 1
                    
                case .failure (let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func add(_ transaction: Transaction) {
        items.append(transaction)
    }
    
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
}
