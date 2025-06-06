//
//  LogWorkoutView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 4/25/25.
//

import SwiftUI

struct LogWorkoutView: View {
    let exercise: Exercise
    @ObservedObject var viewModel: ExerciseViewModel
    let editingLog: WorkoutLog?
    
    @State private var sets: [WorkoutSetInput]
    @State private var notes: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLogging = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init(exercise: Exercise, viewModel: ExerciseViewModel, editingLog: WorkoutLog? = nil) {
        self.exercise = exercise
        self.viewModel = viewModel
        self.editingLog = editingLog
        
        // Initialize sets from editingLog if available
        if let editingLog = editingLog {
            _sets = State(initialValue: editingLog.sets.map { WorkoutSetInput(reps: $0.reps, weight: $0.weight) })
            _notes = State(initialValue: editingLog.notes ?? "")
        } else {
            _sets = State(initialValue: [WorkoutSetInput()])
        }
    }
    
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle(editingLog != nil ? "Дасгал засах" : "Дасгал бичих")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Цуцлах") {
                            dismiss()
                        }
                    }
                    
                    if editingLog != nil {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .alert(alertMessage, isPresented: $showingAlert) {
                    Button("OK") {
                        if alertMessage.contains("амжилттай") {
                            dismiss()
                        }
                    }
                }
                .alert("Дасгал устгах", isPresented: $showingDeleteConfirmation) {
                    Button("Цуцлах", role: .cancel) { }
                    Button("Устгах", role: .destructive) {
                        deleteWorkout()
                    }
                } message: {
                    Text("Энэ дасгалыг устгахдаа итгэлтэй байна уу?")
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
        Section(header: Text("Дасгал")) {
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
        Section(header: Text("Сетүүд")) {
            ForEach(sets.indices, id: \.self) { index in
                setRow(for: index)
            }
            
            addSetButton
        }
    }
    
    private func setRow(for index: Int) -> some View {
        HStack {
            Text("Сет \(index + 1)")
                .font(.headline)
                .frame(width: 60, alignment: .leading)
            
            Divider()
                .frame(height: 20)
            
            HStack(spacing: 4) {
                TextField("Давт", value: $sets[index].reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                
                Text("давт")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                TextField("Жин", value: $sets[index].weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                
                Text("кг")
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
                Text("Сет нэмэх")
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Тэмдэглэл (заавал биш)")) {
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
                    Text("Дасгал хадгалах")
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
            alertMessage = "Дор хаяж нэг сет зөв давталт болон жинтэй бичнэ үү."
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
        
        if let editingLog = editingLog {
            // Update existing log
            viewModel.updateWorkoutLog(
                logId: editingLog.id ?? "",
                sets: workoutSets,
                notes: notes.isEmpty ? nil : notes
            ) { success in
                isLogging = false
                
                if success {
                    alertMessage = "Дасгал амжилттай шинэчлэгдлээ!"
                    // Refresh logs after successful update
                    if let userId = viewModel.getCurrentUserId() {
                        viewModel.fetchUserWorkoutLogs(userId: userId)
                    }
                } else {
                    alertMessage = "Дасгал шинэчлэхэд алдаа гарлаа. Дахин оролдоно уу."
                }
                
                showingAlert = true
            }
        } else {
            // Create new log
            viewModel.logWorkout(
                exerciseId: exerciseId,
                exerciseName: exercise.name,
                sets: workoutSets,
                notes: notes.isEmpty ? nil : notes
            ) { success in
                isLogging = false
                
                if success {
                    alertMessage = "Дасгал амжилттай бүртгэгдлээ!"
                    // Refresh logs after successful creation
                    if let userId = viewModel.getCurrentUserId() {
                        viewModel.fetchUserWorkoutLogs(userId: userId)
                    }
                } else {
                    alertMessage = "Дасгал бүртгэхэд алдаа гарлаа. Дахин оролдоно уу."
                }
                
                showingAlert = true
            }
        }
    }
    
    private func deleteWorkout() {
        guard let editingLog = editingLog, let logId = editingLog.id else { return }
        
        isLogging = true
        
        viewModel.deleteWorkoutLog(logId: logId) { success in
            isLogging = false
            
            if success {
                alertMessage = "Дасгал амжилттай устгагдлаа!"
                // Refresh logs after successful deletion
                if let userId = viewModel.getCurrentUserId() {
                    viewModel.fetchUserWorkoutLogs(userId: userId)
                }
            } else {
                alertMessage = "Дасгал устгахад алдаа гарлаа. Дахин оролдоно уу."
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
