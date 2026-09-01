//
//  AddAccountView.swift
//  HomeBugh
//
//  Form to create or edit an account.
//

import SwiftUI

struct AddAccountView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AccountViewModel

    /// If set, we're editing; otherwise creating.
    var editingAccount: Account?

    @State private var name = ""
    @State private var selectedCurrency = 0
    @State private var showInSummary = true

    private let currencies = [
        Currency(id: 1, name: "EUR", unit: "EUR"),
        Currency(id: 2, name: "USD", unit: "USD"),
        Currency(id: 3, name: "MDL", unit: "MDL"),
        Currency(id: 4, name: "RM", unit: "RM"),
    ]

    private var isEditing: Bool { editingAccount != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name *")) {
                    TextField("Account name", text: $name)
                }

                Section(header: Text("Currency *")) {
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(0 ..< currencies.count, id: \.self) { index in
                            Text(currencies[index].name).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    // Currency cannot be changed after creation (API allows only name + show_in_summary on update).
                    .disabled(isEditing)
                }

                Section {
                    Toggle("Show in summary", isOn: $showInSummary)
                }
            }
            .navigationBarTitle(isEditing ? "Edit account" : "New account")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let account = editingAccount {
                    name = account.name
                    selectedCurrency = currencies.firstIndex { $0.id == account.currency.id } ?? 0
                    showInSummary = account.showInSummary
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if var existing = editingAccount {
            existing.name = trimmedName
            existing.showInSummary = showInSummary
            existing.updatedAt = Date()
            viewModel.update(existing)
        } else {
            let account = Account(
                name: trimmedName,
                balance: 0.0,
                currency: currencies[selectedCurrency],
                status: AccountStatus.active,
                showInSummary: showInSummary
            )
            viewModel.add(account)
        }
        dismiss()
    }
}
