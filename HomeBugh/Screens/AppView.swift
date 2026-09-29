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

    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView {
            TransactionsView(viewModel: repositoryProvider.makeTransactionsViewModel())
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Transactions")
                }

            SettingsView(path: $settingsPath)
                .environmentObject(auth)
                .environmentObject(userLoggedIn)
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Settings")
                }
        }
    }
}
