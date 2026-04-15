//
//  AppView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct AppView: View {

    @EnvironmentObject var repositoryProvider: RepositoryProvider
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    @EnvironmentObject var auth: Auth

    var body: some View {
        TabView {
            TransactionsView(viewModel: TransactionsViewModel(
                repository: repositoryProvider.transactionsRepository()
            ))
            .tabItem {
                Image(systemName: "list.dash")
                Text("Transactions")
            }

            SettingsView().environmentObject(auth).environmentObject(userLoggedIn)
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Settings")
                }
        }
    }
}
