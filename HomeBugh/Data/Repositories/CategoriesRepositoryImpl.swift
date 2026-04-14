//
//  CategoriesRepositoryImpl.swift
//  HomeBugh
//
//  Concrete implementation of CategoriesRepository backed by local storage.
//

import Foundation

final class CategoriesRepositoryImpl: CategoriesRepository {

    private let localStore: CategoriesLocalStore

    init(localStore: CategoriesLocalStore) {
        self.localStore = localStore
    }

    func list(page: Int, pageSize: Int) async throws -> [Category] {
        try localStore.list(page: page, pageSize: pageSize)
    }

    func create(_ category: Category) async throws {
        try localStore.create(category)
    }

    func update(_ category: Category) async throws {
        try localStore.update(category)
    }

    func delete(id: UUID) async throws {
        try localStore.delete(id: id)
    }
}
