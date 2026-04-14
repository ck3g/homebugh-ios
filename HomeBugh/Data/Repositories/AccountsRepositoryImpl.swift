//
//  AccountsRepositoryImpl.swift
//  HomeBugh
//
//  Concrete implementation of AccountsRepository backed by local storage.
//

import Foundation

final class AccountsRepositoryImpl: AccountsRepository {

    private let localStore: AccountsLocalStore

    init(localStore: AccountsLocalStore) {
        self.localStore = localStore
    }

    func list(page: Int, pageSize: Int) async throws -> [Account] {
        try localStore.list(page: page, pageSize: pageSize)
    }

    func create(_ account: Account) async throws {
        try localStore.create(account)
    }

    func update(_ account: Account) async throws {
        try localStore.update(account)
    }

    func delete(id: UUID) async throws {
        try localStore.delete(id: id)
    }
}
