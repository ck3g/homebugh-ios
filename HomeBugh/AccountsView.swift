//
//  AccountsView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 12/14/20.
//

import SwiftUI

struct Account: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var amount: String
}

struct AccountsView: View {
    
    private let accounts = [Account(name: "Deutsche Bank", amount: "50000 $"),
                            Account(name: "Postbank", amount: "8000 $"),
                            Account(name: "Victoria Bank", amount: "100 $")
    ]
    
    var body: some View {
            List {
                ForEach(accounts, id: \.self) { account in
                    AccountCell(account: account)
                }
            }
            .navigationBarTitle(Text("Accounts"))
    }
}

struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView()
    }
}
