//
//  AddCustomExerciseView.swift
//  BeFit
//
//  Created by AI Assistant on 4/25/25.
//

import SwiftUI

struct AddCustomExerciseView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    
    @State private var exerciseName = ""
    @State private var selectedCategory: ExerciseCategory = .upperBodyPush
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases.filter { $0 != .custom }) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section {
                    Button(action: saveExercise) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Exercise")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(isSaving || exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    private func saveExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a valid exercise name."
            showingAlert = true
            return
        }
        
        // Check for duplicate name
        if viewModel.exercises.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "An exercise with this name already exists."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        viewModel.addCustomExercise(name: trimmedName, category: selectedCategory) { success in
            isSaving = false
            
            if success {
                alertMessage = "Exercise added successfully!"
            } else {
                alertMessage = "Failed to add exercise. Please try again."
            }
            
            showingAlert = true
        }
    }
}

#Preview {
    AddCustomExerciseView(viewModel: ExerciseViewModel())
} 