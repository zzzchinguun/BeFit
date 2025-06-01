import SwiftUI
import Charts

// Re-use the TimeRange enum similar to the one in ExerciseDetailView
enum WeightTimeRange: String, CaseIterable {
    case week, month, threeMonths, sixMonths, year, all
    
    var displayName: String {
        switch self {
        case .week: return "Долоо хоног"
        case .month: return "Сар"
        case .threeMonths: return "3 Сар"
        case .sixMonths: return "6 Сар"
        case .year: return "Жил"
        case .all: return "Бүх цаг"
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

struct WeightProgressView: View {
    @ObservedObject var viewModel: WeightLogViewModel
    @StateObject private var languageManager = LanguageManager.shared
    @State private var selectedTimeRange = WeightTimeRange.threeMonths
    @State private var selectedView = 0 // 0 = Progress Chart, 1 = Calendar
    @State private var selectedDate: Date?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text(languageManager.isEnglishLanguage ? "Weight Progress" : "Жингийн Ахиц")
                .font(.title)
                .fontWeight(.bold)
            
            // View selector
            Picker(languageManager.isEnglishLanguage ? "View" : "Харах", selection: $selectedView) {
                Text(languageManager.isEnglishLanguage ? "Progress" : "Ахиц").tag(0)
                Text(languageManager.isEnglishLanguage ? "Calendar" : "Хуанли").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if selectedView == 0 {
                progressChartView
            } else {
                calendarView
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .navigationTitle(languageManager.isEnglishLanguage ? "Weight Progress" : "Жингийн Ахиц")
    }
    
    private var progressChartView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.weightLogs.count < 2 {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(languageManager.isEnglishLanguage ? "Insufficient Data" : "Хангалттай өгөгдөл байхгүй")
                            .font(.headline)
                        
                        Text(languageManager.isEnglishLanguage ? "Add at least two weight entries to view your progress" : "Ахицаа харахын тулд дор хаяж хоёр жингийн бичлэг оруулна уу")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    // Time range selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(WeightTimeRange.allCases, id: \.self) { timeRange in
                                Button {
                                    withAnimation {
                                        selectedTimeRange = timeRange
                                    }
                                } label: {
                                    Text(timeRange.displayName)
                                        .font(.caption)
                                        .fontWeight(selectedTimeRange == timeRange ? .bold : .regular)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedTimeRange == timeRange ?
                                            Color.blue :
                                            Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(selectedTimeRange == timeRange ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Progress chart
                    weightChartView
                    
                    // Stats section
                    weightProgressStatsView
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var weightChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.isEnglishLanguage ? "Weight" : "Жин")
                .font(.headline)
            
            if let filteredLogs = getFilteredLogs(), !filteredLogs.isEmpty {
                Chart {
                    ForEach(filteredLogs) { log in
                        LineMark(
                            x: .value("Date", log.date),
                            y: .value("Weight", log.weight)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", log.date),
                            y: .value("Weight", log.weight)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(50)
                    }
                }
                .chartYScale(domain: getYAxisRange())
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .automatic(desiredCount: getDesiredAxisCount())) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel(formatDate(date), anchor: .top)
                                .font(.caption2)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                    }
                }
                .frame(height: 220)
            } else {
                Text("Сонгосон хугацаанд өгөгдөл байхгүй")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var weightProgressStatsView: some View {
        HStack(spacing: 12) {
            WeightStatBox(
                title: "Одоогийн",
                value: String(format: "%.1f", getCurrentWeight()),
                unit: "кг",
                icon: "scalemass.fill",
                color: .blue
            )
            
            WeightStatBox(
                title: "Хамгийн бага",
                value: String(format: "%.1f", getLowestWeight()),
                unit: "кг",
                icon: "arrow.down.circle.fill",
                color: .green
            )
            
            WeightStatBox(
                title: getProgressTitle(),
                value: getProgressValue(),
                unit: "%",
                icon: getProgressIcon(),
                color: getProgressColor()
            )
        }
    }
    
    private var calendarView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Calendar view
                WeightCalendarView(
                    weightLogs: viewModel.weightLogs,
                    selectedDate: $selectedDate
                )
                
                // Selected day detail
                if let selectedDate = selectedDate, 
                   let selectedLog = viewModel.weightLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                    WeightLogDetailCard(log: selectedLog)
                        .padding(.horizontal)
                } else {
                    Text("Дэлгэрэнгүй харахын тулд огноо сонгоно уу")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentWeight() -> Double {
        return viewModel.weightLogs.first?.weight ?? 0
    }
    
    private func getLowestWeight() -> Double {
        return viewModel.weightLogs.map { $0.weight }.min() ?? 0
    }
    
    private func calculateProgress() -> Double {
        guard viewModel.weightLogs.count >= 2,
              let firstLog = viewModel.weightLogs.last,
              let lastLog = viewModel.weightLogs.first else { return 0 }
        
        if firstLog.weight == 0 { return 0 }
        return ((lastLog.weight - firstLog.weight) / firstLog.weight) * 100
    }
    
    private func getProgressTitle() -> String {
        let progress = calculateProgress()
        return progress >= 0 ? "Нэмсэн" : "Хассан"
    }
    
    private func getProgressValue() -> String {
        let progress = calculateProgress()
        return String(format: "%.1f", abs(progress))
    }
    
    private func getProgressIcon() -> String {
        let progress = calculateProgress()
        // For weight loss (negative progress), we consider it positive
        return progress < 0 ? "arrow.down.right" : "arrow.up.right"
    }
    
    private func getProgressColor() -> Color {
        let progress = calculateProgress()
        // For weight loss (negative progress), we use green
        return progress < 0 ? .green : .red
    }
    
    private func getFilteredLogs() -> [WeightLog]? {
        let dateLimit = Calendar.current.date(byAdding: selectedTimeRange.dateComponent, value: selectedTimeRange.value, to: Date()) ?? Date()
        
        let filtered = viewModel.weightLogs
            .filter { $0.date >= dateLimit }
            .sorted { $0.date < $1.date }
        
        return filtered.isEmpty ? nil : filtered
    }
    
    private func getYAxisRange() -> ClosedRange<Double> {
        if let filteredLogs = getFilteredLogs(), !filteredLogs.isEmpty {
            let weights = filteredLogs.map { $0.weight }
            let minValue = weights.min() ?? 0
            let maxValue = weights.max() ?? 100
            let buffer = max((maxValue - minValue) * 0.1, 1)
            
            return max(minValue - buffer, 0)...(maxValue + buffer)
        }
        return 0...100
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeRange {
        case .week:
            formatter.dateFormat = "d/M"  // Shorter format for weekly view
        case .month:
            formatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths:
            formatter.dateFormat = "d MMM"
        case .year, .all:
            formatter.dateFormat = "MMM yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func getDesiredAxisCount() -> Int {
        switch selectedTimeRange {
        case .week:
            return 3  // Show fewer ticks for weekly view to avoid overcrowding
        case .month:
            return 4
        case .threeMonths, .sixMonths:
            return 3
        case .year, .all:
            return 5
        }
    }
}

// MARK: - Supporting Views for Weight Progress

struct WeightLogDetailCard: View {
    let log: WeightLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text(formattedDate)
                    .font(.headline)
                
                Spacer()
                
                Text("\(String(format: "%.1f", log.weight)) кг")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if let note = log.note, !note.isEmpty {
                Divider()
                
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                    
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: log.date)
    }
}

struct WeightCalendarView: View {
    let weightLogs: [WeightLog]
    @Binding var selectedDate: Date?
    @State private var month = Date()
    
    var body: some View {
        VStack {
            // Month selector
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: month))
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Day of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { date in
                    if date.monthYear == month.monthYear {
                        Button(action: {
                            selectedDate = date
                        }) {
                            VStack {
                                if hasLog(for: date) {
                                    Circle()
                                        .fill(Color.blue.opacity(selectedDate == date ? 1.0 : 0.3))
                                        .overlay(
                                            Text("\(Calendar.current.component(.day, from: date))")
                                                .foregroundColor(selectedDate == date ? .white : .primary)
                                        )
                                        .frame(width: 32, height: 32)
                                } else {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .foregroundColor(.primary)
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                        .disabled(!hasLog(for: date))
                    } else {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var days: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: month) else { return [] }
        guard let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else { return [] }
        guard let monthLastWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.end) else { return [] }
        
        let dateComponents = Calendar.current.dateComponents(
            [.day],
            from: monthFirstWeek.start,
            to: monthLastWeek.end
        )
        
        guard let dayCount = dateComponents.day else { return [] }
        
        let days = (0...dayCount).compactMap { offset -> Date? in
            Calendar.current.date(byAdding: .day, value: offset, to: monthFirstWeek.start)
        }
        
        return days
    }
    
    private var daysOfWeek: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Starting with Sunday
        
        return (1...7).map { weekdayNumber in
            let date = calendar.date(from: DateComponents(weekday: weekdayNumber))!
            return formatter.string(from: date)
        }
    }
    
    private func hasLog(for date: Date) -> Bool {
        return weightLogs.contains { log in
            Calendar.current.isDate(log.date, inSameDayAs: date)
        }
    }
    
    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: month) {
            withAnimation {
                month = newMonth
            }
        }
    }
    
    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: month) {
            withAnimation {
                month = newMonth
            }
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

struct WeightStatBox: View {
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
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Date extension for calendar view
extension Date {
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM yyyy"
        return formatter.string(from: self)
    }
}

#Preview {
    WeightProgressView(viewModel: WeightLogViewModel())
} 