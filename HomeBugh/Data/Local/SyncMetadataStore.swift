//
//  SyncMetadataStore.swift
//  HomeBugh
//
//  Persists the global "last synced at" timestamp used by the sync engine.
//

import Foundation
import GRDB

struct SyncMetadataRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "sync_metadata"

    var id: Int
    var lastSyncedAt: Date?
}

struct SyncMetadataStore {

    private enum Constants {
        /// The single metadata row always uses this primary key.
        static let rowId = 1
    }

    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Returns the timestamp of the last successful sync, or nil if never synced.
    func lastSyncedAt() throws -> Date? {
        try dbQueue.read { db in
            try SyncMetadataRecord.fetchOne(db, key: Constants.rowId)?.lastSyncedAt
        }
    }

    /// Stores the timestamp of the last successful sync.
    func setLastSyncedAt(_ date: Date?) throws {
        try dbQueue.write { db in
            let record = SyncMetadataRecord(id: Constants.rowId, lastSyncedAt: date)
            try record.save(db)
        }
    }
}
