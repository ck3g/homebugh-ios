//
//  CategoryViewModel.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 21.10.2021.
//

import SwiftUI

final class CategoryViewModel: ObservableObject {
    @Published var pageSize: Int = 6
    @Published private var page: Int = 1
    @Published var categoryList: [Category] = []
    @Published var isLoadingPage = false
    @Published var errorMessage: String = ""
    @Published private var canLoadMorePages = true
    
    init() {
        loadMoreContent()
    }
    
    func loadMoreContentIfNeeded(currentItem item: Category?) {
        guard let item = item else {
            loadMoreContent()
            return
        }
        
        let thresholdIndex = categoryList.index(categoryList.endIndex, offsetBy: -5)
        if categoryList.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }
    
    private func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else {
            return
        }
        
        isLoadingPage = true
        
        NetworkManager.shared.getCategoriesList(
            pageSize: pageSize,
            page: page
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingPage = false
                switch result {
                case .success(let categoryList):
                    self.categoryList = self.categoryList + categoryList.categories
                    self.canLoadMorePages = categoryList.metadata.currentPage < categoryList.metadata.lastPage
                    self.page += 1
                    
                case .failure (let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
}
