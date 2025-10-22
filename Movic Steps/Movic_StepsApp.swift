//
//  Movic_StepsApp.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import SwiftData

@main
struct Movic_StepsApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var goalTracker = GoalTracker.shared
    @StateObject private var loadingStateManager = LoadingStateManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StepData.self,
            HealthGoal.self,
            HealthInsight.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ Could not create ModelContainer: \(error)")
            print("🔄 Falling back to in-memory storage...")
            
            // Fallback to in-memory storage if persistent storage fails
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                print("❌ Could not create fallback ModelContainer: \(error)")
                // Last resort: create a minimal container
                return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if loadingStateManager.isLoading {
                    LoadingScreen()
                        .transition(.opacity)
                        .onAppear {
                            // Let the LoadingScreen control its own timing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    loadingStateManager.isLoading = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .environmentObject(notificationManager)
                        .environmentObject(goalTracker)
                        .environmentObject(localizationManager)
                        .transition(.opacity)
                        .onAppear {
                            AppVersion.logVersion()
                            print("🚀 App launched with ContentView - Tab should show 'Settings'")
                        }
                }
            }
            .environmentObject(loadingStateManager)
            .onAppear {
                // Request notification permissions on app launch
                if !notificationManager.isAuthorized {
                    notificationManager.requestAuthorization()
                }
                
                // Refresh language from UserDefaults to ensure persistence
                localizationManager.refreshLanguageFromUserDefaults()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    // Refresh language when app becomes active
                    localizationManager.refreshLanguageFromUserDefaults()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
