import Foundation

protocol TransactionsRepository {
    func list(page: Int, pageSize: Int) async throws -> [Transaction]
    func create(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(id: Int) async throws
}
