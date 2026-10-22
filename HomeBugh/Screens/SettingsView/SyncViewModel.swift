//
//  SyncViewModel.swift
//  HomeBugh
//
//  Drives the manual "Sync now" control and status display in Settings.
//

import SwiftUI

@MainActor
final class SyncViewModel: ObservableObject {

    enum Status: Equatable {
        case idle
        case syncing
        case success(rejections: Int)
        case failure(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var lastSyncedAt: Date?

    private let makeSyncService: () -> SyncServicing?
    private let lastSyncedProvider: () -> Date?

    init(
        makeSyncService: @escaping () -> SyncServicing?,
        lastSyncedProvider: @escaping () -> Date?
    ) {
        self.makeSyncService = makeSyncService
        self.lastSyncedProvider = lastSyncedProvider
        self.lastSyncedAt = lastSyncedProvider()
    }

    var isSyncing: Bool {
        if case .syncing = status { return true }
        return false
    }

    func refreshLastSynced() {
        lastSyncedAt = lastSyncedProvider()
    }

    func syncNow() {
        guard let service = makeSyncService(), !isSyncing else { return }
        status = .syncing

        Task {
            do {
                let result = try await service.sync()
                status = .success(rejections: result.rejections.count)
                lastSyncedAt = lastSyncedProvider()
            } catch {
                status = .failure(message(for: error))
            }
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "Session expired. Please reconnect."
        case APIError.transport:
            return "Couldn't reach the server."
        case APIError.rateLimited:
            return "Too many requests. Try again shortly."
        default:
            return "Sync failed. Please try again."
        }
    }
}
