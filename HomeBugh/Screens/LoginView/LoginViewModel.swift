//
//  LoginViewModel.swift
//  HomeBugh
//
//  View model for the login screen.
//

import SwiftUI

final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var authenticationDidSucceed: Bool = false
    @Published var alertItem: String = ""
    @Published var isLoading = false

    func loginUser(completed: @escaping (Bool) -> Void) {
        // TODO: Wire to auth repository when backend is available
        // For now, always succeed (offline mode)
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.authenticationDidSucceed = true
            completed(true)
        }
    }
}
