//
//  CategoryView.swift
//  HomeBugh
//
//  Created by Amey Sunu on 04/10/21.
//

import SwiftUI

struct CategoryView: View {

    @ObservedObject var viewModel: CategoryViewModel
    @State private var showAddCategory = false

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(viewModel: viewModel)
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadMoreContent()
            }
        }
    }
}
