//
//  AccountsUseCase.swift
//  HomeBugh
//
//  Business operations for accounts. ViewModels depend on this protocol,
//  not on the repository directly.
//

import Foundation

protocol AccountsUseCase {
    func list(page: Int, pageSize: Int) async throws -> [Account]
    func create(_ account: Account) async throws
    func update(_ account: Account) async throws
    func delete(id: UUID) async throws
}

final class DefaultAccountsUseCase: AccountsUseCase {

    private let repository: AccountsRepository

    init(repository: AccountsRepository) {
        self.repository = repository
    }

    func list(page: Int, pageSize: Int) async throws -> [Account] {
        try await repository.list(page: page, pageSize: pageSize)
    }

    func create(_ account: Account) async throws {
        try await repository.create(account)
    }

    func update(_ account: Account) async throws {
        try await repository.update(account)
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
