//
//  AddAccountView.swift
//  HomeBugh
//
//  Form to create a new account.
//

import SwiftUI

struct AddAccountView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AccountViewModel

    @State private var name = ""
    @State private var selectedCurrency = 0
    @State private var showInSummary = true

    private let currencies = [
        Currency(id: 1, name: "EUR", unit: "EUR"),
        Currency(id: 2, name: "USD", unit: "USD"),
        Currency(id: 1, name: "MDL", unit: "MDL"),
        Currency(id: 4, name: "RM", unit: "RM"),
    ]

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
                }

                Section {
                    Toggle("Show in summary", isOn: $showInSummary)
                }
            }
            .navigationBarTitle("New account")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let account = Account(
                            name: name.trimmingCharacters(in: .whitespaces),
                            balance: 0.0,
                            currency: currencies[selectedCurrency],
                            status: "active",
                            showInSummary: showInSummary
                        )
                        viewModel.add(account)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
