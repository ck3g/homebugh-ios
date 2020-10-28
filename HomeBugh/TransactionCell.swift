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
                Text(transaction.date)
                    .font(.footnote)
                Spacer()
                Text(transaction.amount)
                    .foregroundColor(amountTextColor())
            }
            
            HStack {
                Text(transaction.category)
                Spacer()
                Text(transaction.account)
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
        return transaction.categoryType == "Spending" ? .red : .green
    }
    
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCell(transaction: Transaction(date: "October 20, 2020", amount: "18,23$", category: "Sport", categoryType: "Spending", account: "Deutsche Bank", comment: "Magnesium"))
    }
}
