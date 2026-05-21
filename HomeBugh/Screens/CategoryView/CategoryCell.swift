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
            Image(systemName: category.categoryType.isExpense
                  ? "arrow.down"
                  : "arrow.up")
                .foregroundColor(category.categoryType.isExpense
                                 ? .red
                                 : .green)
                .font(.footnote)

            Text(category.name)
                .foregroundColor(category.inactive ? .gray : .primary)
        }
    }
}
