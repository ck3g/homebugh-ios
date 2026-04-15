//
//  ContentView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/5/20.
//

import SwiftUI

struct ContentView: View {

    @StateObject var userLoggedIn = UserLoggedIn()
    @StateObject var auth = Auth()

    var body: some View {
        // TODO: Re-enable auth flow when backend is available
        AppView().environmentObject(auth).environmentObject(userLoggedIn)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
