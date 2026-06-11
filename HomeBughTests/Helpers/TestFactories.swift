//
//  TestFactories.swift
//  HomeBughTests
//
//  Convenience factory methods for creating test domain models.
//

import Foundation
@testable import HomeBugh

enum TestFactory {

    // MARK: - Category

    static func makeCategory(
        id: UUID = UUID(),
        name: String = "Food",
        categoryType: CategoryType = .expense,
        inactive: Bool = false
    ) -> HomeBugh.Category {
        HomeBugh.Category(
            id: id,
            name: name,
            categoryType: categoryType,
            inactive: inactive
        )
    }

    // MARK: - Account

    static func makeAccount(
        id: UUID = UUID(),
        name: String = "Deutsche Bank",
        balance: Double = 1000.0,
        currency: Currency = Currency(id: 1, name: "EUR", unit: "EUR"),
        status: String = AccountStatus.active,
        showInSummary: Bool = true
    ) -> Account {
        Account(
            id: id,
            name: name,
            balance: balance,
            currency: currency,
            status: status,
            showInSummary: showInSummary
        )
    }

    // MARK: - Transaction

    static func makeTransaction(
        id: UUID = UUID(),
        amount: Double = 25.50,
        comment: String = "",
        category: HomeBugh.Category? = nil,
        account: Account? = nil,
        createdAt: Date = Date()
    ) -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            comment: comment,
            category: category ?? makeCategory(),
            account: account ?? makeAccount(),
            createdAt: createdAt
        )
    }
}
