//
//  TransactionCell.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/22/20.
//

import SwiftUI

struct TransactionCell: View {
    
    var transaction: Transaction
    
    var body: some View {
        VStack {
            HStack {
                Text(Date().description)
                    .font(.footnote)
                Spacer()
                Text(String(format: "%.2f", transaction.amount))
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
        TransactionCell(transaction: Transaction(id: 0,
                                                 amount: 18.23,
                                                 comment: "Magnesium",
                                                 category: Category(id: 0, name: "Food", categoryType: CategoryType(id: 0, name: "Spending"), inactive: false),
                                                 account: Account(id: 0, name: "Deutsche Bank", balance: 100000.0, currency: Currency(id: 0, name: "Euro", unit: "Euro"), status: "active", showInSummary: true)))
    }
}
