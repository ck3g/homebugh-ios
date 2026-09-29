//
//  AddTransactionViewModelTests.swift
//  HomeBughTests
//
//  Unit tests for AddTransactionViewModel recency ordering and preselection.
//

import XCTest
@testable import HomeBugh

@MainActor
final class AddTransactionViewModelTests: XCTestCase {

    private var transactionsRepo: MockTransactionsRepository!
    private var accountsRepo: MockAccountsRepository!
    private var categoriesRepo: MockCategoriesRepository!
    private var recent: RecentSelectionStore!
    private var sut: AddTransactionViewModel!

    override func setUp() {
        super.setUp()
        transactionsRepo = MockTransactionsRepository()
        accountsRepo = MockAccountsRepository()
        categoriesRepo = MockCategoriesRepository()
        recent = RecentSelectionStore()
        sut = AddTransactionViewModel(
            transactionsRepository: transactionsRepo,
            accountsRepository: accountsRepo,
            categoriesRepository: categoriesRepo,
            recentSelection: recent
        )
    }

    override func tearDown() {
        sut = nil
        recent = nil
        categoriesRepo = nil
        accountsRepo = nil
        transactionsRepo = nil
        super.tearDown()
    }

    // MARK: - Preselection

    func testLoadDataPreselectsFirstAccountAndCategory() async {
        accountsRepo.accounts = [
            TestFactory.makeAccount(name: "Alpha"),
            TestFactory.makeAccount(name: "Beta"),
        ]
        categoriesRepo.categories = [
            TestFactory.makeCategory(name: "Food"),
            TestFactory.makeCategory(name: "Rent"),
        ]

        sut.loadData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.selectedAccountId, sut.accounts.first?.id)
        XCTAssertEqual(sut.selectedCategoryId, sut.categories.first?.id)
    }

    // MARK: - Recency ordering (LIFO)

    func testRecordedSelectionMovesToFrontOnNextLoad() async {
        let alpha = TestFactory.makeAccount(name: "Alpha")
        let beta = TestFactory.makeAccount(name: "Beta")
        accountsRepo.accounts = [alpha, beta]
        let food = TestFactory.makeCategory(name: "Food")
        let rent = TestFactory.makeCategory(name: "Rent")
        categoriesRepo.categories = [food, rent]

        // Simulate the user having used Beta / Rent most recently.
        recent.recordAccount(beta.id)
        recent.recordCategory(rent.id)

        sut.loadData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.accounts.first?.id, beta.id, "Most recently used account should be first")
        XCTAssertEqual(sut.categories.first?.id, rent.id, "Most recently used category should be first")
        XCTAssertEqual(sut.selectedAccountId, beta.id)
        XCTAssertEqual(sut.selectedCategoryId, rent.id)
    }

    func testSeedsRecencyFromTransactionHistory() async {
        let alpha = TestFactory.makeAccount(name: "Alpha")
        let beta = TestFactory.makeAccount(name: "Beta")
        accountsRepo.accounts = [alpha, beta]
        let food = TestFactory.makeCategory(name: "Food")
        let rent = TestFactory.makeCategory(name: "Rent")
        categoriesRepo.categories = [food, rent]

        // Newest transaction used Beta + Rent (mock returns in array order = newest first).
        transactionsRepo.transactions = [
            TestFactory.makeTransaction(category: rent, account: beta),
            TestFactory.makeTransaction(category: food, account: alpha),
        ]

        sut.loadData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.accounts.first?.id, beta.id, "Seeded recency should put latest-used account first")
        XCTAssertEqual(sut.categories.first?.id, rent.id, "Seeded recency should put latest-used category first")
    }

    func testAllItemsRemainPresentAfterOrdering() async {
        let alpha = TestFactory.makeAccount(name: "Alpha")
        let beta = TestFactory.makeAccount(name: "Beta")
        let gamma = TestFactory.makeAccount(name: "Gamma")
        accountsRepo.accounts = [alpha, beta, gamma]
        categoriesRepo.categories = [TestFactory.makeCategory(name: "Food")]

        recent.recordAccount(gamma.id)

        sut.loadData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.accounts.count, 3, "Ordering must not drop items")
        XCTAssertEqual(sut.accounts.first?.id, gamma.id)
        XCTAssertEqual(Set(sut.accounts.map { $0.id }), Set([alpha.id, beta.id, gamma.id]))
    }

    // MARK: - Same name, different currency

    func testSameNamedAccountsWithDifferentCurrenciesAreBothPresentAndDistinct() async {
        let eur = TestFactory.makeAccount(
            name: "Cash",
            currency: Currency(id: 1, name: "EUR", unit: "EUR")
        )
        let usd = TestFactory.makeAccount(
            name: "Cash",
            currency: Currency(id: 2, name: "USD", unit: "USD")
        )
        accountsRepo.accounts = [eur, usd]
        categoriesRepo.categories = [TestFactory.makeCategory(name: "Food")]

        sut.loadData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.accounts.count, 2, "Both same-named accounts must appear")
        XCTAssertEqual(eur.displayName, "Cash [EUR]")
        XCTAssertEqual(usd.displayName, "Cash [USD]")
        XCTAssertNotEqual(eur.displayName, usd.displayName, "Currency makes them distinguishable")
    }
}
