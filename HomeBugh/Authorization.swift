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
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let confirmedPassword = confirmedPassword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return isEmailValid(enteredEmail: email) && password == confirmedPassword
    }
    
    static func isEmailValid(enteredEmail: String) -> Bool {
        let emailFormat = "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
}
