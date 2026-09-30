//
//  RepositoryProvider.swift
//  HomeBugh
//
//  Composition root: creates and provides repository instances.
//  Matches the "currentRepo()" selector from the architecture diagram.
//

import Foundation
import GRDB

final class RepositoryProvider: ObservableObject {

    private let database: AppDatabase
    /// Session-scoped recency tracker shared across Add Transaction form instances.
    let recentSelectionStore = RecentSelectionStore()

    init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - Convenience initializer for production use

    static func makeDefault() throws -> RepositoryProvider {
        let database = try AppDatabase.makeDefault()
        return RepositoryProvider(database: database)
    }

    // MARK: - Repository accessors

    func transactionsRepository() -> TransactionsRepository {
        let localStore = TransactionsLocalStore(dbQueue: database.dbQueue)
        return LocalTransactionsRepository(localStore: localStore)
    }

    func accountsRepository() -> AccountsRepository {
        let localStore = AccountsLocalStore(dbQueue: database.dbQueue)
        return LocalAccountsRepository(localStore: localStore)
    }

    func categoriesRepository() -> CategoriesRepository {
        let localStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        return LocalCategoriesRepository(localStore: localStore)
    }

    // MARK: - Use case factories

    private func accountsUseCase() -> AccountsUseCase {
        DefaultAccountsUseCase(repository: accountsRepository())
    }

    private func categoriesUseCase() -> CategoriesUseCase {
        DefaultCategoriesUseCase(repository: categoriesRepository())
    }

    private func transactionsUseCase() -> TransactionsUseCase {
        DefaultTransactionsUseCase(repository: transactionsRepository())
    }

    // MARK: - View model factories

    func makeTransactionsViewModel() -> TransactionsViewModel {
        TransactionsViewModel(useCase: transactionsUseCase())
    }

    func makeAccountViewModel() -> AccountViewModel {
        AccountViewModel(useCase: accountsUseCase())
    }

    func makeCategoryViewModel() -> CategoryViewModel {
        CategoryViewModel(useCase: categoriesUseCase())
    }

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        AddTransactionViewModel(
            transactionsUseCase: transactionsUseCase(),
            accountsUseCase: accountsUseCase(),
            categoriesUseCase: categoriesUseCase(),
            recentSelection: recentSelectionStore
        )
    }
}
