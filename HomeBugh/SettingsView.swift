//
//  MainView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/10/20.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    @EnvironmentObject var auth: Auth
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AccountsView()) {
                    Text("Accounts")
                }
                
                NavigationLink(destination: CategoryView()) {
                    Text("Categories")
                }
                
                Button(action: {
                    self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: false)
                    self.auth.setAuthView(view: "Login")
                }) {
                    LogoutButton()
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct LogoutButton: View {
    var body: some View {
        Text("Logout")
            .foregroundColor(.blue)
    }
}
