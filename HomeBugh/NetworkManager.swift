//
//  NetworkManager.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 30.09.2021.
//

import Foundation

final class NetworkManager {

    static let shared = NetworkManager()

    private init() {}

    enum Error: Swift.Error {
        case missingEmail
        case missingPassword
        case invalidEmail
        case invalidRequestData
        case missingResponseData
        case invalidResponseData
        case invalidErrorResponse
        case errorResponse
    }

    func loginUser(
        email: String,
        password: String,
        then completion: @escaping (Result<String, Error>) -> Void
    ) {
        let email = email.trimmedLowercased
        let password = password.trimmedLowercased

        guard !email.isEmpty else {
            completion(.failure(.missingEmail))
            return
        }

        guard !password.isEmpty else {
            completion(.failure(.missingPassword))
            return
        }

        guard email.isEmailValid else {
            completion(.failure(.invalidEmail))
            return
        }

        let user = User(email: email, password: password)

        guard let jsonData = try? JSONEncoder().encode(user) else {
            completion(.failure(.invalidRequestData))
            return
        }

        API.sendRequestAsync(
            url: API.Endpoints.Authentication.Url,
            method: API.Endpoints.Authentication.Method,
            autoAuth: false,
            rawData: jsonData as NSData
        ) { (error, data, dateLastModified, statusCode) in

            guard let data = data else {
                completion(.failure(.missingResponseData))
                return
            }

            let decoder = JSONDecoder()

            switch statusCode {
            case 201:
                guard let response = try? decoder.decode(HTTPRequestResultOK.self, from: data) else {
                    completion(.failure(.invalidResponseData))
                    return
                }
                completion(.success(response.token))
            default:
                guard let _ = try? decoder.decode(HTTPRequestResultError.self, from: data) else {
                    completion(.failure(.invalidErrorResponse))
                    return
                }
                completion(.failure(.errorResponse))
            }
        }
    }
}

extension NetworkManager.Error: LocalizedError {
    public var errorDescription: String? {
        // TODO: maybe, more specialized descriptions should be provided
        switch self {
        case .missingEmail, .missingPassword:
            return "Not all credentials are provided"
        case .invalidEmail:
            return "The email is invalid"
        case .invalidRequestData, .missingResponseData, .invalidResponseData:
            return "Server Error: Invalid Data"
        case .invalidErrorResponse:
            return "Server Error: Invalid Response"
        case .errorResponse:
            return "Server Error: Unauthorized"
        }
    }
}

private extension String {
    var trimmedLowercased: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
