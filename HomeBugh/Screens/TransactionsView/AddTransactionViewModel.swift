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
    let moneyFormatter: MoneyFormatterProtocol

    /// Called when a transaction is successfully saved
    var onTransactionAdded: ((Transaction) -> Void)?

    init(
        transactionsRepository: TransactionsRepository,
        accountsRepository: AccountsRepository,
        categoriesRepository: CategoriesRepository,
        moneyFormatter: MoneyFormatterProtocol = MoneyFormatter()
    ) {
        self.transactionsRepository = transactionsRepository
        self.accountsRepository = accountsRepository
        self.categoriesRepository = categoriesRepository
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
                accounts = try await accountsRepository.list(page: 1, pageSize: Constants.maxPickerItems)
                categories = try await categoriesRepository.listActive(page: 1, pageSize: Constants.maxPickerItems)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
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
                onTransactionAdded?(transaction)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        return true
    }
}
