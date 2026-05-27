//
//  AccountViewModel.swift
//  HomeBugh
//
//  View model for the accounts list screen.
//

import SwiftUI

final class AccountViewModel: ObservableObject {

    enum ViewState {
        case idle
        case loading
        case loaded([Account])
        case error(String)
    }

    private enum Constants {
        static let pageSize = 6
        static let paginationThreshold = 5
    }

    @Published private(set) var state: ViewState = .idle

    private let repository: AccountsRepository
    private var items: [Account] = []
    private var page = 1
    private var canLoadMorePages = true
    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    init(repository: AccountsRepository) {
        self.repository = repository
    }

    // MARK: - Loading

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
        state = .loading

        Task { @MainActor in
            do {
                let newItems = try await repository.list(page: page, pageSize: Constants.pageSize)
                items.append(contentsOf: newItems)
                canLoadMorePages = newItems.count == Constants.pageSize
                page += 1
                updateLoadedState()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - CRUD

    func add(_ account: Account) {
        Task { @MainActor in
            do {
                try await repository.create(account)
                items.append(account)
                updateLoadedState()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private func updateLoadedState() {
        let sorted = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        state = .loaded(sorted)
    }
}
