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
    
    @EnvironmentObject var auth: Auth
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    
    @State var registrationDidSucceed: Bool = true
    
    var body: some View {
        VStack {
            LogoView()
            SUEmailTextField(email: $email)
            SUPasswordTextField(password: $password)
            SUPasswordConfirmationTextField(passwordConfirmation: $passwordConfirmation)
            if !registrationDidSucceed {
                Text("Invalid credentials")
                    .offset(y: -10)
                    .foregroundColor(.red)
            }
            Button(action: {
                self.registrationDidSucceed = Authorization.registerNewUser(email: self.email, password: self.password, confirmedPassword: self.passwordConfirmation)
                if self.registrationDidSucceed {
                    self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: true)
                }
            }) {
                RegisterButton()
            }
            Button(action: { self.auth.setAuthView(view: "Login") }) {
                SignInButton()
            }
        }
        .padding()
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

struct SignInButton: View {
    var body: some View {
        Text("Sign in")
            .font(.headline)
            .foregroundColor(.green)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.white)
    }
}

struct RegisterButton: View {
    var body: some View {
        Text("Sign up")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.green)
            .cornerRadius(15.0)
    }
}

struct SUEmailTextField: View {
    @Binding var email: String
    var body: some View {
        TextField("Email", text: $email)
            .padding()
            .background(lightGreyColor)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
            .keyboardType(.emailAddress)
    }
}

struct SUPasswordTextField: View {
    @Binding var password: String
    var body: some View {
        SecureField("Password", text: $password)
            .padding()
            .background(lightGreyColor)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
    }
}

struct SUPasswordConfirmationTextField: View {
    @Binding var passwordConfirmation: String
    var body: some View {
        SecureField("Password", text: $passwordConfirmation)
            .padding()
            .background(lightGreyColor)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
    }
}
