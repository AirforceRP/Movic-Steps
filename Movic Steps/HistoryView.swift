//
//  HistoryView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedPeriod: HistoryPeriod = .week
    @State private var weeklySteps: [Int] = []
    @State private var isLoading = false
    
    enum HistoryPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector
                    
                    // Stats Summary
                    statsSummary
                    
                    // Chart View
                    chartView
                    
                    // Detailed History
                    detailedHistory
                }
                .padding()
            }
            .navigationTitle("Step History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHistoryData()
            }
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(HistoryPeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                    loadHistoryData()
                }) {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedPeriod == period ? .white : .blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPeriod == period ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var statsSummary: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "Total Steps",
                value: formatNumber(weeklySteps.reduce(0, +)),
                icon: "figure.walk",
                color: .blue
            )
            
            StatCard(
                title: "Daily Average",
                value: formatNumber(weeklySteps.isEmpty ? 0 : weeklySteps.reduce(0, +) / weeklySteps.count),
                icon: "calendar",
                color: .green
            )
            
            StatCard(
                title: "Best Day",
                value: formatNumber(weeklySteps.max() ?? 0),
                icon: "trophy",
                color: .orange
            )
            
            StatCard(
                title: "Goal Days",
                value: "\(goalDaysCount)/\(weeklySteps.count)",
                icon: "target",
                color: .purple
            )
        }
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            } else {
                SimpleBarChart(data: weeklySteps, goal: userSettings.dailyStepGoal)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
    
    private var detailedHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Breakdown")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(weeklySteps.enumerated().reversed()), id: \.offset) { index, steps in
                    HistoryRow(
                        date: dateForIndex(index),
                        steps: steps,
                        goal: userSettings.dailyStepGoal,
                        distance: Double(steps) * 0.762 // Approximate meters per step
                    )
                }
            }
        }
    }
    
    private var goalDaysCount: Int {
        weeklySteps.filter { $0 >= userSettings.dailyStepGoal }.count
    }
    
    private func loadHistoryData() {
        isLoading = true
        
        // Simulate loading with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch selectedPeriod {
            case .week:
                weeklySteps = generateMockWeeklyData()
            case .month:
                weeklySteps = generateMockMonthlyData()
            case .year:
                weeklySteps = generateMockYearlyData()
            }
            isLoading = false
        }
    }
    
    private func generateMockWeeklyData() -> [Int] {
        return [6200, 8100, 7543, 9200, 6800, 10500, 7900]
    }
    
    private func generateMockMonthlyData() -> [Int] {
        return (0..<30).map { _ in Int.random(in: 4000...12000) }
    }
    
    private func generateMockYearlyData() -> [Int] {
        return (0..<12).map { _ in Int.random(in: 150000...350000) }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .week:
            return calendar.date(byAdding: .day, value: -(6 - index), to: Date()) ?? Date()
        case .month:
            return calendar.date(byAdding: .day, value: -(29 - index), to: Date()) ?? Date()
        case .year:
            return calendar.date(byAdding: .month, value: -(11 - index), to: Date()) ?? Date()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct SimpleBarChart: View {
    let data: [Int]
    let goal: Int
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 0, goal)
            let barWidth = geometry.size.width / CGFloat(data.count) - 8
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(value >= goal ? Color.green : Color.blue)
                            .frame(
                                width: barWidth,
                                height: max(4, (CGFloat(value) / CGFloat(maxValue)) * (geometry.size.height - 20))
                            )
                        
                        Text(dayLabel(for: index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -(data.count - 1 - index), to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct HistoryRow: View {
    let date: Date
    let steps: Int
    let goal: Int
    let distance: Double
    @StateObject private var userSettings = UserSettings.shared
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var progressPercentage: Double {
        return min(Double(steps) / Double(goal), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(userSettings.formatDistance(distance))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(steps)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(steps >= goal ? .green : .primary)
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress indicator
            Circle()
                .fill(steps >= goal ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    HistoryView(healthKitManager: HealthKitManager())
}
