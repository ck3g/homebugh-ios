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
    
    @State var registrationDidFail: Bool = false
    @State var registrationDidSucceed: Bool = true
    
    var body: some View {
        VStack {
            LogoView()
            SUEmailTextField(email: $email)
            SUPasswordTextField(password: $password)
            SUPasswordConfirmationTextField(passwordConfirmation: $passwordConfirmation)
            if registrationDidFail {
                Text("Invalid credentials")
                    .offset(y: -10)
                    .foregroundColor(.red)
            }
            Button(action: {
                let email = self.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let password = self.password.trimmingCharacters(in: .whitespacesAndNewlines)
                let confirmedPassword = self.passwordConfirmation.trimmingCharacters(in: .whitespacesAndNewlines)
                if isEmailValid(enteredEmail: email) && password == confirmedPassword {
                    self.registrationDidSucceed = true
                    self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: true)
                } else {
                    self.registrationDidFail = true
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
    
    func isEmailValid(enteredEmail: String) -> Bool {
        let emailFormat = "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
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
