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
            List {
                Button(action: { selectedTab = 0 }) {
                    HStack {
                        Label("nav_steps".localized, systemImage: "figure.walk")
                            .font(.headline)
                        Spacer()
                        if selectedTab == 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(selectedTab == 0 ? .accentColor : .primary)
                
                Button(action: { selectedTab = 1 }) {
                    HStack {
                        Label("nav_insights".localized, systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                        Spacer()
                        if selectedTab == 1 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(selectedTab == 1 ? .accentColor : .primary)
                
                Button(action: { selectedTab = 2 }) {
                    HStack {
                        Label("nav_goals".localized, systemImage: "target")
                            .font(.headline)
                        Spacer()
                        if selectedTab == 2 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(selectedTab == 2 ? .accentColor : .primary)
                
                Button(action: { selectedTab = 3 }) {
                    HStack {
                        Label("nav_trends".localized, systemImage: "chart.bar")
                            .font(.headline)
                        Spacer()
                        if selectedTab == 3 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(selectedTab == 3 ? .accentColor : .primary)
                
                Button(action: { selectedTab = 4 }) {
                    HStack {
                        Label("nav_settings".localized, systemImage: "gearshape")
                            .font(.headline)
                        Spacer()
                        if selectedTab == 4 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(selectedTab == 4 ? .accentColor : .primary)
            }
            .navigationTitle("Movic Steps")
            .listStyle(SidebarListStyle())
            .frame(minWidth: 250)
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
                    iPadSettingsView
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
                    Image(systemName: "figure.walk")
                    Text("nav_steps".localized)
                }
                .tag(0)
            
            HealthInsightsView(healthKitManager: healthKitManager, _insights: insights, _goals: goals)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("nav_insights".localized)
                }
                .tag(1)
            
            GoalsView(healthKitManager: healthKitManager, _goals: goals)
                .tabItem {
                    Image(systemName: "target")
                    Text("nav_goals".localized)
                }
                .tag(2)
            
            TrendsView(healthKitManager: healthKitManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("nav_trends".localized)
                }
                .tag(3)
            
            SimpleSettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("nav_settings".localized)
                }
                .tag(4)
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
    
    private var iPadSettingsView: some View {
        iPadSettingsViewWrapper()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [StepData.self, HealthGoal.self, HealthInsight.self], inMemory: true)
}
