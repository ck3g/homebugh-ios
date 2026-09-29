//
//  AddTransactionViewModel.swift
//  HomeBugh
//
//  View model for the add transaction form.
//

import SwiftUI

final class AddTransactionViewModel: ObservableObject {

    private enum Constants {
        static let maxPickerItems = 100
    }

    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var selectedAccountId: UUID?
    @Published var selectedCategoryId: UUID?
    @Published var amount = ""
    @Published var comment = ""
    @Published var errorMessage = ""

    private let transactionsRepository: TransactionsRepository
    private let accountsRepository: AccountsRepository
    private let categoriesRepository: CategoriesRepository
    private let recentSelection: RecentSelectionTracking
    let moneyFormatter: MoneyFormatterProtocol

    /// Called when a transaction is successfully saved
    var onTransactionAdded: ((Transaction) -> Void)?

    init(
        transactionsRepository: TransactionsRepository,
        accountsRepository: AccountsRepository,
        categoriesRepository: CategoriesRepository,
        recentSelection: RecentSelectionTracking = RecentSelectionStore(),
        moneyFormatter: MoneyFormatterProtocol = MoneyFormatter()
    ) {
        self.transactionsRepository = transactionsRepository
        self.accountsRepository = accountsRepository
        self.categoriesRepository = categoriesRepository
        self.recentSelection = recentSelection
        self.moneyFormatter = moneyFormatter
    }

    var isValid: Bool {
        selectedAccountId != nil &&
        selectedCategoryId != nil &&
        !amount.trimmingCharacters(in: .whitespaces).isEmpty &&
        (moneyFormatter.parse(amount) ?? 0) > 0
    }

    func loadData() {
        Task { @MainActor in
            do {
                let loadedAccounts = try await accountsRepository.list(page: 1, pageSize: Constants.maxPickerItems)
                let loadedCategories = try await categoriesRepository.listActive(page: 1, pageSize: Constants.maxPickerItems)

                // Seed recency from transaction history (newest first) once per session.
                let recentTransactions = try await transactionsRepository.list(page: 1, pageSize: Constants.maxPickerItems)
                recentSelection.seedIfNeeded(
                    accountIds: recentTransactions.map { $0.account.id },
                    categoryIds: recentTransactions.map { $0.category.id }
                )

                // Order "recently used first" (LIFO), then preselect the top item.
                accounts = orderByRecency(loadedAccounts, recentIds: recentSelection.accountIds)
                categories = orderByRecency(loadedCategories, recentIds: recentSelection.categoryIds)
                selectedAccountId = accounts.first?.id
                selectedCategoryId = categories.first?.id
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Orders items so the most-recently-used appear first, followed by the rest
    /// in their original order.
    private func orderByRecency<T: Identifiable>(_ items: [T], recentIds: [UUID]) -> [T] where T.ID == UUID {
        let byId = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let recent = recentIds.compactMap { byId[$0] }
        let recentIdSet = Set(recentIds)
        let remaining = items.filter { !recentIdSet.contains($0.id) }
        return recent + remaining
    }

    func save() -> Bool {
        guard let accountId = selectedAccountId,
              let categoryId = selectedCategoryId,
              let account = accounts.first(where: { $0.id == accountId }),
              let category = categories.first(where: { $0.id == categoryId })
        else { return false }

        let transaction = Transaction(
            amount: moneyFormatter.parse(amount) ?? 0.0,
            comment: comment.trimmingCharacters(in: .whitespaces),
            category: category,
            account: account
        )

        Task { @MainActor in
            do {
                try await transactionsRepository.create(transaction)
                recentSelection.recordAccount(account.id)
                recentSelection.recordCategory(category.id)
                onTransactionAdded?(transaction)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        return true
    }
}
