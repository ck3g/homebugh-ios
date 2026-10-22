//
//  SyncService.swift
//  HomeBugh
//
//  Orchestrates a full sync: refresh currencies, push local changes, then pull
//  server changes. Exposes the outcome (including any rejected pushes).
//

import Foundation

struct SyncResult {
    let rejections: [PushedRejectedDTO]
    var hasRejections: Bool { !rejections.isEmpty }
}

protocol SyncServicing {
    func sync() async throws -> SyncResult
}

final class SyncService: SyncServicing {

    private let pushService: SyncPushService
    private let pullService: SyncPullService
    private let currenciesService: CurrenciesServicing
    private let currenciesStore: CurrenciesLocalStore
    private let metadataStore: SyncMetadataStore
    private let token: String

    init(
        pushService: SyncPushService,
        pullService: SyncPullService,
        currenciesService: CurrenciesServicing,
        currenciesStore: CurrenciesLocalStore,
        metadataStore: SyncMetadataStore,
        token: String
    ) {
        self.pushService = pushService
        self.pullService = pullService
        self.currenciesService = currenciesService
        self.currenciesStore = currenciesStore
        self.metadataStore = metadataStore
        self.token = token
    }

    func sync() async throws -> SyncResult {
        let lastSyncedAt = try metadataStore.lastSyncedAt()

        // Refresh the currency cache (best effort — a failure here shouldn't
        // block the rest of the sync; pulled accounts just won't resolve names).
        if let currencies = try? await currenciesService.fetchCurrencies(token: token) {
            try? currenciesStore.replaceAll(currencies)
        }

        // Push local changes first, then pull (the server excludes just-pushed
        // records from the pull).
        let rejections = try await pushService.push(lastSyncedAt: lastSyncedAt)
        try await pullService.pull(lastSyncedAt: lastSyncedAt)

        return SyncResult(rejections: rejections)
    }
}
