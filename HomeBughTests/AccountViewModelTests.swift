//
//  AccountViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for AccountViewModel.
//

import Combine
import XCTest
@testable import HomeBugh

@MainActor
final class AccountViewModelTests: XCTestCase {

    private var fakeRepository: FakeAccountsRepository!
    private var sut: AccountViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        fakeRepository = FakeAccountsRepository()
        sut = AccountViewModel(useCase: DefaultAccountsUseCase(repository: fakeRepository))
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
        } else {
            XCTFail("Expected .idle, got \(sut.state)")
        }
    }

    // MARK: - Loading

    func testLoadContentTransitionsToLoaded() async {
        let account = TestFactory.makeAccount(name: "Deutsche Bank")
        fakeRepository.accounts = [account]

        await whenLoaded { sut.loadMoreContent() }

        let items = loadedItems()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Deutsche Bank")
    }

    func testLoadContentSortsAlphabetically() async {
        fakeRepository.accounts = [
            TestFactory.makeAccount(name: "Zebra Bank"),
            TestFactory.makeAccount(name: "Alpha Bank"),
            TestFactory.makeAccount(name: "Middle Bank"),
        ]

        await whenLoaded { sut.loadMoreContent() }

        XCTAssertEqual(loadedItems().map(\.name), ["Alpha Bank", "Middle Bank", "Zebra Bank"])
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
        fakeRepository.accounts = []

        await whenLoaded { sut.loadMoreContent() }

        XCTAssertTrue(loadedItems().isEmpty)
    }

    // MARK: - Pagination

    func testLoadMoreContentIfNeededWithNilTriggersLoad() async {
        fakeRepository.accounts = [TestFactory.makeAccount()]

        await whenLoaded { sut.loadMoreContentIfNeeded(currentItem: nil) }

        XCTAssertEqual(loadedItems().count, 1)
    }

    func testLoadMoreContentIfNeededDoesNotLoadWhenBelowThreshold() async {
        // Load fewer items than the pagination threshold (5)
        fakeRepository.accounts = [
            TestFactory.makeAccount(name: "A"),
            TestFactory.makeAccount(name: "B"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        // Calling with the last item should not trigger another load
        // because count (2) < threshold (5)
        let lastItem = loadedItems().last
        sut.loadMoreContentIfNeeded(currentItem: lastItem)

        // State should still be loaded with 2 items (no extra load)
        XCTAssertEqual(loadedItems().count, 2)
    }

    func testLoadMoreContentIfNeededTriggersLoadAtThreshold() async {
        // Create enough items to exceed the threshold (5), with pageSize = 6
        // so canLoadMorePages stays true
        var accounts: [Account] = []
        for i in 1...6 {
            accounts.append(TestFactory.makeAccount(name: "Account \(i)"))
        }
        fakeRepository.accounts = accounts

        await whenLoaded { sut.loadMoreContent() }

        let items = loadedItems()
        XCTAssertEqual(items.count, 6)
        // The threshold item is at index (count - 5) = 1
        let thresholdItem = items[items.count - 5]
        await whenLoaded { sut.loadMoreContentIfNeeded(currentItem: thresholdItem) }

        // Load was triggered and completed (mock only has 6 items, pageSize 6).
        if case .loaded = sut.state {} else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Add

    func testAddAccountAppendsAndSorts() async {
        fakeRepository.accounts = [TestFactory.makeAccount(name: "Zebra Bank")]
        await whenLoaded { sut.loadMoreContent() }

        let newAccount = TestFactory.makeAccount(name: "Alpha Bank")
        await whenLoaded { sut.add(newAccount) }

        let items = loadedItems()
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first?.name, "Alpha Bank")
        XCTAssertEqual(items.last?.name, "Zebra Bank")
    }

    func testAddAccountErrorTransitionsToError() async {
        fakeRepository.createError = TestError.mock

        await whenError { sut.add(TestFactory.makeAccount()) }

        if case .error = sut.state {} else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - Update

    func testUpdateAccountReflectsChanges() async {
        let id = UUID()
        fakeRepository.accounts = [TestFactory.makeAccount(id: id, name: "Old Name")]
        await whenLoaded { sut.loadMoreContent() }

        var updated = TestFactory.makeAccount(id: id, name: "New Name")
        updated.updatedAt = Date()
        await whenLoaded { sut.update(updated) }

        XCTAssertEqual(loadedItems().first?.name, "New Name")
    }

    func testUpdateAccountReSortsList() async {
        let id = UUID()
        fakeRepository.accounts = [
            TestFactory.makeAccount(id: id, name: "Alpha Bank"),
            TestFactory.makeAccount(name: "Middle Bank"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        var updated = TestFactory.makeAccount(id: id, name: "Zebra Bank")
        updated.updatedAt = Date()
        await whenLoaded { sut.update(updated) }

        XCTAssertEqual(loadedItems().map(\.name), ["Middle Bank", "Zebra Bank"])
    }

    func testUpdateAccountErrorTransitionsToError() async {
        let id = UUID()
        fakeRepository.accounts = [TestFactory.makeAccount(id: id)]
        await whenLoaded { sut.loadMoreContent() }

        fakeRepository.updateError = TestError.mock
        await whenError { sut.update(TestFactory.makeAccount(id: id, name: "New Name")) }

        if case .error = sut.state {} else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - Delete

    func testDeleteAccountRemovesFromList() async {
        let id = UUID()
        fakeRepository.accounts = [
            TestFactory.makeAccount(id: id, name: "ToDelete"),
            TestFactory.makeAccount(name: "Keep"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        await whenLoaded { sut.delete(TestFactory.makeAccount(id: id, name: "ToDelete")) }

        let items = loadedItems()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Keep")
    }

    func testDeleteAccountErrorTransitionsToError() async {
        let id = UUID()
        fakeRepository.accounts = [TestFactory.makeAccount(id: id)]
        await whenLoaded { sut.loadMoreContent() }

        fakeRepository.deleteError = TestError.mock
        await whenError { sut.delete(TestFactory.makeAccount(id: id)) }

        if case .error = sut.state {} else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - Refresh

    func testRefreshReflectsUpdatedData() async {
        let id = UUID()
        fakeRepository.accounts = [TestFactory.makeAccount(id: id, name: "Postbank", balance: 0.0)]
        await whenLoaded { sut.loadMoreContent() }

        // Simulate a balance change made elsewhere (e.g. a transaction).
        fakeRepository.accounts = [TestFactory.makeAccount(id: id, name: "Postbank", balance: 1450.0)]
        await whenLoaded { sut.refresh() }

        let items = loadedItems()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.balance ?? 0, 1450.0, accuracy: 0.01)
    }

    func testRefreshDoesNotDuplicateItems() async {
        fakeRepository.accounts = [
            TestFactory.makeAccount(name: "Alpha Bank"),
            TestFactory.makeAccount(name: "Beta Bank"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        await whenLoaded { sut.refresh() }

        XCTAssertEqual(loadedItems().count, 2, "Refresh should reset the list, not append duplicates")
    }

    func testRefreshReflectsDeletedAccount() async {
        fakeRepository.accounts = [
            TestFactory.makeAccount(name: "Alpha Bank"),
            TestFactory.makeAccount(name: "Beta Bank"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        // Account removed elsewhere.
        fakeRepository.accounts = [TestFactory.makeAccount(name: "Alpha Bank")]
        await whenLoaded { sut.refresh() }

        XCTAssertEqual(loadedItems().map(\.name), ["Alpha Bank"])
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

    /// Returns the items from the current `.loaded` state, or fails.
    private func loadedItems(file: StaticString = #filePath, line: UInt = #line) -> [Account] {
        guard case .loaded(let items) = sut.state else {
            XCTFail("Expected .loaded, got \(sut.state)", file: file, line: line)
            return []
        }
        return items
    }
}
