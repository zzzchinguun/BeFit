//
//  LogWorkoutView.swift
//  BeFit
//
//  Created by AI Assistant on 4/25/25.
//

import SwiftUI

struct LogWorkoutView: View {
    let exercise: Exercise
    @ObservedObject var viewModel: ExerciseViewModel
    
    @State private var sets: [WorkoutSetInput]
    @State private var notes: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLogging = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init(exercise: Exercise, viewModel: ExerciseViewModel) {
        self.exercise = exercise
        self.viewModel = viewModel
        _sets = State(initialValue: [WorkoutSetInput()])
    }
    
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Log Workout")
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
    
    private var formContent: some View {
        Form {
            exerciseSection
            setsSection
            notesSection
            saveButtonSection
        }
    }
    
    private var exerciseSection: some View {
        Section(header: Text("Exercise")) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                
                Spacer()
                
                Text(exercise.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var setsSection: some View {
        Section(header: Text("Sets")) {
            ForEach(sets.indices, id: \.self) { index in
                setRow(for: index)
            }
            
            addSetButton
        }
    }
    
    private func setRow(for index: Int) -> some View {
        HStack {
            Text("Set \(index + 1)")
                .font(.headline)
                .frame(width: 60, alignment: .leading)
            
            Divider()
                .frame(height: 20)
            
            HStack(spacing: 4) {
                TextField("Reps", value: $sets[index].reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                
                Text("reps")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                TextField("Weight", value: $sets[index].weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                
                Text("kg")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if sets.count > 1 {
                Button(action: {
                    withAnimation {
                        if index < sets.count {
                            var updatedSets = sets
                            updatedSets.remove(at: index)
                            sets = updatedSets
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var addSetButton: some View {
        Button(action: {
            withAnimation {
                sets.append(WorkoutSetInput())
            }
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Set")
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes (Optional)")) {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
        }
    }
    
    private var saveButtonSection: some View {
        Section {
            Button(action: saveWorkout) {
                if isLogging {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Save Workout")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .disabled(isLogging || !isValidWorkout())
        }
    }
    
    private func isValidWorkout() -> Bool {
        // Check if at least one set has valid values
        return sets.contains { $0.reps > 0 && $0.weight > 0 }
    }
    
    private func saveWorkout() {
        guard isValidWorkout() else {
            alertMessage = "Please enter at least one valid set with reps and weight."
            showingAlert = true
            return
        }
        
        isLogging = true
        
        // Convert WorkoutSetInput to WorkoutSet
        let workoutSets = sets.compactMap { input -> WorkoutSet? in
            if input.reps > 0 && input.weight > 0 {
                return WorkoutSet(id: nil, reps: input.reps, weight: input.weight, isCompleted: true)
            }
            return nil
        }
        
        // Make sure we have a valid exercise ID
        let exerciseId = exercise.id ?? "exercise-\(UUID().uuidString)"
        
        viewModel.logWorkout(
            exerciseId: exerciseId,
            exerciseName: exercise.name,
            sets: workoutSets,
            notes: notes.isEmpty ? nil : notes
        ) { success in
            isLogging = false
            
            if success {
                alertMessage = "Workout logged successfully!"
            } else {
                alertMessage = "Failed to log workout. Please try again."
            }
            
            showingAlert = true
        }
    }
}

struct WorkoutSetInput: Identifiable {
    let id = UUID()
    var reps: Int = 0
    var weight: Double = 0.0
}

#Preview {
    // Set up a test environment
    let viewModel = ExerciseViewModel()
    
    // Use a default exercise and ensure it has an ID
    var exercise = Exercise.defaultExercises[0]
    exercise.id = "test-exercise-id" // This won't affect Firestore, just for preview
    
    return LogWorkoutView(
        exercise: exercise,
        viewModel: viewModel
    )
} 