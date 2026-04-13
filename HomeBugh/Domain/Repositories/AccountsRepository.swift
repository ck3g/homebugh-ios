import Foundation

protocol AccountsRepository {
    func list(page: Int, pageSize: Int) async throws -> [Account]
    func create(_ account: Account) async throws
    func update(_ account: Account) async throws
    func delete(id: Int) async throws
}
