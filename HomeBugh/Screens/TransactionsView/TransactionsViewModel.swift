//
//  TransactionsViewModel.swift
//  HomeBugh
//
//  View model for the transactions list screen.
//

import SwiftUI

final class TransactionsViewModel: ObservableObject {

    private enum Constants {
        static let pageSize = 10
        static let paginationThreshold = 5
    }

    @Published var items = [Transaction]()
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    private let repository: TransactionsRepository
    private var page = 1
    private var canLoadMorePages = true

    init(repository: TransactionsRepository) {
        self.repository = repository
    }

    func loadMoreContentIfNeeded(currentItem item: Transaction?) {
        guard let item = item else {
            loadMoreContent()
            return
        }

        guard items.count >= Constants.paginationThreshold else { return }
        let thresholdIndex = items.index(items.endIndex, offsetBy: -Constants.paginationThreshold)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }

    func loadMoreContent() {
        guard !isLoading && canLoadMorePages else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let newItems = try await repository.list(page: page, pageSize: Constants.pageSize)
                items.append(contentsOf: newItems)
                canLoadMorePages = newItems.count == Constants.pageSize
                page += 1
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func add(_ transaction: Transaction) {
        Task { @MainActor in
            do {
                try await repository.create(transaction)
                items.append(transaction)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteItems(at offsets: IndexSet) {
        let transactionsToDelete = offsets.map { items[$0] }
        items.remove(atOffsets: offsets)

        Task {
            for transaction in transactionsToDelete {
                try? await repository.delete(id: transaction.id)
            }
        }
    }
}
