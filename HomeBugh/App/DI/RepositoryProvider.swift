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
        return TransactionsRepositoryImpl(localStore: localStore)
    }

    func accountsRepository() -> AccountsRepository {
        let localStore = AccountsLocalStore(dbQueue: database.dbQueue)
        return AccountsRepositoryImpl(localStore: localStore)
    }

    func categoriesRepository() -> CategoriesRepository {
        let localStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        return CategoriesRepositoryImpl(localStore: localStore)
    }
}
