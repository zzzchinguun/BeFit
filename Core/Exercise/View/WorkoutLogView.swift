//
//  WorkoutLogView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 4/25/25.
//

import SwiftUI

struct WorkoutLogView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    @State private var selectedDateFilter: DateFilter = .all
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date filter picker
                Picker("Filter", selection: $selectedDateFilter) {
                    ForEach(DateFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredLogs.isEmpty {
                    ContentUnavailableView(
                        "No Workout Logs",
                        systemImage: "dumbbell.fill",
                        description: Text("Start tracking your workouts to see your progress")
                    )
                } else {
                    List {
                        ForEach(groupedLogs.keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(formatDate(date))) {
                                ForEach(groupedLogs[date] ?? []) { log in
                                    NavigationLink(destination: exerciseDetailView(for: log)) {
                                        WorkoutLogRowView(log: log)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Workout Logs")
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onAppear {
            // Refresh logs when view appears
            if let userId = viewModel.getCurrentUserId() {
                viewModel.fetchUserWorkoutLogs(userId: userId)
            }
        }
    }
    
    private var filteredLogs: [WorkoutLog] {
        let logs = viewModel.workoutLogs
        
        switch selectedDateFilter {
        case .all:
            return logs
        case .today:
            return logs.filter { Calendar.current.isDateInToday($0.date) }
        case .thisWeek:
            return logs.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            return logs.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        }
    }
    
    private var groupedLogs: [Date: [WorkoutLog]] {
        Dictionary(grouping: filteredLogs) { log in
            Calendar.current.startOfDay(for: log.date)
        }
    }
    
    private func exerciseDetailView(for log: WorkoutLog) -> some View {
        // First try to find exercise by ID
        if let exercise = viewModel.exercises.first(where: { $0.id == log.exerciseId }) {
            return AnyView(ExerciseDetailView(exercise: exercise, viewModel: viewModel))
        } 
        // Then try to find by name
        else if let exercise = viewModel.exercises.first(where: { $0.name == log.exerciseName }) {
            return AnyView(ExerciseDetailView(exercise: exercise, viewModel: viewModel))
        }
        // Create a temporary exercise if not found by either method
        else {
            let tempExercise = Exercise(
                id: nil, // Use nil instead of log.exerciseId to avoid Firestore warnings
                name: log.exerciseName,
                category: .custom,
                isCustom: false,
                createdBy: nil
            )
            return AnyView(ExerciseDetailView(exercise: tempExercise, viewModel: viewModel))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct WorkoutLogRowView: View {
    let log: WorkoutLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.exerciseName)
                    .font(.headline)

                Text("\(log.sets.count) sets · \(Int(log.totalVolume)) total volume")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(log.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                let maxWeight = log.sets.map { $0.weight }.max() ?? 0
                Text("\(String(format: "%.1f", maxWeight))kg")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
enum DateFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    
    var id: String { self.rawValue }
}

#Preview {
    let viewModel = ExerciseViewModel()
    return WorkoutLogView(viewModel: viewModel)
} 
