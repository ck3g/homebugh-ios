//
//  AccountViewModel.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 10.11.2021.
//

import SwiftUI

final class AccountViewModel: ObservableObject {
    @Published var pageSize: Int = 6
    @Published private var page: Int = 1
    @Published var accountList: [Account] = []
    @Published var isLoadingPage = false
    @Published var errorMessage: String = ""
    @Published private var canLoadMorePages = true
    
    init() {
        loadMoreContent()
    }
    
    func loadMoreContentIfNeeded(currentItem item: Account?) {
        guard let item = item else {
            loadMoreContent()
            return
        }
        
        let thresholdIndex = accountList.index(accountList.endIndex, offsetBy: -5)
        if accountList.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }
    
    private func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else {
            return
        }
        
        isLoadingPage = true
        
        NetworkManager.shared.getAccountsList(
            pageSize: pageSize,
            page: page
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingPage = false
                switch result {
                case .success(let accountList):
                    self.accountList = self.accountList + accountList.accounts
                    self.canLoadMorePages = accountList.metadata.currentPage < accountList.metadata.lastPage
                    self.page += 1
                    
                case .failure (let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
}

