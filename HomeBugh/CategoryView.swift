//
//  CategoryView.swift
//  HomeBugh
//
//  Created by Amey Sunu on 04/10/21.
//

import SwiftUI

struct Category: Identifiable, Hashable {
    var id = UUID()
    var category: String
}

struct CategoryView: View {
    private let categoryValue = [Category(category: "Food and Drinks"), Category(category: "Shopping"), Category(category: "Sports and Games"), Category(category: "Apparels and Accessories")]
    var body: some View {
        List {
            ForEach(categoryValue, id: \.self){ item in
                Text(item.category)
            }
        }
        .navigationTitle("Categories")
    }
}

struct CategoryView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryView()
    }
}
