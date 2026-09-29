//
//  MainView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/10/20.
//

import SwiftUI

struct SettingsView: View {

    enum Destination: Hashable {
        case accounts
        case categories
    }

    @EnvironmentObject var repositoryProvider: RepositoryProvider
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    @EnvironmentObject var auth: Auth

    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink("Accounts", value: Destination.accounts)
                NavigationLink("Categories", value: Destination.categories)

                Button(action: {
                    self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: false)
                    self.auth.setAuthView(view: "Login")
                }) {
                    LogoutButton()
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .accounts:
                    AccountView(viewModel: repositoryProvider.makeAccountViewModel())
                case .categories:
                    CategoryView(viewModel: repositoryProvider.makeCategoryViewModel())
                }
            }
        }
        .onDisappear {
            // Reset to the root menu off-screen when leaving the tab, so returning
            // shows Settings instantly with no visible pop animation.
            path = NavigationPath()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(path: .constant(NavigationPath()))
    }
}

struct LogoutButton: View {
    var body: some View {
        Text("Logout")
            .foregroundColor(.blue)
    }
}
