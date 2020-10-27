//
//  Authentication.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/20/20.
//

import Foundation

let fakeEmail = "user@example.com"
let fakePassword = "password"

class Authentication {
    
    func loginUser(email: String, password: String) -> String {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return email == fakeEmail && password == fakePassword ? "fakeToken" : ""
    }
    
}
