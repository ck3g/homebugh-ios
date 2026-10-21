//
//  SyncRequestDTO.swift
//  HomeBugh
//
//  Request payload for POST /api/v1/sync. Kept separate from domain models.
//  JSON keys are snake_cased by the encoder (configured in HTTPClient).
//

import Foundation

struct SyncRequestDTO: Encodable {
    let lastSyncedAt: Date?
    let changes: SyncChangesDTO?
}

struct SyncChangesDTO: Encodable {
    var categories: ResourceChangesDTO<CategoryCreateDTO, CategoryUpdateDTO>?
    var accounts: ResourceChangesDTO<AccountCreateDTO, AccountUpdateDTO>?
    var transactions: ResourceChangesDTO<TransactionCreateDTO, TransactionUpdateDTO>?
}

struct ResourceChangesDTO<Create: Encodable, Update: Encodable>: Encodable {
    var created: [Create]
    var updated: [Update]
    var deleted: [DeletedRefDTO]

    var isEmpty: Bool {
        created.isEmpty && updated.isEmpty && deleted.isEmpty
    }
}

/// A deleted record reference — only the server id.
struct DeletedRefDTO: Encodable {
    let id: Int
}

// MARK: - Created payloads

struct CategoryCreateDTO: Encodable {
    let clientUuid: String
    let name: String
    let categoryTypeId: Int
}

struct AccountCreateDTO: Encodable {
    let clientUuid: String
    let name: String
    let currencyId: Int
    let showInSummary: Bool
}

struct TransactionCreateDTO: Encodable {
    let clientUuid: String
    let amount: Double
    let comment: String
    let accountId: Int
    let categoryId: Int
}

// MARK: - Updated payloads

struct CategoryUpdateDTO: Encodable {
    let id: Int
    let name: String
    let inactive: Bool
    let updatedAt: Date
}

struct AccountUpdateDTO: Encodable {
    let id: Int
    let name: String
    let showInSummary: Bool
    let updatedAt: Date
}

struct TransactionUpdateDTO: Encodable {
    let id: Int
    let comment: String
    let updatedAt: Date
}
