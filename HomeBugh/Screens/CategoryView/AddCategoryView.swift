//
//  AddCategoryView.swift
//  HomeBugh
//
//  Form to create a new category.
//

import SwiftUI

struct AddCategoryView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CategoryViewModel

    @State private var name = ""
    @State private var selectedType = 0
    @State private var inactive = false

    private let categoryTypes = ["Spending", "Income"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name *")) {
                    TextField("Category name", text: $name)
                }

                Section(header: Text("Category type *")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(0 ..< categoryTypes.count, id: \.self) {
                            Text(categoryTypes[$0]).tag($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Toggle("Inactive", isOn: $inactive)
                }
            }
            .navigationBarTitle("New category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let category = Category(
                            name: name.trimmingCharacters(in: .whitespaces),
                            categoryType: CategoryType(
                                id: selectedType,
                                name: categoryTypes[selectedType]
                            ),
                            inactive: inactive
                        )
                        viewModel.add(category)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
