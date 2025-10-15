//
//  ContentView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var stepData: [StepData]
    @Query private var goals: [HealthGoal]
    @Query private var insights: [HealthInsight]
    
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad Layout - Sidebar Navigation
                iPadLayout
            } else {
                // iPhone Layout - Tab Bar
                iPhoneLayout
            }
        }
        .preferredColorScheme(userSettings.appTheme.colorScheme)
        .accessibilityEnhanced()
        .onAppear {
            if !healthKitManager.isAuthorized {
                healthKitManager.requestAuthorization()
            } else {
                healthKitManager.fetchTodayData()
            }
        }
    }
    
    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    
                    Text("Movic Steps")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Health & Fitness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                
                Divider()
                
                // Navigation Items
                ScrollView {
                    LazyVStack(spacing: 8) {
                        NavigationItem(
                            title: "nav_steps".localized,
                            icon: "figure.walk",
                            color: .blue,
                            isSelected: selectedTab == 0,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 0 } }
                        )
                        
                        NavigationItem(
                            title: "nav_insights".localized,
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green,
                            isSelected: selectedTab == 1,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 1 } }
                        )
                        
                        NavigationItem(
                            title: "nav_goals".localized,
                            icon: "target",
                            color: .orange,
                            isSelected: selectedTab == 2,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 2 } }
                        )
                        
                        NavigationItem(
                            title: "nav_trends".localized,
                            icon: "chart.bar",
                            color: .purple,
                            isSelected: selectedTab == 3,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 3 } }
                        )
                        
                        NavigationItem(
                            title: "Stairs",
                            icon: "building.2",
                            color: .indigo,
                            isSelected: selectedTab == 4,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 4 } }
                        )
                        
                        NavigationItem(
                            title: "Heart Rate",
                            icon: "heart.fill",
                            color: .red,
                            isSelected: selectedTab == 5,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 5 } }
                        )
                        
                        NavigationItem(
                            title: "Workouts",
                            icon: "figure.mixed.cardio",
                            color: .pink,
                            isSelected: selectedTab == 6,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 6 } }
                        )
                        
                        NavigationItem(
                            title: "Sleep",
                            icon: "moon.fill",
                            color: .indigo,
                            isSelected: selectedTab == 7,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 7 } }
                        )
                        
                        NavigationItem(
                            title: "Nutrition",
                            icon: "fork.knife",
                            color: .brown,
                            isSelected: selectedTab == 8,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 8 } }
                        )
                        
                        NavigationItem(
                            title: "More",
                            icon: "ellipsis",
                            color: .gray,
                            isSelected: selectedTab == 9,
                            action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 9 } }
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(.systemBackground))
            .frame(minWidth: 280)
        } detail: {
            // Detail View
            Group {
                switch selectedTab {
                case 0:
                    iPadStepTrackingView
                case 1:
                    iPadHealthInsightsView
                case 2:
                    iPadGoalsView
                case 3:
                    iPadTrendsView
                case 4:
                    iPadStairsView
                case 5:
                    iPadHeartRateView
                case 6:
                    iPadWorkoutView
                case 7:
                    iPadSleepView
                case 8:
                    iPadNutritionView
                case 9:
                    iPadMoreView
                default:
                    iPadStepTrackingView
                }
            }
        }
    }
    
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            StepTrackingView(healthKitManager: healthKitManager)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 0 ? "figure.walk.circle.fill" : "figure.walk")
                            .font(.system(size: 20, weight: .medium))
                        Text("nav_steps".localized)
                            .font(.caption2)
                            .fontWeight(selectedTab == 0 ? .semibold : .regular)
                    }
                }
                .tag(0)
            
            HealthInsightsView(healthKitManager: healthKitManager, _insights: insights, _goals: goals)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 1 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20, weight: .medium))
                        Text("nav_insights".localized)
                            .font(.caption2)
                            .fontWeight(selectedTab == 1 ? .semibold : .regular)
                    }
                }
                .tag(1)
            
            GoalsView(healthKitManager: healthKitManager, _goals: goals)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 2 ? "target.circle.fill" : "target")
                            .font(.system(size: 20, weight: .medium))
                        Text("nav_goals".localized)
                            .font(.caption2)
                            .fontWeight(selectedTab == 2 ? .semibold : .regular)
                    }
                }
                .tag(2)
            
            TrendsView(healthKitManager: healthKitManager)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 3 ? "chart.bar.circle.fill" : "chart.bar")
                            .font(.system(size: 20, weight: .medium))
                        Text("nav_trends".localized)
                            .font(.caption2)
                            .fontWeight(selectedTab == 3 ? .semibold : .regular)
                    }
                }
                .tag(3)
            
            StairsView(healthKitManager: healthKitManager)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 4 ? "building.2.circle.fill" : "building.2")
                            .font(.system(size: 20, weight: .medium))
                        Text("Stairs")
                            .font(.caption2)
                            .fontWeight(selectedTab == 4 ? .semibold : .regular)
                    }
                }
                .tag(4)
            
            HeartRateView()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 5 ? "heart.circle.fill" : "heart.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Heart Rate")
                            .font(.caption2)
                            .fontWeight(selectedTab == 5 ? .semibold : .regular)
                    }
                }
                .tag(5)
            
            WorkoutView()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 6 ? "figure.mixed.cardio.circle.fill" : "figure.mixed.cardio")
                            .font(.system(size: 20, weight: .medium))
                        Text("Workouts")
                            .font(.caption2)
                            .fontWeight(selectedTab == 6 ? .semibold : .regular)
                    }
                }
                .tag(6)
            
            SleepView()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 7 ? "moon.circle.fill" : "moon.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Sleep")
                            .font(.caption2)
                            .fontWeight(selectedTab == 7 ? .semibold : .regular)
                    }
                }
                .tag(7)
            
            NutritionView()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 8 ? "fork.knife.circle.fill" : "fork.knife")
                            .font(.system(size: 20, weight: .medium))
                        Text("Nutrition")
                            .font(.caption2)
                            .fontWeight(selectedTab == 8 ? .semibold : .regular)
                    }
                }
                .tag(8)
            
            MoreView()
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 9 ? "ellipsis.circle.fill" : "ellipsis")
                            .font(.system(size: 20, weight: .medium))
                        Text("More")
                            .font(.caption2)
                            .fontWeight(selectedTab == 9 ? .semibold : .regular)
                    }
                }
                .tag(9)
        }
    }
    
    // MARK: - iPad-Optimized Views
    
    private var iPadStepTrackingView: some View {
        iPadStepTrackingViewWrapper(healthKitManager: healthKitManager)
            .navigationTitle("Step Tracking")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadHealthInsightsView: some View {
        iPadHealthInsightsViewWrapper(healthKitManager: healthKitManager, insights: insights, goals: goals)
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadGoalsView: some View {
        iPadGoalsViewWrapper(healthKitManager: healthKitManager, goals: goals)
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadTrendsView: some View {
        iPadTrendsViewWrapper(healthKitManager: healthKitManager)
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadStairsView: some View {
        StairsView(healthKitManager: healthKitManager)
            .navigationTitle("Stairs")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadHeartRateView: some View {
        HeartRateView()
            .navigationTitle("Heart Rate")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadWorkoutView: some View {
        WorkoutView()
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadSleepView: some View {
        SleepView()
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadNutritionView: some View {
        NutritionView()
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
    }
    
    private var iPadMoreView: some View {
        MoreView()
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
    }
}


// MARK: - Navigation Item Component
struct NavigationItem: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color(.systemGray6))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(isSelected ? color : .primary)
                    
                    if isSelected {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(color)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(color)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            action()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StepData.self, HealthGoal.self, HealthInsight.self], inMemory: true)
}
