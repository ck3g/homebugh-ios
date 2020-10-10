//
//  MainView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/10/20.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    @EnvironmentObject var auth: Auth
    
    var body: some View {
        VStack {
            Text("You are logged in")
            Button(action: {
                self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: false)
                self.auth.setAuthView(view: "Login")
            }) {
                LogoutButton()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

struct LogoutButton: View {
    var body: some View {
        Text("Logout")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.green)
            .cornerRadius(15.0)
    }
}
