//
//  ServerConfigStore.swift
//  HomeBugh
//
//  Persists the configured server base URL (not a secret, so UserDefaults is fine).
//

import Foundation

protocol ServerConfigStoring {
    var baseURL: URL? { get }
    func setBaseURL(_ url: URL?)
}

final class ServerConfigStore: ServerConfigStoring {

    private enum Constants {
        static let baseURLKey = "ServerConfig.baseURL"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var baseURL: URL? {
        guard let string = defaults.string(forKey: Constants.baseURLKey) else { return nil }
        return URL(string: string)
    }

    func setBaseURL(_ url: URL?) {
        defaults.set(url?.absoluteString, forKey: Constants.baseURLKey)
    }
}
