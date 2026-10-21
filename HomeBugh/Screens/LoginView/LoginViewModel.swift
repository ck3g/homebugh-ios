//
//  LoginViewModel.swift
//  HomeBugh
//
//  View model for the "Connect to server" login screen.
//

import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var serverURL: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var didLogin = false

    private let authUseCase: AuthUseCase

    init(authUseCase: AuthUseCase) {
        self.authUseCase = authUseCase
    }

    var isValid: Bool {
        normalizedServerURL() != nil &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    func login() {
        guard let url = normalizedServerURL() else {
            errorMessage = "Enter a valid server URL."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authUseCase.login(
                    serverURL: url,
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                isLoading = false
                didLogin = true
            } catch {
                isLoading = false
                errorMessage = message(for: error)
            }
        }
    }

    private func normalizedServerURL() -> URL? {
        let trimmed = serverURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let url = URL(string: trimmed),
              url.scheme != nil, url.host != nil else {
            return nil
        }
        return url
    }

    private func message(for error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "Invalid email or password."
        case APIError.transport:
            return "Couldn't reach the server. Check the URL and your connection."
        case let APIError.validation(message, _):
            return message ?? "Validation failed."
        default:
            return "Login failed. Please try again."
        }
    }
}
