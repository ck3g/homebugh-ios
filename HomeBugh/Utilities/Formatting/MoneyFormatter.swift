//
//  MoneyFormatter.swift
//  HomeBugh
//
//  Locale-aware money formatting.
//

import Foundation

protocol MoneyFormatterProtocol {
    func format(_ amount: Double, currencyUnit: String) -> String
}

struct MoneyFormatter: MoneyFormatterProtocol {

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    func format(_ amount: Double, currencyUnit: String) -> String {
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(currencyUnit) \(formatted)"
    }
}
