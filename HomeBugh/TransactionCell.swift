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
                    .padding()
                Text(transaction.amount)
                    .padding()
            }
            HStack {
                Text(transaction.category)
                    .padding()
                Text(transaction.account)
                    .padding()
            }
            if transaction.comment != "" {
                Text(transaction.comment)
                    .padding()
            }
        }
        
    }
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCell(transaction: Transaction(date: "October 20, 2020", amount: "18,23$", category: "Sport", account: "Deutsche Bank", comment: "Magnesium"))
    }
}
