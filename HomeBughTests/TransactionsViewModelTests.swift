//
//  TransactionsViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for TransactionsViewModel.
//

import Combine
import XCTest
@testable import HomeBugh

@MainActor
final class TransactionsViewModelTests: XCTestCase {

    private var fakeRepository: FakeTransactionsRepository!
    private var sut: TransactionsViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        fakeRepository = FakeTransactionsRepository()
        sut = TransactionsViewModel(useCase: DefaultTransactionsUseCase(repository: fakeRepository))
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        fakeRepository = nil
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
        fakeRepository.transactions = [transaction]

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.amount, 10.0)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentErrorTransitionsToError() async {
        fakeRepository.listError = TestError.mock

        await whenError { sut.loadMoreContent() }

        if case .error(let message) = sut.state {
            XCTAssertEqual(message, "Mock error")
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    func testLoadEmptyListTransitionsToLoadedEmpty() async {
        fakeRepository.transactions = []

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let items) = sut.state {
            XCTAssertTrue(items.isEmpty)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Pagination

    func testLoadMoreContentIfNeededWithNilTriggersLoad() async {
        fakeRepository.transactions = [TestFactory.makeTransaction()]

        await whenLoaded { sut.loadMoreContentIfNeeded(currentItem: nil) }

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededDoesNotLoadWhenBelowThreshold() async {
        fakeRepository.transactions = [
            TestFactory.makeTransaction(amount: 1.0),
            TestFactory.makeTransaction(amount: 2.0),
        ]
        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let items) = sut.state {
            let lastItem = items.last!
            sut.loadMoreContentIfNeeded(currentItem: lastItem)

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
        fakeRepository.transactions = transactions

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 10)

            // The threshold item is at index (count - 5) = 5
            let thresholdItem = items[items.count - 5]
            await whenLoaded { sut.loadMoreContentIfNeeded(currentItem: thresholdItem) }

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
        fakeRepository.transactions = transactions

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let items) = sut.state {
            let firstItem = items.first!
            sut.loadMoreContentIfNeeded(currentItem: firstItem)

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
        fakeRepository.transactions = [older]
        await whenLoaded { sut.loadMoreContent() }

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
        fakeRepository.transactions = []
        await whenLoaded { sut.loadMoreContent() }

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
        fakeRepository.transactions = [transaction, keeper]
        await whenLoaded { sut.loadMoreContent() }

        await whenLoaded { sut.delete(transaction) }

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
        fakeRepository.transactions = [transaction]
        await whenLoaded { sut.loadMoreContent() }

        await whenLoaded { sut.delete(transaction) }

        if case .loaded(let items) = sut.state {
            XCTAssertTrue(items.isEmpty)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testDeleteTransactionErrorTransitionsToError() async {
        let id = UUID()
        let transaction = TestFactory.makeTransaction(id: id)
        fakeRepository.transactions = [transaction]
        await whenLoaded { sut.loadMoreContent() }

        fakeRepository.deleteError = TestError.mock
        await whenError { sut.delete(transaction) }

        if case .error = sut.state {
            // pass
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - Helpers

    /// Runs `action`, then waits until the view model reaches `.loaded`.
    private func whenLoaded(_ action: () -> Void, timeout: TimeInterval = 1.0) async {
        let exp = expectation(description: "loaded")
        exp.assertForOverFulfill = false
        var cancellable: AnyCancellable?
        cancellable = sut.$state.dropFirst().sink { state in
            if case .loaded = state {
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        action()
        await fulfillment(of: [exp], timeout: timeout)
        cancellable?.cancel()
    }

    /// Runs `action`, then waits until the view model reaches `.error`.
    private func whenError(_ action: () -> Void, timeout: TimeInterval = 1.0) async {
        let exp = expectation(description: "error")
        exp.assertForOverFulfill = false
        var cancellable: AnyCancellable?
        cancellable = sut.$state.dropFirst().sink { state in
            if case .error = state {
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        action()
        await fulfillment(of: [exp], timeout: timeout)
        cancellable?.cancel()
    }
}
