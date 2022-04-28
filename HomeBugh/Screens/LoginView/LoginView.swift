//
//  LoginView.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/2/20.
//

import SwiftUI

let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)

struct LoginView: View {
    
    @EnvironmentObject var auth: Auth
    @EnvironmentObject var userLoggedIn: UserLoggedIn
    @StateObject var viewModel = Authentication()
    
    var body: some View {
        VStack {
            LogoView()
            EmailTextField(email: $viewModel.email)
            PasswordTextField(password: $viewModel.password)
            if !viewModel.authenticationDidSucceed {
                Text(viewModel.alertItem)
                    .offset(y: -10)
                    .foregroundColor(.red)
            }
            Button(action: {
                hideKeyboard()
                viewModel.loginUser(email: viewModel.email, password: viewModel.password) { success in
                    if success {
                        self.userLoggedIn.setUserLoggedIn(isUserLoggedIn: viewModel.authenticationDidSucceed)
                    }
                }
            }) {
                LoginButton()
            }
            Button(action: {
                    hideKeyboard()
                    self.auth.setAuthView(view: "SignUp") }) {
                SignUpButton()
            }
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

struct SignUpButton: View {
    var body: some View {
        Text("Sign up")
            .font(.headline)
            .foregroundColor(.green)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.white)
    }
}

struct LoginButton: View {
    var body: some View {
        Text("Sign in")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.green)
            .cornerRadius(15.0)
    }
}

struct EmailTextField: View {
    @Binding var email: String
    var body: some View {
        TextField("Email", text: $email)
            .padding()
            .background(lightGreyColor)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .modifier(ClearButton(text: $email))
    }
}

struct PasswordTextField: View {
    @Binding var password: String
    var body: some View {
        SecureField("Password", text: $password)
            .padding()
            .background(lightGreyColor)
            .cornerRadius(5.0)
            .padding(.bottom, 20)
            .modifier(ClearButton(text: $password))
    }
}

struct ClearButton: ViewModifier {
    @Binding var text: String
    
    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content
            
            if !text.isEmpty {
                Button(action: { self.text = "" })
                {
                    Image(systemName: "delete.left")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                }
                .padding(.trailing, 8)
                .padding(.bottom, 16)
            }
        }
    }
}

