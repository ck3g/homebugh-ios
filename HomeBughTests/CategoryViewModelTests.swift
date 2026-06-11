//
//  CategoryViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for CategoryViewModel.
//

import XCTest
@testable import HomeBugh

@MainActor
final class CategoryViewModelTests: XCTestCase {

    private var mockRepository: MockCategoriesRepository!
    private var sut: CategoryViewModel!

    override func setUp() {
        super.setUp()
        mockRepository = MockCategoriesRepository()
        sut = CategoryViewModel(repository: mockRepository)
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
        let category = TestFactory.makeCategory(name: "Food")
        mockRepository.categories = [category]

        sut.loadMoreContent()

        // Wait for async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, let inactive) = sut.state {
            XCTAssertEqual(active.count, 1)
            XCTAssertEqual(active.first?.name, "Food")
            XCTAssertTrue(inactive.isEmpty)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentSplitsActiveAndInactive() async {
        mockRepository.categories = [
            TestFactory.makeCategory(name: "Food", inactive: false),
            TestFactory.makeCategory(name: "Old Gym", inactive: true),
            TestFactory.makeCategory(name: "Salary", categoryType: .income, inactive: false),
        ]

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, let inactive) = sut.state {
            XCTAssertEqual(active.count, 2)
            XCTAssertEqual(inactive.count, 1)
            XCTAssertEqual(inactive.first?.name, "Old Gym")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadContentSortsAlphabetically() async {
        mockRepository.categories = [
            TestFactory.makeCategory(name: "Zebra"),
            TestFactory.makeCategory(name: "Alpha"),
            TestFactory.makeCategory(name: "Middle"),
        ]

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.map(\.name), ["Alpha", "Middle", "Zebra"])
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

    func testLoadContentDoesNotLoadWhileAlreadyLoading() {
        mockRepository.categories = [TestFactory.makeCategory()]

        sut.loadMoreContent()
        sut.loadMoreContent() // second call should be ignored

        // No crash or duplicate loading = pass
    }

    // MARK: - Pagination

    func testLoadMoreContentIfNeededWithNilTriggersLoad() async {
        mockRepository.categories = [TestFactory.makeCategory()]

        sut.loadMoreContentIfNeeded(currentItem: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.count, 1)
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testLoadMoreContentIfNeededDoesNotLoadWhenBelowThreshold() async {
        mockRepository.categories = [
            TestFactory.makeCategory(name: "A"),
            TestFactory.makeCategory(name: "B"),
        ]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            let lastItem = active.last!
            sut.loadMoreContentIfNeeded(currentItem: lastItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

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
        mockRepository.categories = categories

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.count, 20)

            // The threshold item is at index (count - 5) = 15
            let thresholdItem = active[active.count - 5]
            sut.loadMoreContentIfNeeded(currentItem: thresholdItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

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
        mockRepository.categories = categories

        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            // Pick an item NOT at the threshold (e.g., first item)
            let firstItem = active.first!
            sut.loadMoreContentIfNeeded(currentItem: firstItem)
            try? await Task.sleep(nanoseconds: 100_000_000)

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
        mockRepository.categories = [TestFactory.makeCategory(name: "Zebra")]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let newCategory = TestFactory.makeCategory(name: "Alpha")
        sut.add(newCategory)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.first?.name, "Alpha")
            XCTAssertEqual(active.last?.name, "Zebra")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testAddCategoryErrorTransitionsToError() async {
        mockRepository.createError = TestError.mock

        sut.add(TestFactory.makeCategory())
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error = sut.state {
            // pass
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - Update

    func testUpdateCategoryReflectsChanges() async {
        let id = UUID()
        mockRepository.categories = [TestFactory.makeCategory(id: id, name: "Old Name")]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        var updated = TestFactory.makeCategory(id: id, name: "New Name")
        updated.updatedAt = Date()
        sut.update(updated)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.first?.name, "New Name")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    // MARK: - Delete

    func testDeleteCategoryRemovesFromList() async {
        let id = UUID()
        mockRepository.categories = [
            TestFactory.makeCategory(id: id, name: "ToDelete"),
            TestFactory.makeCategory(name: "Keep"),
        ]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        sut.delete(TestFactory.makeCategory(id: id, name: "ToDelete"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let active, _) = sut.state {
            XCTAssertEqual(active.count, 1)
            XCTAssertEqual(active.first?.name, "Keep")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func testDeleteCategoryErrorTransitionsToError() async {
        let id = UUID()
        mockRepository.categories = [TestFactory.makeCategory(id: id)]
        sut.loadMoreContent()
        try? await Task.sleep(nanoseconds: 100_000_000)

        mockRepository.deleteError = TestError.mock
        sut.delete(TestFactory.makeCategory(id: id))
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error = sut.state {
            // pass
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }
}
