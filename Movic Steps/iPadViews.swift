//
//  iPadViews.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/18/25.
//

import SwiftUI
import HealthKit

// MARK: - iPad Step Tracking View
struct iPadStepTrackingViewWrapper: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var stepCounter = AccelerometerStepCounter()
    @State private var selectedStepSource: StepTrackingView.StepSource = .healthKit
    @State private var isTrackingSteps = false
    
    private var currentSteps: Int {
        switch selectedStepSource {
        case .healthKit:
            return healthKitManager.todaySteps
        case .accelerometer:
            return stepCounter.currentSteps
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 32) {
                    if !healthKitManager.isAuthorized && selectedStepSource == .healthKit {
                        ModernPermissionView(healthKitManager: healthKitManager)
                            .frame(maxWidth: .infinity)
                    } else {
                        // iPad-optimized two-column layout
                        HStack(alignment: .top, spacing: 32) {
                            // Left Column - Main Step Counter
                            VStack(spacing: 24) {
                                StepSourceSelector(
                                    selectedSource: $selectedStepSource,
                                    isTracking: $isTrackingSteps,
                                    stepCounter: stepCounter
                                )
                                
                                ModernStepCounterCard(
                                    steps: currentSteps,
                                    goal: userSettings.dailyStepGoal,
                                    isLoading: healthKitManager.isLoading,
                                    source: selectedStepSource
                                )
                                .frame(height: 300)
                                
                                ModernQuickActionsView(
                                    healthKitManager: healthKitManager,
                                    stepCounter: stepCounter,
                                    isTracking: $isTrackingSteps,
                                    selectedSource: selectedStepSource
                                )
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Right Column - Metrics and Progress
                            VStack(spacing: 24) {
                                // Today's Progress Ring
                                iPadProgressRingCard(
                                    steps: currentSteps,
                                    goal: userSettings.dailyStepGoal
                                )
                                
                                // Health Metrics Grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                    ModernMetricCard(
                                        title: "Distance",
                                        value: userSettings.formatDistance(healthKitManager.todayDistance),
                                        icon: "location.fill",
                                        color: .blue,
                                        trend: .up
                                    )
                                    
                                    ModernMetricCard(
                                        title: "Calories",
                                        value: String(format: "%.0f", healthKitManager.todayCalories),
                                        icon: "flame.fill",
                                        color: .orange,
                                        trend: .stable
                                    )
                                    
                                    ModernMetricCard(
                                        title: "Active Time",
                                        value: "\(healthKitManager.todayActiveMinutes) min",
                                        icon: "clock.fill",
                                        color: .green,
                                        trend: .up
                                    )
                                    
                                    ModernMetricCard(
                                        title: "Avg Pace",
                                        value: userSettings.formatSpeed(calculateAveragePace()),
                                        icon: "speedometer",
                                        color: .purple,
                                        trend: .stable
                                    )
                                }
                                
                                // Weekly Progress Chart
                                iPadWeeklyProgressCard(healthKitManager: healthKitManager)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.02),
                    Color.pink.opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            if userSettings.preferredStepSource == .healthKit {
                selectedStepSource = .healthKit
                if !healthKitManager.isAuthorized {
                    healthKitManager.requestAuthorization()
                } else {
                    healthKitManager.fetchTodayData()
                }
            } else {
                selectedStepSource = .accelerometer
                stepCounter.startTracking()
            }
        }
        .onDisappear {
            stepCounter.stopTracking()
        }
    }
    
    private func calculateAveragePace() -> Double {
        guard healthKitManager.todayActiveMinutes > 0, healthKitManager.todayDistance > 0 else { return 0 }
        return healthKitManager.todayDistance / (Double(healthKitManager.todayActiveMinutes) * 60)
    }
}

// MARK: - iPad Health Insights View
struct iPadHealthInsightsViewWrapper: View {
    @ObservedObject var healthKitManager: HealthKitManager
    let insights: [HealthInsight]
    let goals: [HealthGoal]
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // iPad-optimized three-column layout
                HStack(alignment: .top, spacing: 24) {
                    // Left Column - Health Score
                    VStack(spacing: 20) {
                        HealthScoreCard(healthKitManager: healthKitManager)
                            .frame(height: 200)
                        
                        TodaySummaryCard(healthKitManager: healthKitManager, userSettings: userSettings)
                            .frame(height: 180)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Middle Column - Insights & Achievements
                    VStack(spacing: 20) {
                        if !goals.isEmpty {
                            AchievementsSection(goals: goals)
                        }
                        
                        if !insights.isEmpty {
                            RecentInsightsSection(insights: insights)
                        } else {
                            iPadEmptyInsightsCard()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column - Health Tips
                    VStack(spacing: 20) {
                        HealthTipsSection()
                        
                        iPadHealthStatsCard(healthKitManager: healthKitManager)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.green.opacity(0.03),
                    Color.blue.opacity(0.02),
                    Color.white.opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - iPad Goals View
struct iPadGoalsViewWrapper: View {
    @ObservedObject var healthKitManager: HealthKitManager
    let goals: [HealthGoal]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddGoal = false
    @State private var showingEditGoal: HealthGoal?
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: HealthGoal?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // iPad-optimized layout
                VStack(spacing: 24) {
                    // Header with Add Goal button
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Your Health Goals")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Track your progress towards better health")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingAddGoal = true }) {
                            Label("Add Goal", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Goals Grid - 3 columns on iPad
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                        ForEach(goals.filter { $0.isActive }) { goal in
                            GoalCard(goal: goal)
                                .frame(height: 160)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Delete action
                                    Button(role: .destructive) {
                                        goalToDelete = goal
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    // Edit action
                                    Button {
                                        print("Edit button tapped for goal: \(goal.type)")
                                        showingEditGoal = goal
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    if !goals.filter({ !$0.isActive }).isEmpty {
                        // Achievement History - 2 columns on iPad
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Achievement History")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 32)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                ForEach(goals.filter { !$0.isActive }) { goal in
                                    CompletedGoalCard(goal: goal)
                                        .frame(height: 120)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .sheet(item: $showingEditGoal) { goal in
            EditGoalView(goal: goal)
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                goalToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete {
                    modelContext.delete(goal)
                    goalToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
        .onAppear {
            updateGoalProgress()
        }
    }
    
    private func updateGoalProgress() {
        for goal in goals where goal.isActive {
            switch goal.type {
            case .steps:
                goal.currentValue = Double(healthKitManager.todaySteps)
            case .distance:
                goal.currentValue = healthKitManager.todayDistance
            case .calories:
                goal.currentValue = healthKitManager.todayCalories
            case .activeMinutes:
                goal.currentValue = Double(healthKitManager.todayActiveMinutes)
            }
            
            // Progress is calculated automatically in the model
        }
    }
}

// MARK: - iPad Trends View
struct iPadTrendsViewWrapper: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedPeriod: TrendsView.TimePeriod = .week
    @State private var weeklySteps: [Int] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Period Selector
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(TrendsView.TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 32)
                
                // iPad-optimized trends layout
                HStack(alignment: .top, spacing: 32) {
                    // Left Column - Charts
                    VStack(spacing: 24) {
                        iPadTrendsChartCard(
                            title: "Steps Trend",
                            data: weeklySteps,
                            period: selectedPeriod
                        )
                        .frame(height: 300)
                        
                        iPadTrendsChartCard(
                            title: "Weekly Average",
                            data: weeklySteps,
                            period: selectedPeriod
                        )
                        .frame(height: 200)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column - Stats
                    VStack(spacing: 24) {
                        iPadTrendsStatsCard(weeklySteps: weeklySteps)
                            .frame(height: 250)
                        
                        iPadTrendsSummaryCard(
                            weeklySteps: weeklySteps,
                            selectedPeriod: selectedPeriod
                        )
                        .frame(height: 250)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            healthKitManager.fetchWeeklySteps { steps in
                weeklySteps = steps
            }
        }
        .onChange(of: selectedPeriod) { _ in
            healthKitManager.fetchWeeklySteps { steps in
                weeklySteps = steps
            }
        }
    }
}

// MARK: - iPad Settings View
struct iPadSettingsViewWrapper: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 32) {
                    // iPad-optimized settings layout - Two columns
                    HStack(alignment: .top, spacing: 32) {
                        // Left Column
                        VStack(spacing: 24) {
                            iPadSettingsSection(title: "Units & Display") {
                                iPadUnitSystemSettings()
                            }
                            
                            iPadSettingsSection(title: "Personal Information") {
                                iPadPersonalInfoSettings()
                            }
                            
                            iPadSettingsSection(title: "Data Management") {
                                iPadDataManagementSettings()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column
                        VStack(spacing: 24) {
                            iPadSettingsSection(title: "Step Tracking") {
                                iPadStepTrackingSettings()
                            }
                            
                            iPadSettingsSection(title: "Notifications") {
                                iPadNotificationSettings()
                            }
                            
                            iPadSettingsSection(title: "About") {
                                iPadAboutSettings()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - iPad Helper Components

struct iPadProgressRingCard: View {
    let steps: Int
    let goal: Int
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }
    
    var body: some View {
        GlassmorphismCard {
            VStack(spacing: 16) {
                Text("Today's Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ZStack {
                    AnimatedProgressRing(
                        progress: progress,
                        lineWidth: 12,
                        size: 120,
                        colors: [.blue, .purple]
                    )
                    .frame(width: 120, height: 120)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("\(steps)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("/ \(goal) steps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct iPadWeeklyProgressCard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @State private var weeklySteps: [Int] = []
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weekly Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if weeklySteps.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                        .overlay(
                            Text("Loading...")
                                .foregroundColor(.secondary)
                        )
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(weeklySteps.enumerated()), id: \.offset) { index, steps in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor.opacity(0.7))
                                    .frame(width: 20, height: CGFloat(steps) / 200.0 + 10)
                                
                                Text(dayAbbreviation(for: index))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 100)
                }
            }
        }
        .onAppear {
            healthKitManager.fetchWeeklySteps { steps in
                weeklySteps = steps
            }
        }
    }
    
    private func dayAbbreviation(for index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[index % 7]
    }
}

struct iPadEmptyInsightsCard: View {
    var body: some View {
        GlassmorphismCard {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("No Insights Yet")
                    .font(.headline)
                
                Text("Keep tracking your steps to generate personalized health insights.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
        }
    }
}

struct iPadHealthStatsCard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Stats")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Steps:")
                        Spacer()
                        Text("\(healthKitManager.todaySteps)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Distance:")
                        Spacer()
                        Text(UserSettings.shared.formatDistance(healthKitManager.todayDistance))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Calories:")
                        Spacer()
                        Text("\(Int(healthKitManager.todayCalories))")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Active Time:")
                        Spacer()
                        Text("\(healthKitManager.todayActiveMinutes) min")
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - iPad Settings Components

struct iPadSettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            GlassmorphismCard {
                content
            }
        }
    }
}

struct iPadUnitSystemSettings: View {
    @StateObject private var settings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Unit System", selection: $settings.unitSystem) {
                ForEach(UnitSystem.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(spacing: 8) {
                HStack {
                    Label("Distance", systemImage: "location")
                    Spacer()
                    Text(settings.unitSystem.distanceUnit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Weight", systemImage: "scalemass")
                    Spacer()
                    Text(settings.unitSystem.weightUnit)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct iPadPersonalInfoSettings: View {
    @StateObject private var settings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight: \(settings.formatUserWeight())")
                    .font(.subheadline)
                Slider(value: $settings.userWeight, in: 30...200, step: 0.5)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Height: \(settings.formatUserHeight())")
                    .font(.subheadline)
                Slider(value: $settings.userHeight, in: 100...250, step: 1)
            }
        }
    }
}

struct iPadStepTrackingSettings: View {
    @StateObject private var settings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Preferred Source", selection: $settings.preferredStepSource) {
                ForEach(StepTrackingSource.allCases) { source in
                    Text(source.displayName).tag(source)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Step Sensitivity: \(settings.stepSensitivity.displayName)")
                    .font(.subheadline)
                Picker("Sensitivity", selection: $settings.stepSensitivity) {
                    ForEach(StepSensitivity.allCases) { sensitivity in
                        Text(sensitivity.displayName).tag(sensitivity)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct iPadNotificationSettings: View {
    @StateObject private var settings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Toggle("Enable Notifications", isOn: $settings.enableNotifications)
            
            if settings.enableNotifications {
                Picker("Goal Reminder", selection: $settings.goalReminderTime) {
                    ForEach(GoalReminderTime.allCases) { time in
                        Text(time.displayName).tag(time)
                    }
                }
            }
            
            Toggle("Weekly Progress Report", isOn: $settings.showWeeklyReport)
        }
    }
}

struct iPadDataManagementSettings: View {
    @StateObject private var settings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                settings.resetToDefaults()
            }) {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.red)
            }
            
            Toggle("Privacy Mode", isOn: $settings.privacyMode)
        }
    }
}

struct iPadAboutSettings: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Build", systemImage: "hammer")
                Spacer()
                Text("1")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - iPad Trends Components

struct iPadTrendsChartCard: View {
    let title: String
    let data: [Int]
    let period: TrendsView.TimePeriod
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                
                if data.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 150)
                        .overlay(
                            Text("Loading...")
                                .foregroundColor(.secondary)
                        )
                } else {
                    // Simple bar chart representation
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, steps in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.7))
                                .frame(width: 20, height: max(CGFloat(steps) / 200.0, 5))
                        }
                    }
                    .frame(height: 150)
                }
            }
        }
    }
}

struct iPadTrendsStatsCard: View {
    let weeklySteps: [Int]
    
    private var totalSteps: Int {
        weeklySteps.reduce(0, +)
    }
    
    private var averageSteps: Int {
        guard !weeklySteps.isEmpty else { return 0 }
        return totalSteps / weeklySteps.count
    }
    
    private var maxSteps: Int {
        weeklySteps.max() ?? 0
    }
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Statistics")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Steps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(totalSteps)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Daily Average")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(averageSteps)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Image(systemName: "chart.bar")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Best Day")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(maxSteps)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

struct iPadTrendsSummaryCard: View {
    let weeklySteps: [Int]
    let selectedPeriod: TrendsView.TimePeriod
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(selectedPeriod.rawValue) Summary")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    Text("You're doing great! Keep up the consistent activity to maintain your health goals.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !weeklySteps.isEmpty {
                        let trend = calculateTrend()
                        HStack {
                            Image(systemName: trend.icon)
                                .foregroundColor(trend.color)
                            Text(trend.description)
                                .font(.subheadline)
                                .foregroundColor(trend.color)
                        }
                    }
                }
            }
        }
    }
    
    private func calculateTrend() -> (icon: String, color: Color, description: String) {
        guard weeklySteps.count >= 2 else {
            return ("minus", .gray, "Not enough data")
        }
        
        let recent = Array(weeklySteps.suffix(3))
        let older = Array(weeklySteps.prefix(3))
        
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let olderAvg = Double(older.reduce(0, +)) / Double(older.count)
        
        if recentAvg > olderAvg * 1.1 {
            return ("arrow.up", .green, "Trending up!")
        } else if recentAvg < olderAvg * 0.9 {
            return ("arrow.down", .red, "Trending down")
        } else {
            return ("minus", .blue, "Staying consistent")
        }
    }
}

// MARK: - Additional Helper Components

struct CompletedGoalCard: View {
    let goal: HealthGoal
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(goal.type.rawValue.capitalized)
                        .font(.headline)
                        .strikethrough()
                    Spacer()
                }
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                
                Text("Target: \(Int(goal.targetValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

