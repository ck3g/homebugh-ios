//
//  AppState.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 30.03.2021.
//

import Foundation

class AppState {
    
    static var CurrentUser: User {
        get {
            if let loadedData =  UserDefaults.standard.object(forKey: "AppState.CurrentUser") as? Data {
                if let decodedData = try? JSONDecoder().decode(User.self, from: loadedData) {
                    return decodedData
                }
                return  User()// ***
            }
            else {
                return User() // ***
            }
        }
        set {
            if let encodedData = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encodedData, forKey: "AppState.CurrentUser")
            }
            else {
                // ***
                if let encodedData = try? JSONEncoder().encode(User()) {
                    UserDefaults.standard.set(encodedData, forKey: "AppState.CurrentUser")
                }
                // TODO: check was ist wenn nil????
            }
        }
    }
    
}
