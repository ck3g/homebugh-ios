//
//  AuthState.swift
//  HomeBugh
//
//  Observable objects for auth state management.
//  TODO: Replace with proper auth when backend is available.
//

import SwiftUI

class Auth: ObservableObject {
    @Published var currentView: String = "Login"

    func setAuthView(view: String) {
        self.currentView = view
    }
}

class UserLoggedIn: ObservableObject {
    @Published var isUserLoggedIn: Bool = true  // Always logged in for offline mode

    func setUserLoggedIn(isUserLoggedIn: Bool) {
        self.isUserLoggedIn = isUserLoggedIn
    }
}
