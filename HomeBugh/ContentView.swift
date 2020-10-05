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

struct ContentView: View {
    
    @State var isUserLoggedIn: Bool = false
    @ObservedObject var auth = Auth()
    
    var body: some View {
        ZStack {
            if isUserLoggedIn {
                Text("Logged in")
            } else {
                if self.auth.currentView == "Login" {
                    LoginView().environmentObject(auth)
                } else {
                    SignUpView().environmentObject(auth)
                }
                
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Auth())
    }
}
