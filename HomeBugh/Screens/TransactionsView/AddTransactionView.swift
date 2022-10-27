//
//  AddTransaction.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/29/20.
//

import SwiftUI

struct AddTransactionView: View {
    
    @State private var date = Date()
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    @State private var selectedAccount = 0
    @State private var accounts = ["Deutsche Bank", "Postbank", "Cash (Euro)"]
    @State private var selectedCategory = 0
    @State private var categories = ["Food", "Sport", "Cafe and restaurants", "Daughter"]
    @State private var amount = "0.0"
    @State private var comment = ""
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var transactions: Transactions
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    Picker(selection: $selectedAccount, label: Text(accounts[selectedAccount])) {
                        ForEach(0 ..< accounts.count) {
                            Text(self.accounts[$0]).tag($0)
                        }
                    }.pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Category")) {
                    Picker(selection: $selectedCategory, label: Text(categories[selectedCategory])) {
                        ForEach(0 ..< categories.count) {
                            Text(self.categories[$0]).tag($0)
                        }
                    }.pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amount)
                }
                
                Section(header: Text("Comment")) {
                    TextEditor(text: $comment)
                }
                
            }
            .navigationBarTitle("New transaction")
            .navigationBarItems(
                trailing: Button("Save") {
                    let transaction = Transaction(id: 3,
                                                  amount: amount,
                                                  comment: comment,
                                                  category: Category(id: 0, name: categories[selectedCategory], categoryType: CategoryType(id: 0, name: "Spending"), inactive: false),
                                                  account: Account(id: 0, name: accounts[selectedAccount], balance: 100000.0, currency: Currency(id: 0, name: "Euro", unit: "Euro"), status: "active", showInSummary: true))
                    self.transactions.items.append(transaction)
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AddTransaction_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView(transactions: Transactions())
    }
}
