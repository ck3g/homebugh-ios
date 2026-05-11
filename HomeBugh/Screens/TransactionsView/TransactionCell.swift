//
//  TransactionCell.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/22/20.
//

import SwiftUI

struct TransactionCell: View {
    
    var transaction: Transaction
    private let dateFormatter: DateTextFormatterProtocol = DateTextFormatter()
    private let moneyFormatter: MoneyFormatterProtocol = MoneyFormatter()
    
    var body: some View {
        VStack {
            HStack {
                Text(dateFormatter.abbreviated(transaction.createdAt))
                    .font(.footnote)
                Spacer()
                Text(moneyFormatter.format(transaction.amount, currencyUnit: transaction.account.currency.unit))
                    .foregroundColor(amountTextColor())
            }
            
            HStack {
                Text(transaction.category.name)
                Spacer()
                Text(transaction.account.name)
            }
            
            if transaction.comment != "" {
                HStack {
                    Text(transaction.comment)
                    Spacer()
                }
            }
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
    }
    
    func amountTextColor() -> Color {
        return transaction.category.categoryType.name == "Spending" ? .red : .green
    }
    
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCell(transaction: Transaction(
            amount: 18.23,
            comment: "Magnesium",
            category: Category(
                name: "Food",
                categoryType: CategoryType(id: 0, name: "Spending"),
                inactive: false
            ),
            account: Account(
                name: "Deutsche Bank",
                balance: 100000.0,
                currency: Currency(id: 0, name: "Euro", unit: "Euro"),
                status: "active",
                showInSummary: true
            )
        ))
    }
}
