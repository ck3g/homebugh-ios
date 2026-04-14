//
//  TransactionsRepositoryImpl.swift
//  HomeBugh
//
//  Concrete implementation of TransactionsRepository backed by local storage.
//

import Foundation

final class TransactionsRepositoryImpl: TransactionsRepository {

    private let localStore: TransactionsLocalStore

    init(localStore: TransactionsLocalStore) {
        self.localStore = localStore
    }

    func list(page: Int, pageSize: Int) async throws -> [Transaction] {
        try localStore.list(page: page, pageSize: pageSize)
    }

    func create(_ transaction: Transaction) async throws {
        try localStore.create(transaction)
    }

    func update(_ transaction: Transaction) async throws {
        try localStore.update(transaction)
    }

    func delete(id: UUID) async throws {
        try localStore.delete(id: id)
    }
}
