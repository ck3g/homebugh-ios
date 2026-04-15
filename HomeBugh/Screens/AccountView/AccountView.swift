//
//  AccountView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 12/14/20.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel

    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.items, id: \.id) { item in
                    AccountCell(account: item)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: item)
                        }
                }
            }

            if viewModel.isLoading {
                ProgressView()
            }

            if viewModel.items.isEmpty && !viewModel.isLoading {
                EmptyState(imageName: "",
                           message: "The accounts list is empty.")
            }

            if viewModel.errorMessage != "" {
                EmptyState(imageName: "",
                           message: viewModel.errorMessage)
            }
        }
        .navigationBarTitle(Text("Accounts"))
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadMoreContent()
            }
        }
    }
}
