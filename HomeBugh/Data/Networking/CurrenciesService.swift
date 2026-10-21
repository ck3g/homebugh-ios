//
//  CurrenciesService.swift
//  HomeBugh
//
//  Fetches the read-only currency list (GET /api/v1/currencies).
//

import Foundation

protocol CurrenciesServicing {
    func fetchCurrencies(token: String) async throws -> [Currency]
}

struct CurrenciesResponseDTO: Decodable {
    let currencies: [CurrencyDTO]
}

struct CurrencyDTO: Decodable {
    let id: Int
    let name: String
    let unit: String
}

final class CurrenciesService: CurrenciesServicing {

    private enum Path {
        static let currencies = "currencies"
    }

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchCurrencies(token: String) async throws -> [Currency] {
        let response: CurrenciesResponseDTO = try await httpClient.send(
            method: .get,
            path: Path.currencies,
            body: Optional<EmptyBody>.none,
            token: token
        )
        return response.currencies.map { Currency(id: $0.id, name: $0.name, unit: $0.unit) }
    }
}
