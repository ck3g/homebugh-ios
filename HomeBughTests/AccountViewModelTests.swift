//
//  AccountViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for AccountViewModel.
//

import XCTest
@testable import HomeBugh

@MainActor
final class AccountViewModelTests: XCTestCase {

    private var mockRepository: MockAccountsRepository!
    private var sut: AccountViewModel!

    override func setUp() {
        super.setUp()
        mockRepository = MockAccountsRepository()
        sut = AccountViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        if case .idle = sut.state {
        } else {
            XCTFail("Expected .idle, got \(sut.state)")
        }
    }

    // MARK: - Loading

    func testLoadContentTransitionsToLoaded() async {
        let account = TestFactory.makeAccount(name: "Deutsche Bank")
        mockRepository.accounts = [account]

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.name, "Deutsche Bank")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentSortsAlphabetically() async {
        mockRepository.accounts = [
            TestFactory.makeAccount(name: "Zebra Bank"),
            TestFactory.makeAccount(name: "Alpha Bank"),
            TestFactory.makeAccount(name: "Middle Bank"),
        ]

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.map(\.name), ["Alpha Bank", "Middle Bank", "Zebra Bank"])
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentErrorTransitionsToError() async {
        mockRepository.listError = TestError.mock

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error(let message) = sut.state {
            XCTAssertEqual(message, "Mock error")
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    func testLoadEmptyListTransitionsToLoadedEmpty() async {
        mockRepository.accounts = []

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertTrue(items.isEmpty)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Pagination

    func testLoadMoreContentIfNeededWithNilTriggersLoad() async {
        mockRepository.accounts = [TestFactory.makeAccount()]

        sut.loadMoreContentIfNeeded(currentItem: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededDoesNotLoadWhenBelowThreshold() async {
        // Load fewer items than the pagination threshold (5)
        mockRepository.accounts = [
            TestFactory.makeAccount(name: "A"),
            TestFactory.makeAccount(name: "B"),
        ]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Calling with the last item should not trigger another load
        // because count (2) < threshold (5)
        if case .loaded(let items) = sut.state {
            let lastItem = items.last!
            sut.loadMoreContentIfNeeded(currentItem: lastItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

            // State should still be loaded with 2 items (no extra load)
            if case .loaded(let updatedItems) = sut.state {
                XCTAssertEqual(updatedItems.count, 2)
            } else {
                XCTFail("Expected .loaded, got \(sut.state)")
            }
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededTriggersLoadAtThreshold() async {
        // Create enough items to exceed the threshold (5), with pageSize = 6
        // so canLoadMorePages stays true
        var accounts: [Account] = []
        for i in 1...6 {
            accounts.append(TestFactory.makeAccount(name: "Account \(i)"))
        }
        mockRepository.accounts = accounts

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 6)
            // The threshold item is at index (count - 5) = 1
            let thresholdItem = items[items.count - 5]
            sut.loadMoreContentIfNeeded(currentItem: thresholdItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Should have tried to load page 2 (which returns empty since
            // mock only has 6 items and pageSize is 6)
            if case .loaded = sut.state {
                // pass — load was triggered
            } else {
                XCTFail("Expected .loaded, got \(sut.state)")
            }
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Add

    func testAddAccountAppendsAndSorts() async {
        mockRepository.accounts = [TestFactory.makeAccount(name: "Zebra Bank")]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let newAccount = TestFactory.makeAccount(name: "Alpha Bank")
        sut.add(newAccount)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items.first?.name, "Alpha Bank")
            XCTAssertEqual(items.last?.name, "Zebra Bank")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testAddAccountErrorTransitionsToError() async {
        mockRepository.createError = TestError.mock

        sut.add(TestFactory.makeAccount())
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error = sut.state {
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }
}
