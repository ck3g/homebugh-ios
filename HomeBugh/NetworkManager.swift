//
//  NetworkManager.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 30.09.2021.
//

import UIKit
import Foundation

final class NetworkManager {
    
    static let shared = NetworkManager()
    
    private init() {}
    
    func loginUser(email: String, password: String, completed: @escaping (Bool, String) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if email.isEmpty || password.isEmpty {
            completed(false, "Not all credentials are provided")
            return
        }
        
        // pre-set username+password in model to make autoAuth working:
        AppState.CurrentUser.email = email
        AppState.CurrentUser.password = password
        
        let appUserLoginRequestData = User(email: email, password: password)
        
        do {
            let jsonData = try JSONEncoder().encode(appUserLoginRequestData)
            DispatchQueue.main.async {
                _ = API.sendRequestAsync(
                    url: API.Endpoints.Authentication.Url,
                    method: API.Endpoints.Authentication.Method,
                    autoAuth: false,
                    rawData: jsonData as NSData,
                    completionHandler: {
                        (error, data, dateLastModified, statusCode) in
                        if let _ = error {
                            completed(false, "Server Error: Unable To Complete")
                            return
                        }
                        
                        guard statusCode == 201 else {
                            completed(false, "Server Error: Invalid Response")
                            return
                        }
                        
                        guard let data = data else {
                            completed(false, "Server Error: Invalid Data")
                            return
                        }
                        // print(String(decoding: data, as: UTF8.self))
                        do {
                            let decoder = JSONDecoder()
                            let decodedResponse = try decoder.decode(HTTPRequestResultOK.self, from: data)
                            completed(true, decodedResponse.token)
                        } catch {
                            completed(false, "Server Error: Invalid Data")
                        }
                    }
                )
            }
        } catch {
            completed(false, "Server Error: Invalid Data")
            return
        }
    }
}
