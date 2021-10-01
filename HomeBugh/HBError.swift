//
//  HBError.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 30.09.2021.
//

import Foundation

enum HBError: Error {
    case notAllCredentialsProvided
    case invalidURL
    case invalidResponse
    case invalidData
    case unableToComplete
}
