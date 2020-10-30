//
//  AppView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/21/20.
//

import SwiftUI

struct AppView: View {
    
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    @EnvironmentObject var auth: Auth
    
    var body: some View {
        TabView {
            TransactionsView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Transactions")
                }
            
            MainView().environmentObject(auth).environmentObject(userLoggedIn)
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Settings")
                }
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
