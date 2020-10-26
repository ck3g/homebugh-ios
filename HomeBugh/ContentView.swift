//
//  ContentView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/5/20.
//

import SwiftUI

class Auth: ObservableObject {
    var currentView: String = "Login"
    
    func setAuthView(view: String) {
        self.objectWillChange.send()
        self.currentView = view
      }
}

class UserLoggedIn: ObservableObject {
    var isUserLoggedIn: Bool = AuthToken().isValid()
    
    func setUserLoggedIn(isUserLoggedIn: Bool) {
        self.objectWillChange.send()
        self.isUserLoggedIn = isUserLoggedIn
      }
}

struct ContentView: View {
    
    @ObservedObject var userLoggedIn = UserLoggedIn()
    @ObservedObject var auth = Auth()
    
    var body: some View {
        ZStack {
            if self.userLoggedIn.isUserLoggedIn {
                AppView().environmentObject(auth).environmentObject(userLoggedIn)
            } else {
                if self.auth.currentView == "Login" {
                    LoginView().environmentObject(auth).environmentObject(userLoggedIn)
                } else {
                    SignUpView().environmentObject(auth).environmentObject(userLoggedIn)
                }
                
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Auth()).environmentObject(UserLoggedIn())
    }
}
