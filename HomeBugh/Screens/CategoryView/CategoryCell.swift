//
//  CategoryCell.swift
//  HomeBugh
//
//  Row view for a single category in the list.
//

import SwiftUI

struct CategoryCell: View {

    let category: Category

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.categoryType.name == "Spending"
                  ? "arrow.down"
                  : "arrow.up")
                .foregroundColor(category.categoryType.name == "Spending"
                                 ? .red
                                 : .green)
                .font(.footnote)

            Text(category.name)
                .foregroundColor(category.inactive ? .gray : .primary)
        }
    }
}
