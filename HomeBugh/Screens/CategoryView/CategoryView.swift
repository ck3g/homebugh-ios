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
    @State private var categoryToEdit: Category?

    var body: some View {
        ZStack {
            List {
                if !viewModel.activeItems.isEmpty {
                    Section(header: Text("Active")) {
                        ForEach(viewModel.activeItems, id: \.id) { item in
                            CategoryCell(category: item)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deactivate(item)
                                    } label: {
                                        Image(systemName: "trash")
                                    }

                                    Button {
                                        categoryToEdit = item
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.gray)
                                }
                                .onAppear {
                                    viewModel.loadMoreContentIfNeeded(currentItem: item)
                                }
                        }
                    }
                }

                if !viewModel.inactiveItems.isEmpty {
                    Section(header: Text("Inactive")) {
                        ForEach(viewModel.inactiveItems, id: \.id) { item in
                            CategoryCell(category: item)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        categoryToEdit = item
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.gray)
                                }
                        }
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
        .sheet(item: $categoryToEdit) { category in
            AddCategoryView(viewModel: viewModel, editingCategory: category)
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadMoreContent()
            }
        }
    }
}
