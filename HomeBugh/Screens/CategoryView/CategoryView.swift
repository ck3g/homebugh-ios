//
//  CategoryView.swift
//  HomeBugh
//
//  Created by Amey Sunu on 04/10/21.
//

import SwiftUI

struct CategoryView: View {
    
    @StateObject var viewModel = CategoryViewModel()
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.categoryList, id: \.self){ item in
                    Text(item.name)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: item)
                        }
                }
            }
            
            if viewModel.isLoadingPage {
                ProgressView()
            }
            
            if viewModel.categoryList.isEmpty && !viewModel.isLoadingPage {
                EmptyState(imageName: "",
                           message: "The categories list is empty.")
            }
            
            if viewModel.errorMessage != "" {
                EmptyState(imageName: "",
                           message: viewModel.errorMessage)
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
