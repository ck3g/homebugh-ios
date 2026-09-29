//
//  RecentSelectionStoreTests.swift
//  HomeBughTests
//
//  Unit tests for RecentSelectionStore recency logic.
//

import XCTest
@testable import HomeBugh

final class RecentSelectionStoreTests: XCTestCase {

    private var sut: RecentSelectionStore!

    override func setUp() {
        super.setUp()
        sut = RecentSelectionStore()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func testStartsEmpty() {
        XCTAssertTrue(sut.accountIds.isEmpty)
        XCTAssertTrue(sut.categoryIds.isEmpty)
    }

    // MARK: - Record

    func testRecordAccountInsertsAtFront() {
        let a = UUID(), b = UUID()
        sut.recordAccount(a)
        sut.recordAccount(b)

        XCTAssertEqual(sut.accountIds, [b, a], "Most recent should be first")
    }

    func testRecordAccountMovesExistingToFrontWithoutDuplicating() {
        let a = UUID(), b = UUID(), c = UUID()
        sut.recordAccount(a)
        sut.recordAccount(b)
        sut.recordAccount(c)
        sut.recordAccount(a) // re-use the oldest

        XCTAssertEqual(sut.accountIds, [a, c, b], "Re-used id moves to front, no duplicates")
        XCTAssertEqual(sut.accountIds.count, 3)
    }

    func testRecordCategoryInsertsAtFront() {
        let a = UUID(), b = UUID()
        sut.recordCategory(a)
        sut.recordCategory(b)

        XCTAssertEqual(sut.categoryIds, [b, a])
    }

    // MARK: - Seeding

    func testSeedPopulatesWhenEmpty() {
        let a = UUID(), b = UUID()
        let x = UUID(), y = UUID()
        sut.seedIfNeeded(accountIds: [a, b], categoryIds: [x, y])

        XCTAssertEqual(sut.accountIds, [a, b])
        XCTAssertEqual(sut.categoryIds, [x, y])
    }

    func testSeedRunsOnlyOnce() {
        let first = UUID()
        let second = UUID()
        sut.seedIfNeeded(accountIds: [first], categoryIds: [])
        sut.seedIfNeeded(accountIds: [second], categoryIds: []) // ignored

        XCTAssertEqual(sut.accountIds, [first], "Second seed must be ignored")
    }

    func testSeedDoesNotClobberRecordedSelections() {
        let recorded = UUID()
        let seeded = UUID()
        sut.recordAccount(recorded)
        sut.seedIfNeeded(accountIds: [seeded], categoryIds: [])

        // Recorded stays first (more recent), seeded appended after.
        XCTAssertEqual(sut.accountIds, [recorded, seeded])
    }

    func testSeedMergeDeduplicatesAgainstRecorded() {
        let shared = UUID()
        let other = UUID()
        sut.recordAccount(shared)
        sut.seedIfNeeded(accountIds: [shared, other], categoryIds: [])

        XCTAssertEqual(sut.accountIds, [shared, other], "No duplicate of the shared id")
        XCTAssertEqual(sut.accountIds.count, 2)
    }

    func testSeedDeduplicatesWithinSeedInput() {
        let a = UUID(), b = UUID()
        sut.seedIfNeeded(accountIds: [a, b, a, b], categoryIds: [])

        XCTAssertEqual(sut.accountIds, [a, b], "Duplicate seed ids collapse, order preserved")
    }
}
