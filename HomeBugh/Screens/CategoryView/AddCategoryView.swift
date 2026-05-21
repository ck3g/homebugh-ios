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
    @State private var selectedType: CategoryType = .expense
    @State private var inactive = false

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
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Text(type.name).tag(type)
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
                    selectedType = category.categoryType
                    inactive = category.inactive
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if var existing = editingCategory {
            existing.name = trimmedName
            existing.categoryType = selectedType
            existing.inactive = inactive
            existing.updatedAt = Date()
            viewModel.update(existing)
        } else {
            let category = Category(
                name: trimmedName,
                categoryType: selectedType,
                inactive: inactive
            )
            viewModel.add(category)
        }
        dismiss()
    }
}
