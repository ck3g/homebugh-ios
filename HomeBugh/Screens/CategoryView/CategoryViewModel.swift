//
//  CategoryViewModel.swift
//  HomeBugh
//
//  View model for the categories list screen.
//

import SwiftUI

final class CategoryViewModel: ObservableObject {

    enum ViewState {
        case idle
        case loading
        case loaded(active: [Category], inactive: [Category])
        case error(String)
    }

    private enum Constants {
        static let pageSize = 20
        static let paginationThreshold = 5
    }

    @Published private(set) var state: ViewState = .idle

    private let repository: CategoriesRepository
    private var items: [Category] = []
    private var page = 1
    private var canLoadMorePages = true
    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    init(repository: CategoriesRepository) {
        self.repository = repository
    }

    // MARK: - Loading

    func loadMoreContentIfNeeded(currentItem item: Category?) {
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

    func add(_ category: Category) {
        Task { @MainActor in
            do {
                try await repository.create(category)
                items.append(category)
                updateLoadedState()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func update(_ category: Category) {
        Task { @MainActor in
            do {
                try await repository.update(category)
                if let index = items.firstIndex(where: { $0.id == category.id }) {
                    items[index] = category
                }
                updateLoadedState()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    /// Soft-delete: sets status to "deleted". Fails if transactions reference this category.
    func delete(_ category: Category) {
        Task { @MainActor in
            do {
                try await repository.delete(id: category.id)
                items.removeAll { $0.id == category.id }
                updateLoadedState()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private func updateLoadedState() {
        let sorted = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let active = sorted.filter { !$0.inactive }
        let inactive = sorted.filter { $0.inactive }
        state = .loaded(active: active, inactive: inactive)
    }
}
