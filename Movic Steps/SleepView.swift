//
//  SleepView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import HealthKit

struct SleepView: View {
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedTimeframe: TimeFrame = .today
    @State private var showingSleepChart = false
    @State private var showingSleepGoals = false
    
    enum TimeFrame: String, CaseIterable {
        case today = "today"
        case week = "week"
        case month = "month"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .today: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .year: return "This Year"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        SleepHeaderView()
                        
                    // Time frame selector
                    SleepTimeFrameSelector(selectedTimeframe: $selectedTimeframe)
                        
                        // Sleep summary card
                        SleepSummaryCard(
                            sleepData: sleepManager.todaySleepData,
                            goal: userSettings.dailySleepGoal
                        )
                        
                        // Sleep stages
                        SleepStagesView(stages: sleepManager.todaySleepStages)
                        
                        // Sleep metrics
                        SleepMetricsView(
                            totalSleep: sleepManager.todaySleepData.totalSleep,
                            deepSleep: sleepManager.todaySleepData.deepSleep,
                            lightSleep: sleepManager.todaySleepData.lightSleep,
                            remSleep: sleepManager.todaySleepData.remSleep
                        )
                        
                        // Sleep trends
                        SleepTrendsView(weeklyData: sleepManager.weeklySleepData)
                        
                        // Quick actions
                        SleepQuickActionsView(
                            onViewChart: { showingSleepChart = true },
                            onSetGoals: { showingSleepGoals = true },
                            onRefresh: { sleepManager.fetchSleepData() }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            sleepManager.fetchSleepData()
        }
        .sheet(isPresented: $showingSleepChart) {
            SleepChartView(data: sleepManager.todaySleepStages)
        }
        .sheet(isPresented: $showingSleepGoals) {
            SleepGoalsView()
        }
        .onAppear {
            if !sleepManager.isAuthorized {
                sleepManager.requestAuthorization()
            } else {
                sleepManager.fetchSleepData()
            }
        }
    }
}

// MARK: - Header View
struct SleepHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Monitor your sleep quality and patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "moon.fill")
                .font(.title)
                .foregroundColor(.indigo)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Time Frame Selector
struct SleepTimeFrameSelector: View {
    @Binding var selectedTimeframe: SleepView.TimeFrame
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(SleepView.TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: { selectedTimeframe = timeframe }) {
                    Text(timeframe.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeframe == timeframe ? Color.indigo : Color(.systemGray6))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Sleep Summary Card
struct SleepSummaryCard: View {
    let sleepData: SleepData
    let goal: Int
    @State private var moonAnimation = false
    
    private var sleepQuality: SleepQuality {
        let percentage = (sleepData.totalSleep / Double(goal)) * 100
        switch percentage {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .fair
        default: return .poor
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last Night's Sleep")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sleepQuality.color)
                            .frame(width: 8, height: 8)
                        
                        Text(sleepQuality.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(sleepQuality.color)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(moonAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: moonAnimation)
                    
                    Image(systemName: "moon.fill")
                        .font(.title2)
                        .foregroundColor(.indigo)
                        .rotationEffect(.degrees(moonAnimation ? 5 : -5))
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moonAnimation)
                }
            }
            
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(formatSleepTime(sleepData.totalSleep))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text("hours")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                if sleepData.totalSleep > 0 {
                    Text("of \(goal) hour goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Sleep goal progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sleep Goal Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(sleepData.totalSleep))/\(goal) hours")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [sleepQuality.color, sleepQuality.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(min(sleepData.totalSleep / Double(goal), 1.0)) * 200, height: 8)
                        .animation(.easeInOut(duration: 1.0), value: sleepData.totalSleep)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            moonAnimation = true
        }
    }
    
    private func formatSleepTime(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

// MARK: - Sleep Stages
struct SleepStagesView: View {
    let stages: [SleepStage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Stages")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(stages) { stage in
                    SleepStageRow(stage: stage)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Sleep Stage Row
struct SleepStageRow: View {
    let stage: SleepStage
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(stage.color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(stage.duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(stage.percentage))%")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(stage.color.opacity(0.1))
        )
    }
}

// MARK: - Sleep Metrics
struct SleepMetricsView: View {
    let totalSleep: Double
    let deepSleep: Double
    let lightSleep: Double
    let remSleep: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Breakdown")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SleepMetricCard(
                    title: "Deep Sleep",
                    value: String(format: "%.1f", deepSleep),
                    unit: "hrs",
                    color: .blue,
                    icon: "moon.zzz"
                )
                
                SleepMetricCard(
                    title: "Light Sleep",
                    value: String(format: "%.1f", lightSleep),
                    unit: "hrs",
                    color: .green,
                    icon: "moon"
                )
                
                SleepMetricCard(
                    title: "REM Sleep",
                    value: String(format: "%.1f", remSleep),
                    unit: "hrs",
                    color: .purple,
                    icon: "brain.head.profile"
                )
                
                SleepMetricCard(
                    title: "Total Sleep",
                    value: String(format: "%.1f", totalSleep),
                    unit: "hrs",
                    color: .indigo,
                    icon: "bed.double"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Sleep Trends
struct SleepTrendsView: View {
    let weeklyData: [SleepData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Sleep Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            if weeklyData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No sleep data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Simple bar chart representation
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, data in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.indigo)
                                .frame(width: 20, height: CGFloat(data.totalSleep) * 10)
                            
                            Text(Calendar.current.shortWeekdaySymbols[index])
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 120)
                .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Quick Actions
struct SleepQuickActionsView: View {
    let onViewChart: () -> Void
    let onSetGoals: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Sleep Chart",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ) {
                    onViewChart()
                }
                
                QuickActionButton(
                    title: "Set Goals",
                    icon: "target",
                    color: .green
                ) {
                    onSetGoals()
                }
                
                QuickActionButton(
                    title: "Refresh Data",
                    icon: "arrow.clockwise",
                    color: .orange
                ) {
                    onRefresh()
                }
                
                QuickActionButton(
                    title: "Sleep Tips",
                    icon: "lightbulb",
                    color: .purple
                ) {
                    // Sleep tips action
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Sleep Chart View
struct SleepChartView: View {
    let data: [SleepStage]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if data.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Sleep Data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Enable sleep tracking to see your sleep stages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    Text("Sleep Stages Chart")
                        .font(.headline)
                        .padding()
                    
                    // Simple representation of sleep stages
                    LazyVStack(spacing: 8) {
                        ForEach(data) { stage in
                            HStack {
                                Circle()
                                    .fill(stage.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(stage.name)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(stage.duration)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Sleep Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sleep Goals View
struct SleepGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @State private var sleepGoal: Double = 8.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Set Your Sleep Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("\(String(format: "%.1f", sleepGoal)) hours")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Slider(value: $sleepGoal, in: 4...12, step: 0.5)
                        .accentColor(.indigo)
                    
                    HStack {
                        Text("4 hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("12 hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sleep Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userSettings.dailySleepGoal = Int(sleepGoal)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            sleepGoal = Double(userSettings.dailySleepGoal)
        }
    }
}

// MARK: - Data Models
struct SleepData {
    let totalSleep: Double
    let deepSleep: Double
    let lightSleep: Double
    let remSleep: Double
    let bedTime: Date?
    let wakeTime: Date?
}

struct SleepStage: Identifiable {
    let id = UUID()
    let name: String
    let duration: String
    let percentage: Double
    let color: Color
}

enum SleepQuality {
    case excellent, good, fair, poor
    
    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - Sleep Metric Card
struct SleepMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    SleepView()
}
