import Foundation

protocol ListTransactionsUseCase {
    func execute(page: Int, pageSize: Int) async throws -> [Transaction]
}

protocol CreateTransactionUseCase {
    func execute(_ transaction: Transaction) async throws
}

protocol UpdateTransactionUseCase {
    func execute(_ transaction: Transaction) async throws
}

protocol DeleteTransactionUseCase {
    func execute(id: UUID) async throws
}
