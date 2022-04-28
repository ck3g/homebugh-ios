//
//  HTTPRequestResult.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 08.04.2021.
//

import Foundation

struct HTTPRequestResultOK: Codable {
    let result: String
    let token: String
}

struct HTTPRequestResultError: Codable {
    let error: Err
    
    struct Err: Codable {
        let token: String
    }
}
