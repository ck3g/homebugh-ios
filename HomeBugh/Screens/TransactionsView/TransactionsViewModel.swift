//
//  TransactionsViewModel.swift
//  HomeBugh
//
//  View model for the transactions list screen.
//

import SwiftUI

final class TransactionsViewModel: ObservableObject {

    enum ViewState {
        case idle
        case loading
        case loaded([Transaction])
        case error(String)
    }

    private enum Constants {
        static let pageSize = 10
        static let paginationThreshold = 5
    }

    @Published private(set) var state: ViewState = .idle

    private let repository: TransactionsRepository
    private var items: [Transaction] = []
    private var page = 1
    private var canLoadMorePages = true
    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    init(repository: TransactionsRepository) {
        self.repository = repository
    }

    // MARK: - Loading

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
        state = .loading

        Task { @MainActor in
            do {
                let newItems = try await repository.list(page: page, pageSize: Constants.pageSize)
                items.append(contentsOf: newItems)
                canLoadMorePages = newItems.count == Constants.pageSize
                page += 1
                state = .loaded(items)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - CRUD

    func add(_ transaction: Transaction) {
        items.insert(transaction, at: 0)
        state = .loaded(items)
    }

    func delete(_ transaction: Transaction) {
        items.removeAll { $0.id == transaction.id }
        state = .loaded(items)

        Task {
            try? await repository.delete(id: transaction.id)
        }
    }
}
