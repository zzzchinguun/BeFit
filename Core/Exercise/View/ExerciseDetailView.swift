//
//  ExerciseDetailView.swift
//  BeFit
//
//  Created by AI Assistant on 4/25/25.
//

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    let exercise: Exercise
    @ObservedObject var viewModel: ExerciseViewModel
    
    @State private var showingLogWorkout = false
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(exercise.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingLogWorkout = true
                    } label: {
                        Text("Log Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Stats summary
                HStack(spacing: 0) {
                    StatCard(
                        title: "Maximum Weight",
                        value: "\(String(format: "%.1f", viewModel.calculateMaxWeight(for: exercise.id ?? ""))) kg",
                        icon: "scalemass.fill"
                    )
                    
                    Divider()
                    
                    StatCard(
                        title: "Max Volume",
                        value: "\(Int(viewModel.calculateMaxVolume(for: exercise.id ?? "")))",
                        icon: "chart.bar.fill"
                    )
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("History").tag(0)
                    Text("Progress").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    historyView
                } else {
                    progressView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLogWorkout) {
            LogWorkoutView(exercise: exercise, viewModel: viewModel)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            let logs = viewModel.getExerciseLogHistory(exerciseId: exercise.id ?? "")
            
            if logs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No workout history yet")
                        .font(.headline)
                    
                    Text("Start logging your workouts to track your progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        showingLogWorkout = true
                    } label: {
                        Text("Log Your First Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(logs) { log in
                    WorkoutLogCard(log: log)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var progressView: some View {
        VStack(spacing: 24) {
            let logs = viewModel.getExerciseLogHistory(exerciseId: exercise.id ?? "")
            
            if logs.count < 2 {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Not enough data")
                        .font(.headline)
                    
                    Text("Log at least two workouts to see your progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Volume progression chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Volume Progression")
                        .font(.headline)
                    
                    // SwiftUI Charts implementation would go here
                    // Using a placeholder for now
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Volume chart")
                                .foregroundColor(.blue)
                        )
                }
                .padding(.horizontal)
                
                // Weight progression chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weight Progression")
                        .font(.headline)
                    
                    // SwiftUI Charts implementation would go here
                    // Using a placeholder for now
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Weight chart")
                                .foregroundColor(.green)
                        )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct WorkoutLogCard: View {
    let log: WorkoutLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(log.date))
                    .font(.headline)
                
                Spacer()
                
                Text("Total: \(Int(log.totalVolume))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ForEach(log.sets) { set in
                HStack {
                    Text("Set \(log.sets.firstIndex(where: { $0.id == set.id })! + 1)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(set.reps) reps")
                        .font(.subheadline)
                    
                    Text("×")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                    
                    Text("\(String(format: "%.1f", set.weight)) kg")
                        .font(.subheadline)
                }
            }
            
            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(
            exercise: Exercise.defaultExercises[0],
            viewModel: ExerciseViewModel()
        )
    }
} 