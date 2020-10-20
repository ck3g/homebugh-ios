//
//  Authorization.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/20/20.
//

import Foundation

class Authorization {
    static func registerNewUser(email: String, password: String, confirmedPassword: String) -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmedPassword = confirmedPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        if isEmailValid(enteredEmail: email) && password == confirmedPassword {
            return true
        } else {
            return false
        }
    }
    
    static func isEmailValid(enteredEmail: String) -> Bool {
        let emailFormat = "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
}
