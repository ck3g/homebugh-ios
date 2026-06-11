//
//  MoneyFormatterTests.swift
//  HomeBughTests
//
//  Unit tests for MoneyFormatter.
//

import XCTest
@testable import HomeBugh

final class MoneyFormatterTests: XCTestCase {

    private var sut: MoneyFormatter!

    override func setUp() {
        super.setUp()
        sut = MoneyFormatter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - format

    func testFormatPrefixesCurrencyUnit() {
        let result = sut.format(10.0, currencyUnit: "EUR")
        XCTAssertTrue(result.hasPrefix("EUR "), "Expected 'EUR ' prefix, got: \(result)")
    }

    func testFormatZeroAmount() {
        let result = sut.format(0.0, currencyUnit: "$")
        XCTAssertTrue(result.hasPrefix("$ "), "Expected '$ ' prefix, got: \(result)")
        XCTAssertTrue(result.contains("0"), "Expected zero in output, got: \(result)")
    }

    func testFormatNegativeAmount() {
        let result = sut.format(-50.25, currencyUnit: "USD")
        XCTAssertTrue(result.hasPrefix("USD "), "Expected 'USD ' prefix, got: \(result)")
    }

    func testFormatTwoDecimalPlaces() {
        let result = sut.format(1.5, currencyUnit: "EUR")
        // Should have exactly 2 decimal places: "1.50" or "1,50" depending on locale
        let numberPart = result.replacingOccurrences(of: "EUR ", with: "")
        let decimalSeparators = CharacterSet(charactersIn: ".,")
        let parts = numberPart.components(separatedBy: decimalSeparators)
        XCTAssertEqual(parts.count, 2, "Expected decimal separator in: \(numberPart)")
        XCTAssertEqual(parts.last?.count, 2, "Expected 2 decimal places in: \(numberPart)")
    }

    func testFormatLargeAmount() {
        let result = sut.format(1_000_000.99, currencyUnit: "EUR")
        XCTAssertTrue(result.hasPrefix("EUR "), "Expected 'EUR ' prefix, got: \(result)")
    }

    // MARK: - parse

    func testParseValidNumber() {
        let result = sut.parse("10")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 10.0, accuracy: 0.001)
    }

    func testParseInvalidString() {
        let result = sut.parse("abc")
        XCTAssertNil(result)
    }

    func testParseEmptyString() {
        let result = sut.parse("")
        XCTAssertNil(result)
    }

    func testParseDecimalNumber() {
        let result = sut.parse("42.75")
        // Might fail on locales using comma as decimal separator,
        // so also try comma variant
        if let result = result {
            XCTAssertEqual(result, 42.75, accuracy: 0.001)
        } else {
            let commaResult = sut.parse("42,75")
            XCTAssertNotNil(commaResult, "Expected to parse either '42.75' or '42,75'")
        }
    }

    func testParseZero() {
        let result = sut.parse("0")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 0.0, accuracy: 0.001)
    }

    func testParseNegativeNumber() {
        let result = sut.parse("-10")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, -10.0, accuracy: 0.001)
    }

    // MARK: - Round-trip

    func testFormatThenParseRoundTrips() {
        let original = 42.75
        let formatted = sut.format(original, currencyUnit: "EUR")
        let numberPart = formatted.replacingOccurrences(of: "EUR ", with: "")
        let parsed = sut.parse(numberPart)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed!, original, accuracy: 0.001)
    }

    // MARK: - placeholder

    func testPlaceholderContainsZero() {
        let placeholder = sut.placeholder
        XCTAssertTrue(placeholder.contains("0"), "Expected '0' in placeholder, got: \(placeholder)")
    }

    func testPlaceholderIsNotEmpty() {
        XCTAssertFalse(sut.placeholder.isEmpty)
    }

    func testPlaceholderHasTwoDecimalPlaces() {
        let placeholder = sut.placeholder
        let decimalSeparators = CharacterSet(charactersIn: ".,")
        let parts = placeholder.components(separatedBy: decimalSeparators)
        XCTAssertEqual(parts.count, 2, "Expected decimal separator in: \(placeholder)")
        XCTAssertEqual(parts.last?.count, 2, "Expected 2 decimal places in: \(placeholder)")
    }
}
