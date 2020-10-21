//
//  Authentication.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/20/20.
//

import Foundation

class Authentication {
    
    var storedEmail: String = "user@example.com"
    var storedPassword: String = "password"
    
    func loginUser(email: String, password: String) -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return email == self.storedEmail && password == self.storedPassword
    }
}
