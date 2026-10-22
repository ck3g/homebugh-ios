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

    // MARK: - Auth infrastructure (shared instances)

    private let tokenStore: TokenStore = KeychainTokenStore()
    private let serverConfig: ServerConfigStoring = ServerConfigStore()

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

    // MARK: - Auth

    func authUseCase() -> AuthUseCase {
        DefaultAuthUseCase(
            tokenStore: tokenStore,
            serverConfig: serverConfig,
            makeAuthService: { baseURL in
                AuthService(httpClient: URLSessionHTTPClient(baseURL: baseURL.appendingPathComponent("api/v1")))
            }
        )
    }

    /// Whether a server session is currently active (token present).
    var isLoggedIn: Bool {
        tokenStore.hasToken
    }

    // MARK: - Sync

    /// Builds a sync service for the current session, or nil if not connected
    /// to a server (no token or no base URL configured).
    func makeSyncService() -> SyncServicing? {
        guard let token = tokenStore.read(),
              let baseURL = serverConfig.baseURL else {
            return nil
        }

        let httpClient = URLSessionHTTPClient(baseURL: baseURL.appendingPathComponent("api/v1"))
        let transport = HTTPSyncTransport(httpClient: httpClient, token: token)

        let accountsStore = AccountsLocalStore(dbQueue: database.dbQueue)
        let categoriesStore = CategoriesLocalStore(dbQueue: database.dbQueue)
        let transactionsStore = TransactionsLocalStore(dbQueue: database.dbQueue)
        let currenciesStore = CurrenciesLocalStore(dbQueue: database.dbQueue)
        let metadataStore = SyncMetadataStore(dbQueue: database.dbQueue)

        let pushService = SyncPushService(
            accountsStore: accountsStore,
            categoriesStore: categoriesStore,
            transactionsStore: transactionsStore,
            transport: transport
        )
        let pullService = SyncPullService(
            accountsStore: accountsStore,
            categoriesStore: categoriesStore,
            transactionsStore: transactionsStore,
            currenciesStore: currenciesStore,
            metadataStore: metadataStore,
            transport: transport
        )

        return SyncService(
            pushService: pushService,
            pullService: pullService,
            currenciesService: CurrenciesService(httpClient: httpClient),
            currenciesStore: currenciesStore,
            metadataStore: metadataStore,
            token: token
        )
    }

    func lastSyncedAt() -> Date? {
        try? SyncMetadataStore(dbQueue: database.dbQueue).lastSyncedAt()
    }

    // MARK: - View model factories

    @MainActor
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authUseCase: authUseCase())
    }

    @MainActor
    func makeSyncViewModel() -> SyncViewModel {
        SyncViewModel(
            makeSyncService: { [weak self] in self?.makeSyncService() },
            lastSyncedProvider: { [weak self] in self?.lastSyncedAt() }
        )
    }

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
