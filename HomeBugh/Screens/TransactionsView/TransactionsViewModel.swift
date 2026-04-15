//
//  TransactionsViewModel.swift
//  HomeBugh
//
//  View model for the transactions list screen.
//

import SwiftUI

final class TransactionsViewModel: ObservableObject {
    @Published var items = [Transaction]()
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    private let pageSize = 10
    private var page = 1
    private var canLoadMorePages = true

    func loadMoreContentIfNeeded(currentItem item: Transaction?) {
        guard let item = item else {
            loadMoreContent()
            return
        }

        guard items.count >= 5 else { return }
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }

    func loadMoreContent() {
        guard !isLoading && canLoadMorePages else { return }
        isLoading = true
        // TODO: Wire to repository in Phase 4
        isLoading = false
    }

    func add(_ transaction: Transaction) {
        items.append(transaction)
    }

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}
