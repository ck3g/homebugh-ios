//
//  AddCategoryView.swift
//  HomeBugh
//
//  Form to create or edit a category.
//

import SwiftUI

struct AddCategoryView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CategoryViewModel

    /// If set, we're editing; otherwise creating.
    var editingCategory: Category?

    @State private var name = ""
    @State private var selectedType = 0
    @State private var inactive = false

    private let categoryTypes = ["Spending", "Income"]

    private var isEditing: Bool { editingCategory != nil }

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
            .navigationBarTitle(isEditing ? "Edit category" : "New category")
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
                if let category = editingCategory {
                    name = category.name
                    selectedType = categoryTypes.firstIndex(of: category.categoryType.name) ?? 0
                    inactive = category.inactive
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let type = CategoryType(id: selectedType, name: categoryTypes[selectedType])

        if var existing = editingCategory {
            existing.name = trimmedName
            existing.categoryType = type
            existing.inactive = inactive
            existing.updatedAt = Date()
            viewModel.update(existing)
        } else {
            let category = Category(
                name: trimmedName,
                categoryType: type,
                inactive: inactive
            )
            viewModel.add(category)
        }
        dismiss()
    }
}
