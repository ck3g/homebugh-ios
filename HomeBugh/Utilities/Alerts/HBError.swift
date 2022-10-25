//
//  HBError.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 24.10.2022.
//

import Foundation

enum HBError: Error {
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

extension HBError: LocalizedError {
    public var errorDescription: String? {
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
