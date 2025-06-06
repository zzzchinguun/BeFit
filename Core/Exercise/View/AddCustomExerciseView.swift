//
//  AddCustomExerciseView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 4/25/25.
//

import SwiftUI

struct ModernAddCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExerciseViewModel
    @StateObject private var languageManager = LanguageManager.shared
    @State private var exerciseName = ""
    @State private var exerciseDescription = ""
    @State private var exerciseInstructions = ""
    @State private var selectedCategory: ExerciseCategory = .compound
    @State private var nameIsFocused = false
    @State private var descriptionIsFocused = false
    @State private var instructionsIsFocused = false
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private var isFormValid: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text(languageManager.isEnglishLanguage ? "Add Custom Exercise" : "Өөрийн дасгал нэмэх")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(languageManager.isEnglishLanguage ? "Enter exercise details to add to your custom exercise library" : "Дасгалын дэлгэрэнгүй мэдээллийг оруулаад өөрийн дасгалын санд нэмээрэй")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top)
                    
                    // Form
                    VStack(spacing: 24) {
                        // Exercise name
                        ModernFormSection(title: languageManager.isEnglishLanguage ? "Exercise Name" : "Дасгалын нэр", isRequired: true) {
                            ModernTextField(
                                text: $exerciseName,
                                placeholder: languageManager.isEnglishLanguage ? "Enter exercise name..." : "Дасгалын нэр оруулах...",
                                isFocused: $nameIsFocused,
                                icon: "dumbbell.fill"
                            )
                        }
                        
                        // Category selection
                        ModernFormSection(title: languageManager.isEnglishLanguage ? "Category" : "Ангилал", isRequired: true) {
                            CategorySelectionView(selectedCategory: $selectedCategory)
                        }
                        
                        // Description (optional)
                        ModernFormSection(title: languageManager.isEnglishLanguage ? "Description" : "Тайлбар", isRequired: false) {
                            ModernTextEditor(
                                text: $exerciseDescription,
                                placeholder: languageManager.isEnglishLanguage ? "Brief exercise description..." : "Дасгалын товч тайлбар...",
                                isFocused: $descriptionIsFocused,
                                minHeight: 80
                            )
                        }
                        
                        // Instructions (optional)
                        ModernFormSection(title: languageManager.isEnglishLanguage ? "Instructions" : "Заавар", isRequired: false) {
                            ModernTextEditor(
                                text: $exerciseInstructions,
                                placeholder: languageManager.isEnglishLanguage ? "Exercise instructions..." : "Дасгал хийх заавар...",
                                isFocused: $instructionsIsFocused,
                                minHeight: 120
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Save button
                    VStack(spacing: 16) {
                        Button(action: saveExercise) {
                            HStack(spacing: 12) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                
                                Text(isSaving ? (languageManager.isEnglishLanguage ? "Saving..." : "Хадгалж байна...") : (languageManager.isEnglishLanguage ? "Save Exercise" : "Дасгал хадгалах"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: isFormValid ? 
                                        [Color.blue, Color.blue.opacity(0.8)] : 
                                        [Color.gray, Color.gray.opacity(0.8)]
                                    ),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                        }
                        .disabled(!isFormValid || isSaving)
                        .scaleEffect(isFormValid ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
                        
                        Text(languageManager.isEnglishLanguage ? "Required fields are marked with *" : "Барилгагүй талбарууд заавал биш")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.isEnglishLanguage ? "Cancel" : "Цуцлах") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.isEnglishLanguage ? "Save" : "Хадгалах") {
                        saveExercise()
                    }
                    .foregroundColor(isFormValid ? .blue : .gray)
                    .disabled(!isFormValid || isSaving)
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("амжилттай") {
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
            alertMessage = languageManager.isEnglishLanguage ? "Please enter a valid exercise name." : "Дасгалын зөв нэр оруулна уу."
            showingAlert = true
            return
        }
        
        // Check for duplicate name
        if viewModel.exercises.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = languageManager.isEnglishLanguage ? "An exercise with this name already exists." : "Ийм нэртэй дасгал өмнө бүртгэгдсэн байна."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        viewModel.addCustomExercise(name: trimmedName, category: selectedCategory) { success in
            DispatchQueue.main.async {
                isSaving = false
                
                if success {
                    alertMessage = languageManager.isEnglishLanguage ? "Exercise added successfully!" : "Дасгал амжилттай нэмэгдлээ!"
                } else {
                    alertMessage = languageManager.isEnglishLanguage ? "Failed to add exercise. Please try again." : "Дасгал нэмэхэд алдаа гарлаа. Дахин оролдоно уу."
                }
                
                showingAlert = true
            }
        }
    }
}

// MARK: - Supporting Views

struct ModernFormSection<Content: View>: View {
    let title: String
    let isRequired: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            content()
        }
    }
}

struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    let icon: String?
    
    init(text: Binding<String>, placeholder: String, isFocused: Binding<Bool>, icon: String? = nil) {
        self._text = text
        self.placeholder = placeholder
        self._isFocused = isFocused
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFocused ? .blue : .gray)
                    .frame(width: 24)
            }
            
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                isFocused = editing
            })
            .font(.body)
            .autocapitalization(.words)
            .disableAutocorrection(false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .stroke(isFocused ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ModernTextEditor: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    let minHeight: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.clear)
                .onTapGesture {
                    isFocused = true
                }
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .stroke(isFocused ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CategorySelectionView: View {
    @Binding var selectedCategory: ExerciseCategory
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(ExerciseCategory.allCases.filter { $0 != .custom }, id: \.self) { category in
                CategoryOptionCard(
                    category: category,
                    isSelected: selectedCategory == category,
                    onTap: {
                        selectedCategory = category
                    }
                )
            }
        }
    }
}

struct CategoryOptionCard: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: categoryIcon(for: category))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : categoryColor(for: category))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? categoryColor(for: category) : categoryColor(for: category).opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(categoryDescription(for: category))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: ExerciseCategory) -> String {
        switch category {
        case .compound: return "figure.strengthtraining.traditional"
        case .lowerBody: return "figure.highintensity.intervaltraining"
        case .upperBodyPush: return "dumbbell.fill"
        case .upperBodyPull: return "figure.play"
        case .core: return "figure.core.training"
        case .custom: return "plus.circle.fill"
        }
    }
    
    private func categoryColor(for category: ExerciseCategory) -> Color {
        switch category {
        case .compound: return .blue
        case .lowerBody: return .green
        case .upperBodyPush: return .orange
        case .upperBodyPull: return .purple
        case .core: return .red
        case .custom: return .pink
        }
    }
    
    private func categoryDescription(for category: ExerciseCategory) -> String {
        switch category {
        case .compound: return "Олон булчин хамрах дасгал"
        case .lowerBody: return "Хөлний дасгал"
        case .upperBodyPush: return "Түлхэх дасгал"
        case .upperBodyPull: return "Татах дасгал"
        case .core: return "Хэвлийн дасгал"
        case .custom: return "Миний дасгал"
        }
    }
}

// Keep the original AddCustomExerciseView for backward compatibility
struct AddCustomExerciseView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    
    var body: some View {
        ModernAddCustomExerciseView(viewModel: viewModel)
    }
}

#Preview {
    ModernAddCustomExerciseView(viewModel: ExerciseViewModel())
} 
