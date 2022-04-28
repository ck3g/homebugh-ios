//
//  AccountView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 12/14/20.
//

import SwiftUI

struct AccountView: View {
    @StateObject var viewModel = AccountViewModel()
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.accountList, id: \.self) { item in
                    AccountCell(account: item)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: item)
                        }
                }
            }
            
            if viewModel.isLoadingPage {
                ProgressView()
            }
            
            if viewModel.accountList.isEmpty && !viewModel.isLoadingPage {
                EmptyState(imageName: "",
                           message: "The categories list is empty.")
            }
            
            if viewModel.errorMessage != "" {
                EmptyState(imageName: "",
                           message: viewModel.errorMessage)
            }
        }
        .navigationBarTitle(Text("Accounts"))
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
