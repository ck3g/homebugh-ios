//
//  AccountViewModel.swift
//  HomeBugh
//
//  View model for the accounts list screen.
//

import SwiftUI

final class AccountViewModel: ObservableObject {
    @Published var items: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    private let repository: AccountsRepository
    private let pageSize = 6
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

        guard items.count >= 5 else { return }
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }

    func loadMoreContent() {
        guard !isLoading && canLoadMorePages else { return }
        isLoading = true

        Task { @MainActor in
            do {
                let newItems = try await repository.list(page: page, pageSize: pageSize)
                items.append(contentsOf: newItems)
                canLoadMorePages = newItems.count == pageSize
                page += 1
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
