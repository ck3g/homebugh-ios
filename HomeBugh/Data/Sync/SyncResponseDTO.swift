//
//  SyncResponseDTO.swift
//  HomeBugh
//
//  Response payload for POST /api/v1/sync. JSON keys are snake_case, decoded
//  with .convertFromSnakeCase (configured in HTTPClient).
//

import Foundation

struct SyncResponseDTO: Decodable {
    let pushed: PushedDTO?
    let pull: PullDTO?
}

// MARK: - Pushed

struct PushedDTO: Decodable {
    let categories: PushedResourceDTO?
    let accounts: PushedResourceDTO?
    let transactions: PushedResourceDTO?
}

struct PushedResourceDTO: Decodable {
    var created: [PushedCreatedDTO]?
    var updated: [PushedUpdatedDTO]?
    var deleted: [PushedDeletedDTO]?
    var rejected: [PushedRejectedDTO]?
}

struct PushedCreatedDTO: Decodable {
    let clientUuid: String
    let serverId: Int
    let status: String
}

struct PushedUpdatedDTO: Decodable {
    let id: Int
    let status: String
}

struct PushedDeletedDTO: Decodable {
    let id: Int
    let status: String
}

struct PushedRejectedDTO: Decodable {
    let clientUuid: String?
    let id: Int?
    let operation: String
    let reason: String
}

// MARK: - Pull

struct PullDTO: Decodable {
    let categories: [PulledCategoryDTO]?
    let accounts: [PulledAccountDTO]?
    let transactions: [PulledTransactionDTO]?
    let deletions: [PulledDeletionDTO]?
    let hasMore: Bool
    let cursor: Date?
}

struct PulledCategoryDTO: Decodable {
    let id: Int
    let name: String
    let categoryTypeId: Int
    let inactive: Bool
    let status: String
    let clientUuid: String?
    let createdAt: Date
    let updatedAt: Date
}

struct PulledAccountDTO: Decodable {
    let id: Int
    let name: String
    let balance: Double
    let currencyId: Int
    let status: String
    let showInSummary: Bool
    let clientUuid: String?
    let createdAt: Date
    let updatedAt: Date
}

struct PulledTransactionDTO: Decodable {
    let id: Int
    let amount: Double
    let comment: String
    let accountId: Int
    let categoryId: Int
    let clientUuid: String?
    let createdAt: Date
    let updatedAt: Date
}

struct PulledDeletionDTO: Decodable {
    let resourceType: String
    let resourceId: Int
    let deletedAt: Date
}
