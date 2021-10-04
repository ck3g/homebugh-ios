//
//  String+Ext.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 30.03.2021.
//

import Foundation

extension String {
    
    var isEmailValid: Bool {
        let emailFormat         = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate      = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
}
