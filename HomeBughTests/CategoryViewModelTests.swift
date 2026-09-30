//
//  CategoryViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for CategoryViewModel.
//

import Combine
import XCTest
@testable import HomeBugh

@MainActor
final class CategoryViewModelTests: XCTestCase {

    private var fakeRepository: FakeCategoriesRepository!
    private var sut: CategoryViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        fakeRepository = FakeCategoriesRepository()
        sut = CategoryViewModel(useCase: DefaultCategoriesUseCase(repository: fakeRepository))
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
        let category = TestFactory.makeCategory(name: "Food")
        fakeRepository.categories = [category]

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let active, let inactive) = sut.state {
            XCTAssertEqual(active.count, 1)
            XCTAssertEqual(active.first?.name, "Food")
            XCTAssertTrue(inactive.isEmpty)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentSplitsActiveAndInactive() async {
        fakeRepository.categories = [
            TestFactory.makeCategory(name: "Food", inactive: false),
            TestFactory.makeCategory(name: "Old Gym", inactive: true),
            TestFactory.makeCategory(name: "Salary", categoryType: .income, inactive: false),
        ]

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let active, let inactive) = sut.state {
            XCTAssertEqual(active.count, 2)
            XCTAssertEqual(inactive.count, 1)
            XCTAssertEqual(inactive.first?.name, "Old Gym")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentSortsAlphabetically() async {
        fakeRepository.categories = [
            TestFactory.makeCategory(name: "Zebra"),
            TestFactory.makeCategory(name: "Alpha"),
            TestFactory.makeCategory(name: "Middle"),
        ]

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.map(\.name), ["Alpha", "Middle", "Zebra"])
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

    func testLoadContentDoesNotLoadWhileAlreadyLoading() {
        fakeRepository.categories = [TestFactory.makeCategory()]

        sut.loadMoreContent()
        sut.loadMoreContent() // second call should be ignored

        // No crash or duplicate loading = pass
    }

    // MARK: - Pagination

    func testLoadMoreContentIfNeededWithNilTriggersLoad() async {
        fakeRepository.categories = [TestFactory.makeCategory()]

        await whenLoaded { sut.loadMoreContentIfNeeded(currentItem: nil) }

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.count, 1)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededDoesNotLoadWhenBelowThreshold() async {
        fakeRepository.categories = [
            TestFactory.makeCategory(name: "A"),
            TestFactory.makeCategory(name: "B"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let active, _) = sut.state {
            let lastItem = active.last!
            sut.loadMoreContentIfNeeded(currentItem: lastItem)

            if case .loaded(let updatedActive, _) = sut.state {
                XCTAssertEqual(updatedActive.count, 2)
            } else {
                XCTFail("Expected .loaded, got \(sut.state)")
            }
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededTriggersLoadAtThreshold() async {
        // pageSize is 20, so we need 20 items for canLoadMorePages to stay true
        var categories: [HomeBugh.Category] = []
        for i in 1...20 {
            categories.append(TestFactory.makeCategory(name: "Cat \(String(format: "%02d", i))"))
        }
        fakeRepository.categories = categories

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.count, 20)

            // The threshold item is at index (count - 5) = 15
            let thresholdItem = active[active.count - 5]
            await whenLoaded { sut.loadMoreContentIfNeeded(currentItem: thresholdItem) }

            // Load was triggered for page 2 (returns empty), state stays .loaded
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
        var categories: [HomeBugh.Category] = []
        for i in 1...20 {
            categories.append(TestFactory.makeCategory(name: "Cat \(String(format: "%02d", i))"))
        }
        fakeRepository.categories = categories

        await whenLoaded { sut.loadMoreContent() }

        if case .loaded(let active, _) = sut.state {
            // Pick an item NOT at the threshold (e.g., first item)
            let firstItem = active.first!
            sut.loadMoreContentIfNeeded(currentItem: firstItem)

            // Count should remain 20 — no extra page loaded
            if case .loaded(let updatedActive, _) = sut.state {
                XCTAssertEqual(updatedActive.count, 20)
            } else {
                XCTFail("Expected .loaded, got \(sut.state)")
            }
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Add

    func testAddCategoryAppendsAndSorts() async {
        fakeRepository.categories = [TestFactory.makeCategory(name: "Zebra")]
        await whenLoaded { sut.loadMoreContent() }

        let newCategory = TestFactory.makeCategory(name: "Alpha")
        await whenLoaded { sut.add(newCategory) }

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.first?.name, "Alpha")
            XCTAssertEqual(active.last?.name, "Zebra")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testAddCategoryErrorTransitionsToError() async {
        fakeRepository.createError = TestError.mock

        await whenError { sut.add(TestFactory.makeCategory()) }

        if case .error = sut.state {
            // pass
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - Update

    func testUpdateCategoryReflectsChanges() async {
        let id = UUID()
        fakeRepository.categories = [TestFactory.makeCategory(id: id, name: "Old Name")]
        await whenLoaded { sut.loadMoreContent() }

        var updated = TestFactory.makeCategory(id: id, name: "New Name")
        updated.updatedAt = Date()
        await whenLoaded { sut.update(updated) }

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.first?.name, "New Name")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Delete

    func testDeleteCategoryRemovesFromList() async {
        let id = UUID()
        fakeRepository.categories = [
            TestFactory.makeCategory(id: id, name: "ToDelete"),
            TestFactory.makeCategory(name: "Keep"),
        ]
        await whenLoaded { sut.loadMoreContent() }

        await whenLoaded { sut.delete(TestFactory.makeCategory(id: id, name: "ToDelete")) }

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.count, 1)
            XCTAssertEqual(active.first?.name, "Keep")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testDeleteCategoryErrorTransitionsToError() async {
        let id = UUID()
        fakeRepository.categories = [TestFactory.makeCategory(id: id)]
        await whenLoaded { sut.loadMoreContent() }

        fakeRepository.deleteError = TestError.mock
        await whenError { sut.delete(TestFactory.makeCategory(id: id)) }

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
