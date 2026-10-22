//
//  AppView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct AppView: View {

    @EnvironmentObject var repositoryProvider: RepositoryProvider
    @Environment(\.scenePhase) private var scenePhase

    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView {
            TransactionsView(viewModel: repositoryProvider.makeTransactionsViewModel())
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Transactions")
                }

            SettingsView(
                path: $settingsPath,
                syncViewModel: repositoryProvider.makeSyncViewModel()
            )
            .tabItem {
                Image(systemName: "square.and.pencil")
                Text("Settings")
            }
        }
        .task {
            await syncIfConnected()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await syncIfConnected() }
            }
        }
    }

    /// Triggers a background sync when connected to a server (best effort).
    private func syncIfConnected() async {
        guard let service = repositoryProvider.makeSyncService() else { return }
        _ = try? await service.sync()
    }
}
