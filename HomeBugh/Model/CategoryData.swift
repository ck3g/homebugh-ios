//
//  CategoryList.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 28.10.2021.
//

import Foundation

struct Category: Codable, Hashable {
    var id: Int
    var name: String
    var categoryType: CategoryType
    var inactive: Bool
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.inactive == rhs.inactive
            && lhs.categoryType == rhs.categoryType
    }
}

struct CategoryType: Codable, Hashable {
    var id: Int
    var name: String
}

struct CategoryData: Codable {
    var categories: [Category]
    var metadata: Metadata
}
