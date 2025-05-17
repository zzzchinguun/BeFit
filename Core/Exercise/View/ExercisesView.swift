//
//  ExercisesView.swift
//  BeFit
//
//  Created by AI Assistant on 4/25/25.
//

import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @State private var showingAddCustomExercise = false
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryPill(title: "All", isSelected: viewModel.selectedCategory == nil) {
                            viewModel.selectedCategory = nil
                            viewModel.filterExercises()
                        }
                        
                        ForEach(ExerciseCategory.allCases) { category in
                            CategoryPill(title: category.rawValue, isSelected: viewModel.selectedCategory == category) {
                                viewModel.selectedCategory = category
                                viewModel.filterExercises()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search exercises", text: $searchText)
                        .onChange(of: searchText) { _ in
                            viewModel.searchText = searchText
                            viewModel.filterExercises()
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.searchText = ""
                            viewModel.filterExercises()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                
                List {
                    ForEach(viewModel.filteredExercises) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise, viewModel: viewModel)) {
                            HStack {
                                Text(exercise.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if exercise.isCustom {
                                    Text("Custom")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(8)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
//            .navigationTitle("Exercises")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        showingAddCustomExercise = true
//                    } label: {
//                        Image(systemName: "plus")
//                    }
//                }
//            }
            .sheet(isPresented: $showingAddCustomExercise) {
                AddCustomExerciseView(viewModel: viewModel)
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct CategoryPill: View {
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
                .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
                .cornerRadius(16)
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4)
        }
    }
}

#Preview {
    ExercisesView()
} 
