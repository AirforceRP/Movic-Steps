//
//  TrendsView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import Charts

struct TrendsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedMetric: MetricType = .steps
    @State private var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    @State private var weeklyCalories: [Double] = Array(repeating: 0, count: 7)
    @State private var weeklyActiveMinutes: [Int] = Array(repeating: 0, count: 7)
    @State private var isLoading = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    enum MetricType: String, CaseIterable, Identifiable {
        case steps = "Steps"
        case calories = "Calories"
        case activeMinutes = "Active Minutes"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .steps: return "figure.walk"
            case .calories: return "flame"
            case .activeMinutes: return "clock"
            }
        }
        
        var color: Color {
            switch self {
            case .steps: return .blue
            case .calories: return .orange
            case .activeMinutes: return .green
            }
        }
        
        var unit: String {
            switch self {
            case .steps: return "steps"
            case .calories: return "cal"
            case .activeMinutes: return "min"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    PeriodSelector(selectedPeriod: $selectedPeriod)
                    
                    // Metric Selector
                    MetricSelector(selectedMetric: $selectedMetric)
                    
                    // Main Chart
                    MetricChart(
                        data: chartData,
                        period: selectedPeriod,
                        metric: selectedMetric,
                        isLoading: isLoading
                    )
                    
                    // Statistics Cards
                    StatisticsSection(
                        healthKitManager: healthKitManager,
                        period: selectedPeriod,
                        metric: selectedMetric
                    )
                    
                    // Trend Analysis
                    TrendAnalysisSection(
                        data: currentData,
                        period: selectedPeriod,
                        metric: selectedMetric
                    )
                }
                .padding()
            }
            .navigationTitle("Trends")
            .onAppear {
                loadData()
            }
            .onChange(of: selectedPeriod) {
                loadData()
            }
            .onChange(of: selectedMetric) {
                loadData()
            }
        }
    }
    
    private var chartData: [ChartDataPoint] {
        switch selectedPeriod {
        case .week:
            return getWeeklyData().enumerated().map { index, value in
                ChartDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: index - 6, to: Date()) ?? Date(),
                    value: Int(value),
                    label: dayLabels[index]
                )
            }
        case .month:
            // For demo purposes, generate sample monthly data
            return generateMonthlyData()
        case .year:
            // For demo purposes, generate sample yearly data
            return generateYearlyData()
        case .year:
            // For demo purposes, generate sample 5-year data
            return generateFiveYearData()
        }
    }
    
    private var currentData: [Double] {
        switch selectedMetric {
        case .steps:
            return weeklySteps.map { Double($0) }
        case .calories:
            return weeklyCalories
        case .activeMinutes:
            return weeklyActiveMinutes.map { Double($0) }
        }
    }
    
    private func getWeeklyData() -> [Double] {
        switch selectedMetric {
        case .steps:
            return weeklySteps.map { Double($0) }
        case .calories:
            return weeklyCalories
        case .activeMinutes:
            return weeklyActiveMinutes.map { Double($0) }
        }
    }
    
    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let today = Date()
        return (0..<7).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: dayOffset - 6, to: today) ?? today
            return formatter.string(from: date)
        }
    }
    
    private func loadData() {
        isLoading = true
        
        switch selectedPeriod {
        case .week:
            // Load steps data
            healthKitManager.fetchWeeklySteps { steps in
                DispatchQueue.main.async {
                    self.weeklySteps = steps
                    self.loadWeeklyCaloriesAndActiveMinutes()
                }
            }
        case .month:
            // Simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isLoading = false
            }
        case .year:
            // Simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isLoading = false
            }
        case .year:
            // Simulate loading 5-year data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isLoading = false
            }
        }
    }
    
    private func loadWeeklyCaloriesAndActiveMinutes() {
        // Calculate calories and active minutes for each day based on steps
        for (index, steps) in weeklySteps.enumerated() {
            let distance = userSettings.calculateDistanceFromSteps(steps)
            let calories = userSettings.calculateCaloriesBurned(steps: steps, distance: distance)
            let activeMinutes = userSettings.calculateActiveMinutes(steps: steps, distance: distance)
            
            weeklyCalories[index] = calories
            weeklyActiveMinutes[index] = activeMinutes
        }
        
        isLoading = false
    }
    
    private func generateMonthlyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -29 + dayOffset, to: today) ?? today
            let steps = Int.random(in: 3000...12000)
            return ChartDataPoint(
                date: date,
                value: steps,
                label: calendar.component(.day, from: date).description
            )
        }
    }
    
    private func generateYearlyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<12).map { monthOffset in
            let date = calendar.date(byAdding: .month, value: -11 + monthOffset, to: today) ?? today
            let steps = Int.random(in: 150000...400000)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return ChartDataPoint(
                date: date,
                value: steps,
                label: formatter.string(from: date)
            )
        }
    }
    
    private func generateFiveYearData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<5).map { yearOffset in
            let date = calendar.date(byAdding: .year, value: -4 + yearOffset, to: today) ?? today
            let value = selectedMetric == .steps ? Int.random(in: 3000000...5000000) :
                       selectedMetric == .calories ? Int.random(in: 120000...200000) :
                       Int.random(in: 20000...35000)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return ChartDataPoint(
                date: date,
                value: value,
                label: formatter.string(from: date)
            )
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    let label: String
}

struct PeriodSelector: View {
    @Binding var selectedPeriod: TrendsView.TimePeriod
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(TrendsView.TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct MetricSelector: View {
    @Binding var selectedMetric: TrendsView.MetricType
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(TrendsView.MetricType.allCases) { metric in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMetric = metric
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: metric.icon)
                            .font(.title2)
                            .foregroundColor(selectedMetric == metric ? .white : metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType))
                        
                        Text(metric.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMetric == metric ? .white : .primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMetric == metric ? metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType) : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct MetricChart: View {
    let data: [ChartDataPoint]
    let period: TrendsView.TimePeriod
    let metric: TrendsView.MetricType
    let isLoading: Bool
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType))
                    .font(.title2)
                
                Text("\(metric.rawValue) Trend")
                    .font(.headline)
                
                Spacer()
            }
            
            if isLoading {
                ProgressView("Loading...")
                    .frame(height: 200)
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(metric.rawValue, point.value)
                    )
                    .foregroundStyle(metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(metric.rawValue, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType).opacity(0.3), metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType).opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: period == .week ? .day : .month)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(formatYAxisValue(intValue))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatYAxisValue(_ value: Int) -> String {
        switch metric {
        case .steps:
            return "\(value / 1000)K"
        case .calories:
            return "\(value)"
        case .activeMinutes:
            return "\(value)"
        }
    }
}

struct StatisticsSection: View {
    @ObservedObject var healthKitManager: HealthKitManager
    let period: TrendsView.TimePeriod
    let metric: TrendsView.MetricType
    @StateObject private var userSettings = UserSettings.shared
    
    private var currentValue: Double {
        switch metric {
        case .steps:
            return Double(healthKitManager.todaySteps)
        case .calories:
            return healthKitManager.todayCalories
        case .activeMinutes:
            return Double(healthKitManager.todayActiveMinutes)
        }
    }
    
    private var averageValue: Double {
        switch period {
        case .week:
            return currentValue // Simplified for demo
        case .month:
            return metric == .steps ? 8500 : (metric == .calories ? 350 : 60) // Sample data
        case .year:
            return metric == .steps ? 9200 : (metric == .calories ? 380 : 65) // Sample data
        case .year:
            return metric == .steps ? 9500 : (metric == .calories ? 400 : 70) // Sample 5-year data
        }
    }
    
    private var maxValue: Double {
        switch period {
        case .week:
            return currentValue * 1.3 // Simplified for demo
        case .month:
            return metric == .steps ? 15000 : (metric == .calories ? 500 : 90) // Sample data
        case .year:
            return metric == .steps ? 18000 : (metric == .calories ? 600 : 100) // Sample data
        case .year:
            return metric == .steps ? 20000 : (metric == .calories ? 700 : 120) // Sample 5-year data
        }
    }
    
    private var totalValue: Double {
        switch period {
        case .week:
            return currentValue * 7 // Simplified for demo
        case .month:
            return metric == .steps ? 255000 : (metric == .calories ? 10500 : 1800) // Sample data
        case .year:
            return metric == .steps ? 3300000 : (metric == .calories ? 136500 : 23400) // Sample data
        case .year:
            return metric == .steps ? 16500000 : (metric == .calories ? 682500 : 117000) // Sample 5-year data
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                TrendsStatCard(
                    title: "Average",
                    value: formatValue(averageValue),
                    subtitle: "\(metric.unit)/day",
                    color: metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType)
                )
                
                TrendsStatCard(
                    title: "Maximum",
                    value: formatValue(maxValue),
                    subtitle: metric.unit,
                    color: .green.adjustedForColorBlindness(userSettings.colorBlindnessType)
                )
                
                TrendsStatCard(
                    title: "Total",
                    value: formatTotalValue(totalValue),
                    subtitle: metric.unit,
                    color: .orange.adjustedForColorBlindness(userSettings.colorBlindnessType)
                )
            }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .steps:
            return "\(Int(value))"
        case .calories:
            return String(format: "%.0f", value)
        case .activeMinutes:
            return "\(Int(value))"
        }
    }
    
    private func formatTotalValue(_ value: Double) -> String {
        switch metric {
        case .steps:
            return "\(Int(value / 1000))K"
        case .calories:
            return String(format: "%.0f", value)
        case .activeMinutes:
            return "\(Int(value))"
        }
    }
}

struct TrendsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color.adjustedForColorBlindness(userSettings.colorBlindnessType))
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct TrendAnalysisSection: View {
    let data: [Double]
    let period: TrendsView.TimePeriod
    let metric: TrendsView.MetricType
    @StateObject private var userSettings = UserSettings.shared
    
    private var trendDirection: TrendDirection {
        guard data.count >= 2 else { return .stable }
        
        let recent = Array(data.suffix(3))
        let older = Array(data.prefix(3))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        if recentAvg > olderAvg * 1.1 {
            return .increasing
        } else if recentAvg < olderAvg * 0.9 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private var trendDescription: String {
        let metricName = metric.rawValue.lowercased()
        switch trendDirection {
        case .increasing:
            return "Your \(metricName) is trending upward! Keep up the great work."
        case .decreasing:
            return "Your \(metricName) has decreased recently. Try to get back on track."
        case .stable:
            return "Your \(metricName) level is consistent. Consider setting new goals."
        }
    }
    
    private var trendColor: Color {
        switch trendDirection {
        case .increasing: return .green.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .decreasing: return .red.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .stable: return metric.color.adjustedForColorBlindness(userSettings.colorBlindnessType)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Analysis")
                .font(.headline)
            
            HStack {
                Image(systemName: trendDirection.icon)
                    .foregroundColor(trendColor)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(trendDescription)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Based on your \(period.rawValue.lowercased()) \(metric.rawValue.lowercased()) data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(trendColor.opacity(0.1))
            )
        }
    }
}

enum TrendDirection {
    case increasing, decreasing, stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

#Preview {
    TrendsView(healthKitManager: HealthKitManager())
}
