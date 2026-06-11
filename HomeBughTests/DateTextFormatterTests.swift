//
//  DateTextFormatterTests.swift
//  HomeBughTests
//
//  Unit tests for DateTextFormatter.
//

import XCTest
@testable import HomeBugh

final class DateTextFormatterTests: XCTestCase {

    private var sut: DateTextFormatter!

    override func setUp() {
        super.setUp()
        sut = DateTextFormatter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAbbreviatedReturnsNonEmptyString() {
        let date = Date()
        let result = sut.abbreviated(date)
        XCTAssertFalse(result.isEmpty)
    }

    func testAbbreviatedContainsYear() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 6, day: 15)
        let date = calendar.date(from: components)!
        let result = sut.abbreviated(date)
        XCTAssertTrue(result.contains("2025"), "Expected year in output, got: \(result)")
    }

    func testAbbreviatedDifferentDatesProduceDifferentOutput() {
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        XCTAssertNotEqual(sut.abbreviated(date1), sut.abbreviated(date2))
    }

    func testAbbreviatedSameDateProducesSameOutput() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 3, day: 10))!
        XCTAssertEqual(sut.abbreviated(date), sut.abbreviated(date))
    }

    func testAbbreviatedDoesNotContainTime() {
        let result = sut.abbreviated(Date())
        // Long date style should not contain ":" which is typical in time formatting
        XCTAssertFalse(result.contains(":"), "Expected no time component, got: \(result)")
    }
}
