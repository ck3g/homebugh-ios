//
//  DateTextFormatter.swift
//  HomeBugh
//
//  Locale-aware date formatting.
//

import Foundation

protocol DateTextFormatterProtocol {
    func abbreviated(_ date: Date) -> String
}

struct DateTextFormatter: DateTextFormatterProtocol {

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    func abbreviated(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
