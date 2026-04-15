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

    private let pageSize = 6
    private var page = 1
    private var canLoadMorePages = true

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
        // TODO: Wire to repository in Phase 4
        isLoading = false
    }
}
