//
//  HealthInsightsView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import SwiftData

struct HealthInsightsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.modelContext) private var modelContext
    let _insights: [HealthInsight]
    let _goals: [HealthGoal]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Score Card
                    HealthScoreCard(healthKitManager: healthKitManager)
                    
                    // Today's Summary
                    TodaySummaryCard(healthKitManager: healthKitManager, userSettings: userSettings)
                    
                    // Health Tips
                    HealthTipsSection()
                    
                    // Achievements Section
                    if !_goals.isEmpty {
                        AchievementsSection(goals: _goals)
                    }
                    
                    // Recent Insights
                    if !_insights.isEmpty {
                        RecentInsightsSection(insights: _insights)
                    }
                }
                .padding()
            }
            .navigationTitle("Health Insights")
            .onAppear {
                generateInsights()
            }
        }
    }
    
    private func generateInsights() {
        // Generate insights based on current data
        let todaySteps = healthKitManager.todaySteps
        let todayDistance = healthKitManager.todayDistance
        let todayCalories = healthKitManager.todayCalories
        
        // Check if we already have insights for today
        let today = Calendar.current.startOfDay(for: Date())
        let hasTodayInsights = _insights.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        if !hasTodayInsights {
            var newInsights: [HealthInsight] = []
            
            // Step-based insights
            if todaySteps >= 10000 {
                newInsights.append(HealthInsight(
                    title: "🎉 Goal Achieved!",
                    description: "You've reached your daily step goal of 10,000 steps! Great job!",
                    category: .achievement
                ))
            } else if todaySteps >= 5000 {
                newInsights.append(HealthInsight(
                    title: "💪 Halfway There!",
                    description: "You're halfway to your daily goal. Keep up the momentum!",
                    category: .improvement
                ))
            } else if todaySteps < 2000 {
                newInsights.append(HealthInsight(
                    title: "🚶‍♂️ Let's Get Moving!",
                    description: "Try taking a short walk to increase your step count today.",
                    category: .health
                ))
            }
            
            // Distance-based insights
            if todayDistance >= 8000 { // 8km
                newInsights.append(HealthInsight(
                    title: "🏃‍♂️ Distance Master!",
                    description: "You've covered over 8km today! That's excellent for your cardiovascular health.",
                    category: .achievement
                ))
            }
            
            // Calorie insights
            if todayCalories >= 500 {
                newInsights.append(HealthInsight(
                    title: "🔥 Calorie Burner!",
                    description: "You've burned over 500 calories through activity today!",
                    category: .achievement
                ))
            }
            
            // Add insights to the model
            for insight in newInsights {
                modelContext.insert(insight)
            }
        }
    }
}

struct HealthScoreCard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    private var healthScore: Int {
        let steps = healthKitManager.todaySteps
        let distance = healthKitManager.todayDistance
        let calories = healthKitManager.todayCalories
        
        var score = 0
        
        // Step scoring (0-40 points)
        if steps >= 10000 { score += 40 }
        else if steps >= 8000 { score += 30 }
        else if steps >= 6000 { score += 20 }
        else if steps >= 4000 { score += 10 }
        
        // Distance scoring (0-30 points)
        if distance >= 8000 { score += 30 }
        else if distance >= 6000 { score += 20 }
        else if distance >= 4000 { score += 10 }
        
        // Calorie scoring (0-30 points)
        if calories >= 500 { score += 30 }
        else if calories >= 300 { score += 20 }
        else if calories >= 150 { score += 10 }
        
        return min(score, 100)
    }
    
    private var scoreColor: Color {
        switch healthScore {
        case 80...100: return .green.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType)
        case 60..<80: return .yellow.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType)
        case 40..<60: return .orange.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType)
        default: return .red.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType)
        }
    }
    
    private var scoreDescription: String {
        switch healthScore {
        case 80...100: return "Excellent! You're doing great!"
        case 60..<80: return "Good job! Keep it up!"
        case 40..<60: return "Not bad! Try to be more active."
        default: return "Let's get moving today!"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Health Score")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: Double(healthScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [scoreColor, scoreColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: healthScore)
                
                Text("\(healthScore)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
            }
            
            Text(scoreDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct TodaySummaryCard: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Summary")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                SummaryRow(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(healthKitManager.todaySteps)",
                    color: .blue
                )
                
                SummaryRow(
                    icon: "location",
                    title: "Distance",
                    value: userSettings.formatDistance(healthKitManager.todayDistance),
                    color: .green
                )
                
                SummaryRow(
                    icon: "flame",
                    title: "Calories",
                    value: String(format: "%.0f", healthKitManager.todayCalories),
                    color: .orange
                )
                
                SummaryRow(
                    icon: "clock",
                    title: "Active Time",
                    value: "\(healthKitManager.todayActiveMinutes) min",
                    color: .purple
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color.adjustedForColorBlindness(userSettings.colorBlindnessType))
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct HealthTipsSection: View {
    private let tips = [
        "Take the stairs instead of the elevator",
        "Park further away to get extra steps",
        "Take a 5-minute walk every hour",
        "Walk during phone calls",
        "Use a standing desk if possible",
        "Take a walk after meals"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Tips")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(tips.prefix(3), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                            .frame(width: 20)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct RecentInsightsSection: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Insights")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(insights.suffix(3).reversed(), id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}

struct InsightCard: View {
    let insight: HealthInsight
    @StateObject private var userSettings = UserSettings.shared
    
    private var categoryColor: Color {
        switch insight.category {
        case .achievement: return .green.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .improvement: return .blue.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .trend: return .purple.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .goal: return .orange.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .health: return .red.adjustedForColorBlindness(userSettings.colorBlindnessType)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(categoryColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "star.fill")
                        .foregroundColor(categoryColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.insightDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct AchievementsSection: View {
    let goals: [HealthGoal]
    @StateObject private var userSettings = UserSettings.shared
    
    private var completedGoals: [HealthGoal] {
        goals.filter { $0.progress >= 1.0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow.adjustedForColorBlindness(userSettings.colorBlindnessType))
                    .font(.title2)
                
                Text("Achievements")
                    .font(.headline)
                
                Spacer()
                
                Text("\(completedGoals.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if completedGoals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Achievements Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete your first goal to unlock achievements!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(completedGoals.prefix(5), id: \.id) { goal in
                        AchievementCard(goal: goal)
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let goal: HealthGoal
    @StateObject private var userSettings = UserSettings.shared
    
    private var icon: String {
        switch goal.type {
        case .steps: return "figure.walk"
        case .distance: return "location"
        case .calories: return "flame"
        case .activeMinutes: return "clock"
        }
    }
    
    private var color: Color {
        switch goal.type {
        case .steps: return .blue.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .distance: return .green.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .calories: return .orange.adjustedForColorBlindness(userSettings.colorBlindnessType)
        case .activeMinutes: return .purple.adjustedForColorBlindness(userSettings.colorBlindnessType)
        }
    }
    
    private var formattedTargetValue: String {
        switch goal.type {
        case .steps:
            return "\(Int(goal.targetValue))"
        case .distance:
            if userSettings.unitSystem == .metric {
                return String(format: "%.1f", goal.targetValue / 1000) // Convert meters to km
            } else {
                let miles = goal.targetValue * 0.000621371 // Convert meters to miles
                return String(format: "%.1f", miles)
            }
        case .calories:
            return "\(Int(goal.targetValue))"
        case .activeMinutes:
            return "\(Int(goal.targetValue))"
        }
    }
    
    private var unit: String {
        switch goal.type {
        case .steps: return "steps"
        case .distance: return userSettings.unitSystem.distanceUnit
        case .calories: return "cal"
        case .activeMinutes: return "min"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Goal Completed!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green.adjustedForColorBlindness(userSettings.colorBlindnessType))
                        .font(.title3)
                }
                
                Text("\(goal.type.rawValue.capitalized) - \(formattedTargetValue) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(goal.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    HealthInsightsView(healthKitManager: HealthKitManager(), _insights: [], _goals: [])
}
