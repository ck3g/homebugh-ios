//
//  AddTransactionView.swift
//  HomeBugh
//
//  Form to create a new transaction.
//

import SwiftUI

struct AddTransactionView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AddTransactionViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account *")) {
                    if viewModel.accounts.isEmpty {
                        Text("No accounts yet. Create one in Settings.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Account", selection: $viewModel.selectedAccountId) {
                            Text("Select account").tag(nil as UUID?)
                            ForEach(viewModel.accounts, id: \.id) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Section(header: Text("Category *")) {
                    if viewModel.categories.isEmpty {
                        Text("No categories yet. Create one in Settings.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Category", selection: $viewModel.selectedCategoryId) {
                            Text("Select category").tag(nil as UUID?)
                            ForEach(viewModel.categories, id: \.id) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Section(header: Text("Amount *")) {
                    TextField("0.00", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Comment")) {
                    TextEditor(text: $viewModel.comment)
                }
            }
            .navigationBarTitle("New transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}
