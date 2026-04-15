//
//  CategoryView.swift
//  HomeBugh
//
//  Created by Amey Sunu on 04/10/21.
//

import SwiftUI

struct CategoryView: View {

    @ObservedObject var viewModel: CategoryViewModel

    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.items, id: \.id) { item in
                    Text(item.name)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: item)
                        }
                }
            }

            if viewModel.isLoading {
                ProgressView()
            }

            if viewModel.items.isEmpty && !viewModel.isLoading {
                EmptyState(imageName: "",
                           message: "The categories list is empty.")
            }

            if viewModel.errorMessage != "" {
                EmptyState(imageName: "",
                           message: viewModel.errorMessage)
            }
        }
        .navigationTitle("Categories")
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadMoreContent()
            }
        }
    }
}
