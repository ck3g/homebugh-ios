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
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            List {
                if !viewModel.activeItems.isEmpty {
                    Section(header: Text("Active")) {
                        ForEach(viewModel.activeItems, id: \.id) { item in
                            CategoryCell(category: item)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.delete(item)
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
                                    Button(role: .destructive) {
                                        viewModel.delete(item)
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
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            if !newValue.isEmpty {
                showErrorAlert = true
            }
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadMoreContent()
            }
        }
    }
}
