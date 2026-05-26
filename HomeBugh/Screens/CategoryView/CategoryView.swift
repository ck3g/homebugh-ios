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
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle:
                EmptyView()

            case .loading:
                ProgressView()

            case .loaded(let active, let inactive):
                if active.isEmpty && inactive.isEmpty {
                    EmptyState(imageName: "",
                               message: "The categories list is empty.")
                } else {
                    List {
                        if !active.isEmpty {
                            Section(header: Text("Active")) {
                                ForEach(active, id: \.id) { item in
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

                        if !inactive.isEmpty {
                            Section(header: Text("Inactive")) {
                                ForEach(inactive, id: \.id) { item in
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
                }

            case .error(let message):
                EmptyState(imageName: "",
                           message: "The categories list is empty.")
                    .onAppear {
                        errorMessage = message
                        showErrorAlert = true
                    }
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
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if case .idle = viewModel.state {
                viewModel.loadMoreContent()
            }
        }
    }
}
