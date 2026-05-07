//
//  CategoryViewModel.swift
//  HomeBugh
//
//  View model for the categories list screen.
//

import SwiftUI

final class CategoryViewModel: ObservableObject {
    @Published var items: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    var activeItems: [Category] { items.filter { !$0.inactive } }
    var inactiveItems: [Category] { items.filter { $0.inactive } }

    private let repository: CategoriesRepository
    private let pageSize = 20
    private var page = 1
    private var canLoadMorePages = true

    init(repository: CategoriesRepository) {
        self.repository = repository
    }

    func loadMoreContentIfNeeded(currentItem item: Category?) {
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

    func add(_ category: Category) {
        Task { @MainActor in
            do {
                try await repository.create(category)
                items.append(category)
            } catch {
                errorMessage = error.localizedDescription
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
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Soft-delete: sets status to "deleted". Fails if transactions reference this category.
    func delete(_ category: Category) {
        Task { @MainActor in
            do {
                try await repository.delete(id: category.id)
                items.removeAll { $0.id == category.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
