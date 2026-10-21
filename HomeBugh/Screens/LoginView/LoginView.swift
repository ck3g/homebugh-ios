//
//  LoginView.swift
//  HomeBugh
//
//  "Connect to server" screen. Lets the user enter a server URL + credentials
//  to enable sync. The app works fully offline without logging in.
//

import SwiftUI

struct LoginView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Server")) {
                    TextField("https://your-server.com", text: $viewModel.serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Credentials")) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    SecureField("Password", text: $viewModel.password)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }

                Section {
                    Button(action: { viewModel.login() }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Connect").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Connect to Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: viewModel.didLogin) { loggedIn in
                if loggedIn { dismiss() }
            }
        }
    }
}

// Shared helpers still used by the (web-only, stubbed) SignUpView.
let lightGreyColor = Color(red: 239.0 / 255.0, green: 243.0 / 255.0, blue: 244.0 / 255.0, opacity: 1.0)

struct LogoView: View {
    var body: some View {
        Text("HB")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.bottom, 50)
    }
}
