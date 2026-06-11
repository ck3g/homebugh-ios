//
//  MockRepositories.swift
//  HomeBughTests
//
//  Mock implementations of repository protocols for unit tests.
//

import Foundation
@testable import HomeBugh

// MARK: - MockCategoriesRepository

final class MockCategoriesRepository: CategoriesRepository {

    var categories: [HomeBugh.Category] = []
    var activeCategories: [HomeBugh.Category] = []
    var createError: Error?
    var updateError: Error?
    var deleteError: Error?
    var listError: Error?

    func list(page: Int, pageSize: Int) async throws -> [HomeBugh.Category] {
        if let error = listError { throw error }
        let start = (page - 1) * pageSize
        let end = min(start + pageSize, categories.count)
        guard start < categories.count else { return [] }
        return Array(categories[start..<end])
    }

    func listActive(page: Int, pageSize: Int) async throws -> [HomeBugh.Category] {
        if let error = listError { throw error }
        let active = activeCategories.isEmpty
            ? categories.filter { !$0.inactive }
            : activeCategories
        let start = (page - 1) * pageSize
        let end = min(start + pageSize, active.count)
        guard start < active.count else { return [] }
        return Array(active[start..<end])
    }

    func create(_ category: HomeBugh.Category) async throws {
        if let error = createError { throw error }
        categories.append(category)
    }

    func update(_ category: HomeBugh.Category) async throws {
        if let error = updateError { throw error }
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }

    func delete(id: UUID) async throws {
        if let error = deleteError { throw error }
        categories.removeAll { $0.id == id }
    }
}

// MARK: - MockAccountsRepository

final class MockAccountsRepository: AccountsRepository {

    var accounts: [Account] = []
    var createError: Error?
    var updateError: Error?
    var deleteError: Error?
    var listError: Error?

    func list(page: Int, pageSize: Int) async throws -> [Account] {
        if let error = listError { throw error }
        let start = (page - 1) * pageSize
        let end = min(start + pageSize, accounts.count)
        guard start < accounts.count else { return [] }
        return Array(accounts[start..<end])
    }

    func create(_ account: Account) async throws {
        if let error = createError { throw error }
        accounts.append(account)
    }

    func update(_ account: Account) async throws {
        if let error = updateError { throw error }
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        }
    }

    func delete(id: UUID) async throws {
        if let error = deleteError { throw error }
        accounts.removeAll { $0.id == id }
    }
}

// MARK: - MockTransactionsRepository

final class MockTransactionsRepository: TransactionsRepository {

    var transactions: [Transaction] = []
    var createError: Error?
    var updateError: Error?
    var deleteError: Error?
    var listError: Error?

    func list(page: Int, pageSize: Int) async throws -> [Transaction] {
        if let error = listError { throw error }
        let start = (page - 1) * pageSize
        let end = min(start + pageSize, transactions.count)
        guard start < transactions.count else { return [] }
        return Array(transactions[start..<end])
    }

    func create(_ transaction: Transaction) async throws {
        if let error = createError { throw error }
        transactions.append(transaction)
    }

    func update(_ transaction: Transaction) async throws {
        if let error = updateError { throw error }
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        }
    }

    func delete(id: UUID) async throws {
        if let error = deleteError { throw error }
        transactions.removeAll { $0.id == id }
    }
}

// MARK: - Test Error

enum TestError: Error, LocalizedError {
    case mock

    var errorDescription: String? { "Mock error" }
}
