//
//  AccountView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 12/14/20.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel
    @State private var showAddAccount = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle:
                EmptyView()

            case .loading:
                ProgressView()

            case .loaded(let accounts):
                if accounts.isEmpty {
                    EmptyState(imageName: "",
                               message: "The accounts list is empty.")
                } else {
                    List {
                        ForEach(accounts, id: \.id) { item in
                            AccountCell(account: item)
                                .onAppear {
                                    viewModel.loadMoreContentIfNeeded(currentItem: item)
                                }
                        }
                    }
                }

            case .error(let message):
                EmptyState(imageName: "",
                           message: "The accounts list is empty.")
                    .onAppear {
                        errorMessage = message
                        showErrorAlert = true
                    }
            }
        }
        .navigationBarTitle(Text("Accounts"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddAccount = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if case .idle = viewModel.state {
                viewModel.loadMoreContent()
            }
        }
    }
}
