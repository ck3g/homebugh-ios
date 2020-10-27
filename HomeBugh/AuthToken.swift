//
//  AuthToken.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/26/20.
//

import Foundation

struct Token: Codable {
    var token: String
}

class AuthToken {
    var token: Token
    
    private let saveKey = "AuthToken"
    
    init() {
        self.token = Token(token: "")
        if let savedToken = UserDefaults.standard.object(forKey: saveKey) as? Data {
            if let loadedToken = try? JSONDecoder().decode(Token.self, from: savedToken) {
                print(loadedToken)
                self.token = loadedToken
            }
        }
    }
    
    func setToken(token: Token) {
        self.token = token
        save()
    }
    
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(self.token) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func isValid() -> Bool {
        return !self.token.token.isEmpty
    }
}
