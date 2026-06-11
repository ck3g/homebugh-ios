//
//  TransactionsViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for TransactionsViewModel.
//

import XCTest
@testable import HomeBugh

@MainActor
final class TransactionsViewModelTests: XCTestCase {

    private var mockRepository: MockTransactionsRepository!
    private var sut: TransactionsViewModel!

    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionsRepository()
        sut = TransactionsViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        if case .idle = sut.state {
            // pass
        } else {
            XCTFail("Expected .idle, got \(sut.state)")
        }
    }

    // MARK: - Loading

    func testLoadContentTransitionsToLoaded() async {
        let transaction = TestFactory.makeTransaction(amount: 10.0)
        mockRepository.transactions = [transaction]

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.amount, 10.0)
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
        mockRepository.transactions = []

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
        mockRepository.transactions = [TestFactory.makeTransaction()]

        sut.loadMoreContentIfNeeded(currentItem: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededDoesNotLoadWhenBelowThreshold() async {
        mockRepository.transactions = [
            TestFactory.makeTransaction(amount: 1.0),
            TestFactory.makeTransaction(amount: 2.0),
        ]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            let lastItem = items.last!
            sut.loadMoreContentIfNeeded(currentItem: lastItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

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
        // pageSize is 10, so we need 10 items for canLoadMorePages to stay true
        var transactions: [Transaction] = []
        for i in 1...10 {
            transactions.append(TestFactory.makeTransaction(amount: Double(i)))
        }
        mockRepository.transactions = transactions

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 10)

            // The threshold item is at index (count - 5) = 5
            let thresholdItem = items[items.count - 5]
            sut.loadMoreContentIfNeeded(currentItem: thresholdItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

            if case .loaded = sut.state {
                // pass — pagination was triggered
            } else {
                XCTFail("Expected .loaded after pagination, got \(sut.state)")
            }
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededDoesNotTriggerBeforeThreshold() async {
        var transactions: [Transaction] = []
        for i in 1...10 {
            transactions.append(TestFactory.makeTransaction(amount: Double(i)))
        }
        mockRepository.transactions = transactions

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let items) = sut.state {
            let firstItem = items.first!
            sut.loadMoreContentIfNeeded(currentItem: firstItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

            if case .loaded(let updatedItems) = sut.state {
                XCTAssertEqual(updatedItems.count, 10)
            } else {
                XCTFail("Expected .loaded, got \(sut.state)")
            }
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Add

    func testAddTransactionInsertsAtTop() async {
        let older = TestFactory.makeTransaction(amount: 1.0)
        mockRepository.transactions = [older]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let newer = TestFactory.makeTransaction(amount: 99.0)
        sut.add(newer)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items.first?.amount, 99.0, "New transaction should be at top")
            XCTAssertEqual(items.last?.amount, 1.0)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testAddTransactionToEmptyList() async {
        mockRepository.transactions = []
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let transaction = TestFactory.makeTransaction(amount: 50.0)
        sut.add(transaction)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.amount, 50.0)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Delete

    func testDeleteTransactionRemovesFromList() async {
        let id = UUID()
        let transaction = TestFactory.makeTransaction(id: id, amount: 10.0)
        let keeper = TestFactory.makeTransaction(amount: 20.0)
        mockRepository.transactions = [transaction, keeper]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        sut.delete(transaction)

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.amount, 20.0)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testDeleteLastTransactionResultsInEmptyLoaded() async {
        let id = UUID()
        let transaction = TestFactory.makeTransaction(id: id)
        mockRepository.transactions = [transaction]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        sut.delete(transaction)

        if case .loaded(let items) = sut.state {
            XCTAssertTrue(items.isEmpty)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }
}
