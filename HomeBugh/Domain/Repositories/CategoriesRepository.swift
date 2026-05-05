import Foundation

protocol CategoriesRepository {
    func list(page: Int, pageSize: Int) async throws -> [Category]
    func listActive(page: Int, pageSize: Int) async throws -> [Category]
    func create(_ category: Category) async throws
    func update(_ category: Category) async throws
    func delete(id: UUID) async throws
}
