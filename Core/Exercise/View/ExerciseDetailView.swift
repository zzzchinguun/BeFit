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
    @State private var selectedDataType = DataType.weight
    @State private var selectedTimeRange = TimeRange.threeMonths
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
        .onAppear {
            if let userId = viewModel.getCurrentUserId() {
                viewModel.fetchUserWorkoutLogs(userId: userId)
            }
        }
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
                // Data type selector
                Picker("Data Type", selection: $selectedDataType) {
                    Text("Weight").tag(DataType.weight)
                    Text("Volume").tag(DataType.volume)
                    Text("Reps").tag(DataType.reps)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Time range selector
                TimeRangeSelector(selectedTimeRange: $selectedTimeRange)
                    .padding(.horizontal)
                
                // Progress chart
                ProgressChartView(logs: logs, dataType: selectedDataType, timeRange: selectedTimeRange)
                    .frame(height: 240)
                    .padding(.horizontal)
                
                // Stats section
                ProgressStatsView(logs: logs, dataType: selectedDataType)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Supporting Views

struct TimeRangeSelector: View {
    @Binding var selectedTimeRange: TimeRange
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                    }) {
                        Text(range.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedTimeRange == range ? .bold : .regular)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                selectedTimeRange == range ? 
                                    Color.blue.opacity(0.2) : 
                                    Color(.secondarySystemBackground)
                            )
                            .foregroundColor(selectedTimeRange == range ? .blue : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct ProgressChartView: View {
    let logs: [WorkoutLog]
    let dataType: DataType
    let timeRange: TimeRange
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dataType.title)
                .font(.headline)
            
            if let filteredLogs = getFilteredLogs(), !filteredLogs.isEmpty {
                Chart {
                    ForEach(filteredLogs) { log in
                        LineMark(
                            x: .value("Date", log.date),
                            y: .value(dataType.title, getValue(for: log))
                        )
                        .foregroundStyle(dataType.color.gradient)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", log.date),
                            y: .value(dataType.title, getValue(for: log))
                        )
                        .foregroundStyle(dataType.color)
                        .symbolSize(50)
                    }
                }
                .chartYScale(domain: getYAxisRange())
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .automatic(desiredCount: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel(formatDate(date), anchor: .top)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
                .padding(.top, 5)
            } else {
                Text("No data for selected time range")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func getValue(for log: WorkoutLog) -> Double {
        switch dataType {
        case .weight:
            return log.sets.filter { $0.isCompleted }.map { $0.weight }.max() ?? 0
        case .volume:
            return log.totalVolume
        case .reps:
            return Double(log.sets.filter { $0.isCompleted }.map { $0.reps }.max() ?? 0)
        }
    }
    
    private func getYAxisRange() -> ClosedRange<Double> {
        if let filteredLogs = getFilteredLogs(), !filteredLogs.isEmpty {
            let values = filteredLogs.map { getValue(for: $0) }
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 10
            let buffer = max((maxValue - minValue) * 0.1, 1)
            
            return max(minValue - buffer, 0)...maxValue + buffer
        }
        return 0...10
    }
    
    private func getFilteredLogs() -> [WorkoutLog]? {
        let dateLimit = Calendar.current.date(byAdding: timeRange.dateComponent, value: timeRange.value, to: Date()) ?? Date()
        
        let filtered = logs
            .filter { $0.date >= dateLimit }
            .sorted { $0.date < $1.date }
        
        return filtered.isEmpty ? nil : filtered
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch timeRange {
        case .week, .month:
            formatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths:
            formatter.dateFormat = "d MMM"
        case .year, .all:
            formatter.dateFormat = "MMM yyyy"
        }
        
        return formatter.string(from: date)
    }
}

struct ProgressStatsView: View {
    let logs: [WorkoutLog]
    let dataType: DataType
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            StatisticBox(
                title: "Current",
                value: String(format: "%.1f", getCurrentValue()),
                unit: dataType.unit,
                icon: "clock.fill",
                color: .blue
            )
            
            StatisticBox(
                title: "Best",
                value: String(format: "%.1f", getBestValue()),
                unit: dataType.unit,
                icon: "star.fill",
                color: .yellow
            )
            
            StatisticBox(
                title: getProgressTitle(),
                value: getProgressValue(),
                unit: "%",
                icon: getProgressIcon(),
                color: getProgressColor()
            )
        }
    }
    
    private func getCurrentValue() -> Double {
        guard let lastLog = logs.first else { return 0 }
        
        switch dataType {
        case .weight:
            return lastLog.sets.filter { $0.isCompleted }.map { $0.weight }.max() ?? 0
        case .volume:
            return lastLog.totalVolume
        case .reps:
            return Double(lastLog.sets.filter { $0.isCompleted }.map { $0.reps }.max() ?? 0)
        }
    }
    
    private func getBestValue() -> Double {
        switch dataType {
        case .weight:
            return logs.flatMap { $0.sets }.filter { $0.isCompleted }.map { $0.weight }.max() ?? 0
        case .volume:
            return logs.map { $0.totalVolume }.max() ?? 0
        case .reps:
            return Double(logs.flatMap { $0.sets }.filter { $0.isCompleted }.map { $0.reps }.max() ?? 0)
        }
    }
    
    private func calculateProgress() -> Double {
        guard logs.count >= 2, let firstLog = logs.last, let latestLog = logs.first else { return 0 }
        
        let firstValue: Double
        let latestValue: Double
        
        switch dataType {
        case .weight:
            firstValue = firstLog.sets.filter { $0.isCompleted }.map { $0.weight }.max() ?? 0
            latestValue = latestLog.sets.filter { $0.isCompleted }.map { $0.weight }.max() ?? 0
        case .volume:
            firstValue = firstLog.totalVolume
            latestValue = latestLog.totalVolume
        case .reps:
            firstValue = Double(firstLog.sets.filter { $0.isCompleted }.map { $0.reps }.max() ?? 0)
            latestValue = Double(latestLog.sets.filter { $0.isCompleted }.map { $0.reps }.max() ?? 0)
        }
        
        if firstValue == 0 { return 0 }
        return ((latestValue - firstValue) / firstValue) * 100
    }
    
    private func getProgressTitle() -> String {
        let progress = calculateProgress()
        return progress >= 0 ? "Increased" : "Decreased"
    }
    
    private func getProgressValue() -> String {
        let progress = calculateProgress()
        return String(format: "%.1f", abs(progress))
    }
    
    private func getProgressIcon() -> String {
        let progress = calculateProgress()
        return progress >= 0 ? "arrow.up.right" : "arrow.down.right"
    }
    
    private func getProgressColor() -> Color {
        let progress = calculateProgress()
        return progress >= 0 ? .green : .red
    }
}

struct StatisticBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Enums for Progress View

enum DataType: String, CaseIterable {
    case weight, volume, reps
    
    var title: String {
        switch self {
        case .weight: return "Weight"
        case .volume: return "Volume"
        case .reps: return "Reps"
        }
    }
    
    var unit: String {
        switch self {
        case .weight: return "kg"
        case .volume: return ""
        case .reps: return "reps"
        }
    }
    
    var color: Color {
        switch self {
        case .weight: return .blue
        case .volume: return .purple
        case .reps: return .green
        }
    }
}

enum TimeRange: String, CaseIterable {
    case week, month, threeMonths, sixMonths, year, all
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "Year"
        case .all: return "All Time"
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .day
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .year: return .month
        case .all: return .year
        }
    }
    
    var value: Int {
        switch self {
        case .week: return -7
        case .month: return -30
        case .threeMonths: return -3
        case .sixMonths: return -6
        case .year: return -12
        case .all: return -100 // A large number to include all history
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