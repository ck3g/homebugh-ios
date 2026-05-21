//
//  AccountViewModel.swift
//  HomeBugh
//
//  View model for the accounts list screen.
//

import SwiftUI

final class AccountViewModel: ObservableObject {

    private enum Constants {
        static let pageSize = 6
        static let paginationThreshold = 5
    }

    @Published var items: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    private let repository: AccountsRepository
    private var page = 1
    private var canLoadMorePages = true

    init(repository: AccountsRepository) {
        self.repository = repository
    }

    func loadMoreContentIfNeeded(currentItem item: Account?) {
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

    func add(_ account: Account) {
        Task { @MainActor in
            do {
                try await repository.create(account)
                items.append(account)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
