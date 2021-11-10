//
//  AccountCell.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 12/14/20.
//

import SwiftUI

struct AccountCell: View {
    
    var account: Account
    
    var body: some View {
        HStack {
            Text(account.name)
            Spacer()
            Text(String(account.balance) + " " + account.currency.unit)
        }
    }
}
