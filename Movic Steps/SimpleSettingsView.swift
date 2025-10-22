//
//  SimpleSettingsView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI

struct SimpleSettingsView: View {
    @StateObject private var settings = UserSettings.shared
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var goalTracker: GoalTracker
    @State private var showingLanguageSelection = false
    @State private var showingMilestone = true
    @State private var enableMealTracking = true
    @State private var enableHeartRateNotifications = true
    @State private var enableWorkoutAutoDetection = true
    @State private var enableWorkoutCalorieTracking = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.1),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Milestone Notification
                        if showingMilestone {
                            MilestoneCard()
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                        
                        // Quick Access Section
                        quickAccessSection
                        
                        // Health Features Section
                        healthFeaturesSection
                        
                        // Accessibility Settings Section
                        accessibilitySettingsSection
                        
                        // Standard Settings Section
                        standardSettingsSection
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingLanguageSelection) {
            LanguageSelectionView()
        }
    }
    
    // MARK: - View Components
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Access")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            // Health Features Button
            Button(action: {
                // This could navigate to a health features overview
            }) {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "heart.text.square")
                                .font(.title2)
                                .foregroundColor(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Access all your health tracking features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    private var healthFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Health Features")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Stairs Card
                StairsSettingsCard()
                
                // Nutrition Card
                NutritionSettingsCard(enableMealTracking: $enableMealTracking)
                
                // Heart Rate Card
                HeartRateSettingsCard(enableHeartRateNotifications: $enableHeartRateNotifications)
                
                // Workouts Card
                WorkoutsSettingsCard(enableWorkoutAutoDetection: $enableWorkoutAutoDetection)
                
                // Sleep Card
                SleepSettingsCard()
            }
            .padding(.horizontal)
        }
    }
    
    private var accessibilitySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "accessibility")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Accessibility")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // VoiceOver Support
                VoiceOverSettingsCard()
                
                // Visual Accessibility
                VisualAccessibilityCard()
                
                // Motor Accessibility
                MotorAccessibilityCard()
                
                // Cognitive Accessibility
                CognitiveAccessibilityCard()
                
                // System Accessibility
                SystemAccessibilityCard()
            }
            .padding(.horizontal)
        }
    }
    
    private var standardSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
                Text("App Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Units & Display
                UnitsSettingsCard()
                
                // Language
                LanguageSettingsCard(showingLanguageSelection: $showingLanguageSelection)
                
                // Notifications
                NotificationsSettingsCard(notificationManager: notificationManager)
                
                // About
                AboutSettingsCard()
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Individual Settings Cards

struct StairsSettingsCard: View {
    var body: some View {
        SettingsCard(
            icon: "stairs",
            title: "Stairs",
            subtitle: "Floor Tracking",
            color: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Floor Tracking", isOn: .constant(true))
                    .tint(.blue)
                
                Divider()
                
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Floor Height")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("3.0 meters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                NavigationLink(destination: StairsView(healthKitManager: HealthKitManager())) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Detailed Settings")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct NutritionSettingsCard: View {
    @Binding var enableMealTracking: Bool
    
    var body: some View {
        SettingsCard(
            icon: "leaf",
            title: "Nutrition",
            subtitle: "Food Tracking",
            color: .green
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Food Tracking", isOn: $enableMealTracking)
                    .tint(.green)
                
                Divider()
                
                HStack {
                    Image(systemName: "flame")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Daily Calorie Goal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("2,000 calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                NavigationLink(destination: NutritionView()) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                        Text("View Analytics")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }
        }
    }
}

struct HeartRateSettingsCard: View {
    @Binding var enableHeartRateNotifications: Bool
    
    var body: some View {
        SettingsCard(
            icon: "heart.fill",
            title: "Heart Rate",
            subtitle: "Health Monitoring",
            color: .red
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Heart Rate Monitoring", isOn: $enableHeartRateNotifications)
                    .tint(.red)
                
                Divider()
                
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("Resting Heart Rate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("72 BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                NavigationLink(destination: HeartRateView()) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("View Trends")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct WorkoutsSettingsCard: View {
    @Binding var enableWorkoutAutoDetection: Bool
    
    var body: some View {
        SettingsCard(
            icon: "figure.run",
            title: "Workouts",
            subtitle: "Exercise Tracking",
            color: .purple
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Workout Tracking", isOn: $enableWorkoutAutoDetection)
                    .tint(.purple)
                
                Divider()
                
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading) {
                        Text("Today's Workouts")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("2 completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                NavigationLink(destination: WorkoutView()) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Workouts")
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

struct SleepSettingsCard: View {
    var body: some View {
        SettingsCard(
            icon: "moon.fill",
            title: "Sleep",
            subtitle: "Sleep Tracking",
            color: .indigo
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Sleep Tracking", isOn: .constant(true))
                    .tint(.indigo)
                
                Divider()
                
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.indigo)
                    VStack(alignment: .leading) {
                        Text("Last Night's Sleep")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("7h 32m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                NavigationLink(destination: SleepView()) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("View Sleep Data")
                    }
                    .font(.caption)
                    .foregroundColor(.indigo)
                }
            }
        }
    }
}

struct UnitsSettingsCard: View {
    @StateObject private var settings = UserSettings.shared
    
    var body: some View {
        SettingsCard(
            icon: "ruler",
            title: "Units & Display",
            subtitle: "Measurement preferences",
            color: .orange
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Unit System", selection: $settings.unitSystem) {
                    Text("Metric").tag(UnitSystem.metric)
                    Text("Imperial").tag(UnitSystem.imperial)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Text("Distance")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(settings.unitSystem == .metric ? "km" : "miles")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Weight")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(settings.unitSystem == .metric ? "kg" : "lbs")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Height")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(settings.unitSystem == .metric ? "cm" : "ft/in")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct LanguageSettingsCard: View {
    @Binding var showingLanguageSelection: Bool
    
    var body: some View {
        SettingsCard(
            icon: "globe",
            title: "Language",
            subtitle: "App language settings",
            color: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    showingLanguageSelection = true
                }) {
                    HStack {
                        Text("Language Selection")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("English")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

struct NotificationsSettingsCard: View {
    @ObservedObject var notificationManager: NotificationManager
    
    var body: some View {
        SettingsCard(
            icon: "bell",
            title: "Notifications",
            subtitle: "Alert preferences",
            color: .red
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Notifications", isOn: $notificationManager.isAuthorized)
                    .tint(.red)
                
                if notificationManager.isAuthorized {
                    Text("Notifications are enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Request Permission") {
                        notificationManager.requestAuthorization()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct AboutSettingsCard: View {
    var body: some View {
        SettingsCard(
            icon: "info.circle",
            title: "About",
            subtitle: "App information",
            color: .gray
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Version")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("2.1")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("2025.01.20.2")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MilestoneCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Milestone Achieved!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("You've reached 10,000 steps today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Accessibility Settings Cards

struct VoiceOverSettingsCard: View {
    @ObservedObject var settings = UserSettings.shared
    @State private var voiceOverHints = true
    @State private var voiceOverAnnouncements = true
    
    var body: some View {
        SettingsCard(
            icon: "speaker.wave.2",
            title: "VoiceOver Support",
            subtitle: "Screen reader assistance",
            color: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable VoiceOver Support", isOn: $settings.enableVoiceOver)
                    .tint(.blue)
                
                if settings.enableVoiceOver {
                    Divider()
                    
                    Toggle("VoiceOver Hints", isOn: $voiceOverHints)
                        .tint(.blue)
                    
                    Toggle("VoiceOver Announcements", isOn: $voiceOverAnnouncements)
                        .tint(.blue)
                    
                    Text("Provides enhanced VoiceOver support throughout the app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct VisualAccessibilityCard: View {
    @ObservedObject var settings = UserSettings.shared
    
    var body: some View {
        SettingsCard(
            icon: "eye",
            title: "Visual Accessibility",
            subtitle: "Visual assistance features",
            color: .green
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Reduce Motion", isOn: $settings.enableReduceMotion)
                    .tint(.green)
                
                Toggle("Increase Contrast", isOn: $settings.enableHighContrast)
                    .tint(.green)
                
                Toggle("Large Text", isOn: $settings.enableLargeText)
                    .tint(.green)
                
                Toggle("Bold Text", isOn: $settings.enableBoldText)
                    .tint(.green)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Size")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Text Size", selection: $settings.textSize) {
                        Text("Small").tag(AccessibilityTextSize.small)
                        Text("Medium").tag(AccessibilityTextSize.medium)
                        Text("Large").tag(AccessibilityTextSize.large)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .tint(.green)
                    
                    Text("Current: \(settings.textSize.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Vision")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Color Vision", selection: $settings.colorBlindnessType) {
                        Text("None").tag(ColorBlindnessType.none)
                        Text("Protanopia").tag(ColorBlindnessType.protanopia)
                        Text("Deuteranopia").tag(ColorBlindnessType.deuteranopia)
                        Text("Tritanopia").tag(ColorBlindnessType.tritanopia)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(.green)
                    
                    Text("Current: \(settings.colorBlindnessType.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct MotorAccessibilityCard: View {
    @ObservedObject var settings = UserSettings.shared
    
    var body: some View {
        SettingsCard(
            icon: "hand.tap",
            title: "Motor Accessibility",
            subtitle: "Touch and interaction assistance",
            color: .orange
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Switch Control", isOn: $settings.enableSwitchControl)
                    .tint(.orange)
                
                Toggle("Voice Control", isOn: $settings.enableVoiceControl)
                    .tint(.orange)
                
                Toggle("AssistiveTouch", isOn: $settings.enableAssistiveTouch)
                    .tint(.orange)
                
                Toggle("Touch Accommodations", isOn: $settings.enableTouchAccommodations)
                    .tint(.orange)
                
                Text("Enables alternative input methods for easier interaction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CognitiveAccessibilityCard: View {
    @ObservedObject var settings = UserSettings.shared
    
    var body: some View {
        SettingsCard(
            icon: "brain",
            title: "Cognitive Accessibility",
            subtitle: "Learning and focus assistance",
            color: .purple
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Guided Access", isOn: $settings.enableGuidedAccess)
                    .tint(.purple)
                
                Toggle("Time Limits", isOn: $settings.enableTimeLimit)
                    .tint(.purple)
                
                Toggle("Simplified Interface", isOn: $settings.enableSimpleInterface)
                    .tint(.purple)
                
                Toggle("Clear Instructions", isOn: $settings.enableClearInstructions)
                    .tint(.purple)
                
                Text("Provides tools to help with focus and learning")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SystemAccessibilityCard: View {
    var body: some View {
        SettingsCard(
            icon: "gear",
            title: "System Accessibility",
            subtitle: "iOS accessibility settings",
            color: .gray
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                        Text("Open System Accessibility Settings")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accessibility Preview")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Sample Text")
                        .font(.body)
                        .foregroundColor(.primary)
                        .accessibilityLabel("Sample text for accessibility testing")
                    
                    Button("Demo Button") {
                        // Demo action
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("This is a demo button for accessibility testing")
                }
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let content: Content
    
    init(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    SimpleSettingsView()
        .environmentObject(NotificationManager())
}