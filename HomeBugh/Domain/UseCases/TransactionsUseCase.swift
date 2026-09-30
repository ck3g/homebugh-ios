//
//  TransactionsUseCase.swift
//  HomeBugh
//
//  Business operations for transactions. ViewModels depend on this protocol,
//  not on the repository directly.
//

import Foundation

protocol TransactionsUseCase {
    func list(page: Int, pageSize: Int) async throws -> [Transaction]
    func create(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(id: UUID) async throws
}

final class DefaultTransactionsUseCase: TransactionsUseCase {

    private let repository: TransactionsRepository

    init(repository: TransactionsRepository) {
        self.repository = repository
    }

    func list(page: Int, pageSize: Int) async throws -> [Transaction] {
        try await repository.list(page: page, pageSize: pageSize)
    }

    func create(_ transaction: Transaction) async throws {
        try await repository.create(transaction)
    }

    func update(_ transaction: Transaction) async throws {
        try await repository.update(transaction)
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
