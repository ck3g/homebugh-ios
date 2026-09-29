//
//  RecentSelectionStore.swift
//  HomeBugh
//
//  Tracks the most-recently-used accounts and categories for the current app
//  session, so the Add Transaction form can order pickers "recently used first"
//  (LIFO) and preselect the latest choice. In-memory only: resets on relaunch,
//  but is seeded from transaction history on first use.
//

import Foundation

protocol RecentSelectionTracking: AnyObject {
    var accountIds: [UUID] { get }
    var categoryIds: [UUID] { get }
    func recordAccount(_ id: UUID)
    func recordCategory(_ id: UUID)
    func seedIfNeeded(accountIds: [UUID], categoryIds: [UUID])
}

final class RecentSelectionStore: RecentSelectionTracking {

    private(set) var accountIds: [UUID] = []
    private(set) var categoryIds: [UUID] = []
    private var seeded = false

    func recordAccount(_ id: UUID) {
        accountIds.removeAll { $0 == id }
        accountIds.insert(id, at: 0)
    }

    func recordCategory(_ id: UUID) {
        categoryIds.removeAll { $0 == id }
        categoryIds.insert(id, at: 0)
    }

    /// Seeds recency once per session from existing data (e.g. transaction history,
    /// newest first). Only fills what hasn't already been recorded, so explicit
    /// selections made this session always take precedence.
    func seedIfNeeded(accountIds: [UUID], categoryIds: [UUID]) {
        guard !seeded else { return }
        seeded = true
        self.accountIds = merge(existing: self.accountIds, seed: accountIds)
        self.categoryIds = merge(existing: self.categoryIds, seed: categoryIds)
    }

    /// Keeps already-recorded ids first (they are more recent this session),
    /// then appends seed ids not already present.
    private func merge(existing: [UUID], seed: [UUID]) -> [UUID] {
        dedupePreservingOrder(existing + seed)
    }

    private func dedupePreservingOrder(_ ids: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        var result: [UUID] = []
        for id in ids where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }
}
