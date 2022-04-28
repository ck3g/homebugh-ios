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
        case unableToComplete
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
    
    func getCategoriesList(
        pageSize: Int,
        page: Int,
        then completion: @escaping (Result<CategoryData, Error>) -> Void
    ) {
        API.sendRequestAsync(
            url: API.Endpoints.Categories.Url,
            method: API.Endpoints.Categories.Method,
            autoAuth: false,
            parameters: ["page_size": "\(pageSize)", "page": "\(page)"],
            headers: ["Authorization": "Bearer \(AuthTokenStorage().getToken())"]
        ) { (error, data, dateLastModified, statusCode) in
            
            if let _ = error {
                completion(.failure(.unableToComplete))
                return
            }
            
            guard statusCode == 200 else {
                completion(.failure(.invalidResponseData))
                return
            }
            
            guard let data = data else {
                completion(.failure(.missingResponseData))
                return
            }
            
//            print(String(decoding: data, as: UTF8.self))
            
            do  {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedResponse = try decoder.decode(CategoryData.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print(error)
                completion(.failure(.invalidResponseData))
            }
        }
    }
    
    func getAccountsList(
        pageSize: Int,
        page: Int,
        then completion: @escaping (Result<AccountData, Error>) -> Void
    ) {
        API.sendRequestAsync(
            url: API.Endpoints.Accounts.Url,
            method: API.Endpoints.Accounts.Method,
            autoAuth: false,
            parameters: ["page_size": "\(pageSize)", "page": "\(page)"],
            headers: ["Authorization": "Bearer \(AuthTokenStorage().getToken())"]
        ) { (error, data, dateLastModified, statusCode) in
            
            if let _ = error {
                completion(.failure(.unableToComplete))
                return
            }
            
            guard statusCode == 200 else {
                completion(.failure(.invalidResponseData))
                return
            }
            
            guard let data = data else {
                completion(.failure(.missingResponseData))
                return
            }
            
//            print(String(decoding: data, as: UTF8.self))
            
            do  {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedResponse = try decoder.decode(AccountData.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print(error)
                completion(.failure(.invalidResponseData))
            }
        }
    }
    
}

extension NetworkManager.Error: LocalizedError {
    public var errorDescription: String? {
        // TODO: maybe, more specialized descriptions should be provided
        switch self {
        case .unableToComplete:
            return "Server Error: Unable to complete your request at this time. Please check your internet connection."
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
