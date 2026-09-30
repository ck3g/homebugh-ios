//
//  CategoriesUseCase.swift
//  HomeBugh
//
//  Business operations for categories. ViewModels depend on this protocol,
//  not on the repository directly.
//

import Foundation

protocol CategoriesUseCase {
    func list(page: Int, pageSize: Int) async throws -> [Category]
    func listActive(page: Int, pageSize: Int) async throws -> [Category]
    func create(_ category: Category) async throws
    func update(_ category: Category) async throws
    func delete(id: UUID) async throws
}

final class DefaultCategoriesUseCase: CategoriesUseCase {

    private let repository: CategoriesRepository

    init(repository: CategoriesRepository) {
        self.repository = repository
    }

    func list(page: Int, pageSize: Int) async throws -> [Category] {
        try await repository.list(page: page, pageSize: pageSize)
    }

    func listActive(page: Int, pageSize: Int) async throws -> [Category] {
        try await repository.listActive(page: page, pageSize: pageSize)
    }

    func create(_ category: Category) async throws {
        try await repository.create(category)
    }

    func update(_ category: Category) async throws {
        try await repository.update(category)
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
