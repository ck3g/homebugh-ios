//
//  LoginView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/2/20.
//

import SwiftUI

let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)

struct LoginView: View {
    
    @State var email: String = ""
    @State var password: String = ""
    
    var body: some View {
        VStack {
            LogoView()
            TextField("Email", text: $email)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $password)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Text("Sign in")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 220, height: 60)
                .background(Color.green)
                .cornerRadius(15.0)
            Text("Sign up")
                .font(.headline)
                .foregroundColor(.green)
                .padding()
                .frame(width: 220, height: 60)
                .background(Color.white)
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

struct LogoView: View {
    var body: some View {
        Text("HB")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.bottom, 50)
    }
}
