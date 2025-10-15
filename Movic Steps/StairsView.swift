//
//  StairsView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import HealthKit

struct StairsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTimeframe: TimeFrame = .today
    
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
    
    private var currentFloors: Int {
        return healthKitManager.todayFloors
    }
    
    private var goalFloors: Int {
        userSettings.dailyStairsGoal
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header
                    StairsHeaderView()
                    
                    // Time frame selector
                    TimeFrameSelector(selectedTimeframe: $selectedTimeframe)
                    
                    // Main stairs counter
                    StairsCounterCard(
                        floors: currentFloors,
                        goal: goalFloors,
                        timeframe: selectedTimeframe
                    )
                    
                    // Stairs metrics grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        StairsMetricCard(
                            title: "Floors Climbed",
                            value: "\(currentFloors)",
                            icon: "building.2.fill",
                            color: .indigo,
                            trend: .up
                        )
                        
                        StairsMetricCard(
                            title: "Calories Burned",
                            value: "\(calculateStairsCalories())",
                            icon: "flame.fill",
                            color: .orange,
                            trend: .stable
                        )
                        
                        StairsMetricCard(
                            title: "Active Time",
                            value: "\(calculateStairsTime()) min",
                            icon: "clock.fill",
                            color: .green,
                            trend: .up
                        )
                        
                        StairsMetricCard(
                            title: "Goal Progress",
                            value: "\(Int((Double(currentFloors) / Double(goalFloors)) * 100))%",
                            icon: "target",
                            color: .purple,
                            trend: .up
                        )
                    }
                    
                    // Quick actions
                    QuickActionsSection()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Stairs")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            refreshData()
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        healthKitManager.fetchTodayData()
    }
    
    private func calculateStairsCalories() -> Int {
        // Estimate calories burned climbing stairs
        // Roughly 0.17 calories per floor climbed
        return Int(Double(currentFloors) * 0.17)
    }
    
    private func calculateStairsTime() -> Int {
        // Estimate time spent climbing stairs
        // Roughly 1 minute per 3 floors
        return Int(Double(currentFloors) / 3.0)
    }
}

// MARK: - Header View
struct StairsHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stair Climbing")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track your stair climbing progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
struct TimeFrameSelector: View {
    @Binding var selectedTimeframe: StairsView.TimeFrame
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(StairsView.TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeframe = timeframe
                    }
                }) {
                    Text(timeframe.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Stairs Counter Card
struct StairsCounterCard: View {
    let floors: Int
    let goal: Int
    let timeframe: StairsView.TimeFrame
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(floors) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Floors Climbed")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(timeframe.displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8), .white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progress)
                
                VStack(spacing: 8) {
                    Text("\(floors)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("floors")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            HStack {
                Text("Goal: \(goal) floors")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(Int(progress * 100))% complete")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.indigo, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Stairs Metric Card
struct StairsMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, stable
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Set Goal",
                    icon: "target",
                    color: .blue
                ) {
                    // Goal setting action
                }
                
                QuickActionButton(
                    title: "View History",
                    icon: "chart.bar",
                    color: .green
                ) {
                    // History action
                }
                
                QuickActionButton(
                    title: "Share Progress",
                    icon: "square.and.arrow.up",
                    color: .orange
                ) {
                    // Share action
                }
                
                QuickActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.down",
                    color: .purple
                ) {
                    // Export action
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


// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {}
    }
}

// MARK: - Stairs Goal Setting View
struct StairsGoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @State private var goalValue: Int = 10
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set Daily Stairs Goal")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How many floors would you like to climb each day?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    Text("\(goalValue) floors")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Slider(value: Binding(
                        get: { Double(goalValue) },
                        set: { goalValue = Int($0) }
                    ), in: 1...100, step: 1)
                    .accentColor(.blue)
                    
                    HStack {
                        Text("1 floor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("100 floors")
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
            .navigationTitle("Stairs Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userSettings.dailyStairsGoal = goalValue
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            goalValue = userSettings.dailyStairsGoal
        }
    }
}

#Preview {
    StairsView(healthKitManager: HealthKitManager())
}
