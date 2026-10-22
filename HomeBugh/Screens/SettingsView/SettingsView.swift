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
    @StateObject private var syncViewModel: SyncViewModel

    @Binding var path: NavigationPath

    @State private var showLogin = false
    @State private var isLoggedIn = false

    init(path: Binding<NavigationPath>, syncViewModel: @autoclosure @escaping () -> SyncViewModel) {
        _path = path
        _syncViewModel = StateObject(wrappedValue: syncViewModel())
    }

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

                        syncRow

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
        .sheet(isPresented: $showLogin, onDismiss: {
            refreshLoginState()
            syncViewModel.refreshLastSynced()
        }) {
            LoginView(viewModel: repositoryProvider.makeLoginViewModel())
        }
        .onAppear {
            refreshLoginState()
            syncViewModel.refreshLastSynced()
        }
        .onDisappear {
            // Reset to the root menu off-screen when leaving the tab, so returning
            // shows Settings instantly with no visible pop animation.
            path = NavigationPath()
        }
    }

    @ViewBuilder
    private var syncRow: some View {
        Button {
            syncViewModel.syncNow()
        } label: {
            HStack {
                Text("Sync now")
                Spacer()
                if syncViewModel.isSyncing {
                    ProgressView()
                }
            }
        }
        .disabled(syncViewModel.isSyncing)

        if let subtitle = syncStatusSubtitle {
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var syncStatusSubtitle: String? {
        switch syncViewModel.status {
        case .syncing:
            return "Syncing…"
        case .failure(let message):
            return message
        case .success, .idle:
            if let date = syncViewModel.lastSyncedAt {
                return "Last synced \(Self.dateFormatter.string(from: date))"
            }
            return "Not synced yet"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

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
        SettingsView(
            path: .constant(NavigationPath()),
            syncViewModel: SyncViewModel(makeSyncService: { nil }, lastSyncedProvider: { nil })
        )
    }
}
