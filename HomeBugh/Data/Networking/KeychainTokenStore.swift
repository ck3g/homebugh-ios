//
//  KeychainTokenStore.swift
//  HomeBugh
//
//  Securely stores the API bearer token in the iOS Keychain.
//

import Foundation
import Security

protocol TokenStore {
    func save(_ token: String) throws
    func read() -> String?
    func delete() throws
    var hasToken: Bool { get }
}

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
}

final class KeychainTokenStore: TokenStore {

    private let service: String
    private let account: String

    init(service: String = "info.homebugh.HomeBugh", account: String = "api-token") {
        self.service = service
        self.account = account
    }

    var hasToken: Bool {
        read() != nil
    }

    func save(_ token: String) throws {
        let data = Data(token.utf8)

        // Remove any existing item first, then add the new one.
        SecItemDelete(baseQuery() as CFDictionary)

        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func read() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
