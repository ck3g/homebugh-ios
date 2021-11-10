//
//  AccountView.swift
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

struct AccountView: View {
    @StateObject var viewModel = AccountViewModel()
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.accounts, id: \.self) { item in
                    AccountCell(account: item)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: item)
                        }
                }
            }
        }
        .navigationBarTitle(Text("Accounts"))
    }
}

var body: some View {
    ZStack {
        }
        
        if viewModel.isLoadingPage {
            ProgressView()
        }
        
        if viewModel.categoryList.isEmpty && !viewModel.isLoadingPage {
            EmptyState(imageName: "",
                       message: "The categories list is empty.")
        }
        
        if viewModel.errorMessage != "" {
            EmptyState(imageName: "",
                       message: viewModel.errorMessage)
        }
    }
    .navigationTitle("Categories")
}
}


struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView()
    }
}
