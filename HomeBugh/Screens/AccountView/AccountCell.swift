//
//  AccountCell.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 12/14/20.
//

import SwiftUI

struct AccountCell: View {

    let account: Account
    private static let moneyFormatter: MoneyFormatterProtocol = MoneyFormatter()

    var body: some View {
        HStack {
            Text(account.name)
            Spacer()
            Text(Self.moneyFormatter.format(account.balance, currencyUnit: account.currency.unit))
        }
    }
}
