//
//  Authentication.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/20/20.
//

import SwiftUI

let fakeEmail = "user@example.com"
let fakePassword = "password"

final class Authentication: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var token: String?
    @Published var authenticationDidSucceed: Bool = false
    @Published var user = User()
    @Published var alertItem: String = ""
    @Published var isLoading = false
    
    func loginUser(email: String, password: String, completed: @escaping (Bool) -> Void) {
        isLoading = true
        NetworkManager.shared.loginUser(email: email, password: password) { [self] (success, value) in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    self.token = value
                    self.authenticationDidSucceed = !value.isEmpty
                    AppState.CurrentUser = User(email: email, password: password, token: value)
                    AuthTokenStorage().setToken(.init(token: value))
                    completed(self.authenticationDidSucceed)
                } else {
                    alertItem = value
                    completed(false)
                }
            }
        }
    }
    
    
}
