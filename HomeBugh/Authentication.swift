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

    @EnvironmentObject var userLoggedIn: UserLoggedIn
    
    func loginUser(email: String, password: String) {
        isLoading = true
        NetworkManager.shared.loginUser(email: email, password: password) { [self] (success, value) in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    self.token = value
                    self.authenticationDidSucceed = !value.isEmpty
                    AppState.CurrentUser = User(email: email, password: password, token: value)
//                    Authentication().environmentObject(self.userLoggedIn)
//                    self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: authenticationDidSucceed)
                } else {
                    alertItem = value
                }
//                switch result {
//                case .success(let token):
//                    self.token = token
//                    self.authenticationDidSucceed = !token.isEmpty
//                    AppState.CurrentUser = User(email: email, password: password, token: token)
//                    self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: authenticationDidSucceed)
//                case .failure(let error):
//                    self.authenticationDidSucceed = false
//                    switch error {
//                    case .notAllCredentialsProvided:
//                        alertItem = "Not all credentials are provided"
//
//                    case .invalidResponse:
//                        alertItem = "AlertContext.invalidResponse"
//
//                    case .invalidURL:
//                        alertItem = "AlertContext.invalidURL"
//
//                    case .invalidData:
//                        alertItem = "AlertContext.invalidData"
//
//                    case .unableToComplete:
//                        alertItem = "AlertContext.unableToComplete"
//                    }
//                }
            }
        }
    }
    
    
}
