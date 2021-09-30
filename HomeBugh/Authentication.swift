//
//  Authentication.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10/20/20.
//

import Foundation

let fakeEmail = "user@example.com"
let fakePassword = "password"

class Authentication {
    
    func loginUser(email: String, password: String) -> String {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//        return email == fakeEmail && password == fakePassword ? "fakeToken" : ""
        
//        if workspace.isEmpty || email.isEmpty || password.isEmpty {
//            self.view.makeToast(NSLocalizedString("Login.ErrorNotAllDataProvided", comment: ""), position: .top, style: Helper.ToastErrorStyle())
//            return
//        }
        
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
                            
                            if statusCode != 201 {
                                
                                return
                            }

                            if data == nil {
//                                self.showLoginError(errorString: NSLocalizedString("Error.ApiCallNoData", comment: ""))
                                return
                            }
                            print(String(decoding: data!, as: UTF8.self))
//                            guard let parsed = try? JSONDecoder().decode(User.self, from: data!) else {
////                                self.showLoginError(errorString: NSLocalizedString("Error.ApiCallParsingError", comment: ""))
//                                return
//                            }
//                            AppState.CurrentUser = parsed
//                            AppState.CurrentUser.password = password
//                            AppState.UserToken = parsed.userToken
                    }
                    )
                    }
                } catch {
                    DispatchQueue.main.async {
//                        self.view.makeToast(NSLocalizedString("Error.TryCatch", comment: ""), position: .top, style: Helper.ToastErrorStyle())
                    }
                }
        return "fake Token"
    }
    
}
