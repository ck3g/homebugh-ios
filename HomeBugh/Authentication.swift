//
//  Authentication.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/20/20.
//

import SwiftUI

final class Authentication: ObservableObject {
    
    @Published var email: String = AppState.CurrentUser.email
    @Published var password: String = AppState.CurrentUser.password
    @Published var token: String?
    @Published var authenticationDidSucceed: Bool = false
    @Published var user = User()
    @Published var alertItem: String = ""
    @Published var isLoading = false
    
    func loginUser(email: String, password: String, completed: @escaping (Bool) -> Void) {
        isLoading = true
        NetworkManager.shared.loginUser(
            email: email,
            password: password
        ) { [weak self] result in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case let .success(token):
                    self.token = token
                    self.authenticationDidSucceed = !token.isEmpty
                    AppState.CurrentUser = User(email: email, password: password)
                    AuthTokenStorage().setToken(.init(token: token))
                    completed(self.authenticationDidSucceed)
                case let .failure(error):
                    self.alertItem = error.localizedDescription
                    completed(false)
                }
            }
        }
    }
    
    
}
