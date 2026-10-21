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

    @Binding var path: NavigationPath

    @State private var showLogin = false
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink("Accounts", value: Destination.accounts)
                    NavigationLink("Categories", value: Destination.categories)
                }

                Section(header: Text("Server")) {
                    if isLoggedIn {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Button(role: .destructive) {
                            disconnect()
                        } label: {
                            Text("Disconnect")
                        }
                    } else {
                        Button("Connect to Server") {
                            showLogin = true
                        }
                    }
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
        .sheet(isPresented: $showLogin, onDismiss: refreshLoginState) {
            LoginView(viewModel: repositoryProvider.makeLoginViewModel())
        }
        .onAppear(perform: refreshLoginState)
        .onDisappear {
            // Reset to the root menu off-screen when leaving the tab, so returning
            // shows Settings instantly with no visible pop animation.
            path = NavigationPath()
        }
    }

    private func refreshLoginState() {
        isLoggedIn = repositoryProvider.isLoggedIn
    }

    private func disconnect() {
        Task {
            try? await repositoryProvider.authUseCase().logout()
            refreshLoginState()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(path: .constant(NavigationPath()))
    }
}
