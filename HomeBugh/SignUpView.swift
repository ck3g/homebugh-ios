//
//  SignUpView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/2/20.
//

import SwiftUI

struct SignUpView: View {
    
    @State var email: String = ""
    @State var password: String = ""
    @State var passwordConfirmation: String = ""
    
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
            SecureField("Password confirmation", text: $passwordConfirmation)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Text("Sign up")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 220, height: 60)
                .background(Color.green)
                .cornerRadius(15.0)
            Text("Sign in")
                .font(.headline)
                .foregroundColor(.green)
                .padding()
                .frame(width: 220, height: 60)
                .background(Color.white)
        }
        .padding()
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
