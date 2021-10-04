//
//  AuthToken.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/26/20.
//

import Foundation

struct Token: Codable {
    let token: String
}

protocol UnderlyingStorage {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

final class AuthTokenStorage {
    private var token: Token?

    private let storage: UnderlyingStorage
    private let tokenKey = "AuthToken"

    init(_ storage: UnderlyingStorage = UserDefaults.standard) {
        self.storage = storage
        self.token = loadToken()
    }

    func setToken(_ token: Token) {
        self.token = token
        saveToken()
    }

    func checkToken() -> Bool {
        token != nil
    }

    private func saveToken() {
        guard let data = try? JSONEncoder().encode(token) else {
            return
        }
        storage.set(data, forKey: tokenKey)
    }

    private func loadToken() -> Token? {
        guard let data = storage.object(forKey: tokenKey) as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(Token.self, from: data)
    }
}

extension UserDefaults: UnderlyingStorage {}
