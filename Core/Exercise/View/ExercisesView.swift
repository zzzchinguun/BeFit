//
//  ExercisesView.swift
//  BeFit
//
//  Created by AI Assistant on 4/25/25.
//

import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showingAddCustomExercise = false
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var showingError = false
    @State private var showingDeleteAlert = false
    @State private var exerciseToDelete: Exercise?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack{
                Text(languageManager.isEnglishLanguage ? "Exercises" : "Дасгалууд")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                modernAddButton
            }
                .padding()
                // Modern header with gradient
                VStack(spacing: 16) {
                    // Enhanced search bar (without barcode scanner for exercises)
                    ExerciseSearchBar(text: $searchText, placeholder: "Дасгал хайх...")
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchText = newValue
                            viewModel.filterExercises()
                        }
                    
                    // Category filter with modern design
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ModernCategoryPill(title: "Бүгд", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.selectedCategory = nil
                                viewModel.filterExercises()
                            }
                            
                            ForEach(ExerciseCategory.allCases) { category in
                                ModernCategoryPill(title: category.localizedName(isEnglish: languageManager.isExerciseEnglishLanguage), isSelected: viewModel.selectedCategory == category) {
                                    viewModel.selectedCategory = category
                                    viewModel.filterExercises()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Stats summary
                    if !viewModel.exercises.isEmpty {
                        ExerciseStatsRow(
                            totalExercises: viewModel.exercises.count,
                            customExercises: viewModel.exercises.filter { $0.isCustom }.count,
                            filteredCount: viewModel.filteredExercises.count,
                            isEnglishLanguage: languageManager.isEnglishLanguage
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 20)
                
                // Exercise list
                if viewModel.filteredExercises.isEmpty {
                    modernEmptyState
                } else {
                    modernExerciseList
                }
            }
            
            .sheet(isPresented: $showingAddCustomExercise) {
                ModernAddCustomExerciseView(viewModel: viewModel)
            }
            .alert("Дасгал устгах", isPresented: $showingDeleteAlert) {
                Button("Цуцлах", role: .cancel) {
                    exerciseToDelete = nil
                }
                Button("Устгах", role: .destructive) {
                    if let exercise = exerciseToDelete {
                        deleteExercise(exercise)
                    }
                }
            } message: {
                Text("Та энэ дасгалыг үнэхээр устгахыг хүсэж байна уу?")
            }
            .alert("Алдаа", isPresented: $showingError) {
                Button("OK") { showingError = false }
            } message: {
                Text(viewModel.errorMessage ?? "Алдаа гарлаа")
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                print("🔄 ExercisesView appeared - setting up")
                setupErrorHandling()
                
                // Only reset navigation state if we're not already navigating
                if selectedExercise == nil {
                    // Reset view model state to prevent conflicts
                    viewModel.resetNavigationState()
                    
                    // Reset search and filters to ensure clean state
                    if searchText != viewModel.searchText {
                        searchText = viewModel.searchText
                    }
                }
            }
            .onDisappear {
                print("🔄 ExercisesView disappeared - cleaning up")
                cleanupErrorHandling()
                
                // Don't clear navigation state when leaving the view as it might be for navigation
                // selectedExercise = nil
            }
            .onChange(of: viewModel.errorMessage) { _, error in
                showingError = error != nil
            }
            // Remove the notification center observers that might interfere with navigation
            // Clear any existing selected exercise when view re-appears
            // .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            //     selectedExercise = nil
            // }
            // Listen for tab switches to reset state when switching to exercises
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("tabSwitched"))) { notification in
                if let tabName = notification.object as? String, tabName == "exercises" {
                    print("🔄 Switching to exercises tab - resetting state")
                    // Only reset if we're not in an active navigation
                    if selectedExercise == nil {
                        viewModel.resetNavigationState()
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Components
    
    private var modernAddButton: some View {
        Button {
            showingAddCustomExercise = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
    
    private var modernExerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    ModernExerciseCard(
                        exercise: exercise,
                        onTap: {
                            selectedExercise = exercise
                        },
                        onDelete: exercise.isCustom ? {
                            exerciseToDelete = exercise
                            showingDeleteAlert = true
                        } : nil,
                        isEnglishLanguage: languageManager.isEnglishLanguage,
                        isExerciseEnglishLanguage: languageManager.isExerciseEnglishLanguage
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.clear)
        .navigationDestination(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, viewModel: viewModel)
        }
    }
    
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? 
                     (languageManager.isEnglishLanguage ? "No Exercises" : "Дасгал байхгүй") : 
                     (languageManager.isEnglishLanguage ? "No Search Results" : "Хайлт олдсонгүй"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     (languageManager.isEnglishLanguage ? "Start by adding your own exercise" : "Өөрийн дасгал нэмэхээр эхэлнэ үү") : 
                     (languageManager.isEnglishLanguage ? "No exercises found matching '\(searchText)'" : "'\(searchText)' гэсэн хайлтад тохирох дасгал олдсонгүй"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                if searchText.isEmpty {
                    showingAddCustomExercise = true
                } else {
                    searchText = ""
                    viewModel.searchText = ""
                    viewModel.filterExercises()
                }
            } label: {
                Text(searchText.isEmpty ? 
                     (languageManager.isEnglishLanguage ? "Add Custom Exercise" : "Өөрийн дасгал нэмэх") : 
                     (languageManager.isEnglishLanguage ? "Clear Search" : "Хайлт цэвэрлэх"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Methods
    
    private func setupErrorHandling() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("exerciseError"),
            object: nil,
            queue: .main
        ) { notification in
            if let _ = notification.object as? String {
                self.showingError = true
            }
        }
    }
    
    private func cleanupErrorHandling() {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("exerciseError"),
            object: nil
        )
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        guard let exerciseId = exercise.id else { return }
        
        viewModel.deleteCustomExercise(exerciseId: exerciseId) { success in
            if success {
                exerciseToDelete = nil
            } else {
                showingError = true
            }
        }
    }
}

// MARK: - Supporting Views

// ModernSearchBar is now imported from NutritionDatabaseView.swift

struct ModernCategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? 
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color(.tertiarySystemBackground), Color(.tertiarySystemBackground)]), startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ExerciseStatsRow: View {
    let totalExercises: Int
    let customExercises: Int
    let filteredCount: Int
    let isEnglishLanguage: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: isEnglishLanguage ? "Total" : "Нийт", value: "\(totalExercises)", icon: "list.bullet", color: .blue)
            StatCard(title: isEnglishLanguage ? "Custom" : "Өөрийн", value: "\(customExercises)", icon: "plus.circle", color: .green)
            StatCard(title: isEnglishLanguage ? "Showing" : "Харагдаж байгаа", value: "\(filteredCount)", icon: "eye", color: .orange)
            
            Spacer()
        }
    }
}

struct ModernExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    let isEnglishLanguage: Bool
    let isExerciseEnglishLanguage: Bool
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Exercise icon
                Image(systemName: exerciseIcon(for: exercise.category))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(categoryColor(for: exercise.category))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(categoryColor(for: exercise.category).opacity(0.15))
                    )
                
                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.localizedName(isEnglish: isExerciseEnglishLanguage))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(exercise.category.localizedName(isEnglish: isExerciseEnglishLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if exercise.isCustom {
                            Text(isEnglishLanguage ? "Custom" : "Өөрийн")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func exerciseIcon(for category: ExerciseCategory) -> String {
        switch category {
        case .compound: return "dumbbell.fill"
        case .lowerBody: return "figure.walk"
        case .upperBodyPush: return "arrow.up.circle.fill"
        case .upperBodyPull: return "arrow.down.circle.fill"
        case .core: return "circle.grid.cross.fill"
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
}

// MARK: - Exercise-Specific Search Bar (No Barcode Scanner)

struct ExerciseSearchBar: View {
    @Binding var text: String
    var placeholder: String
    @FocusState private var isSearchFocused: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isSearchFocused ? Color.primaryApp : .gray)
                .font(.system(size: 18, weight: .medium))
                
            TextField(placeholder, text: $text)
                .font(.body)
                .focused($isSearchFocused)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color.neutralBackgroundDark.opacity(0.8) : Color.white)
                .stroke(isSearchFocused ? Color.primaryApp.opacity(0.5) : Color.primaryApp.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    ExercisesView()
} 
