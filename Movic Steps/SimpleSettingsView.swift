//
//  SimpleSettingsView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import WebKit

struct SimpleSettingsView: View {
    @StateObject private var settings = UserSettings.shared
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var goalTracker: GoalTracker
    @State private var showingLanguageSelection = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("units_display".localized) {
                    // Unit System Switcher
                    VStack(spacing: 16) {
                        HStack {
                            Text("unit_system".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                        ForEach(UnitSystem.allCases) { unit in
                                UnitSystemCard(
                                    unit: unit,
                                    isSelected: settings.unitSystem == unit,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            settings.unitSystem = unit
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Unit Details
                    VStack(spacing: 12) {
                        UnitDetailRow(
                            icon: "location",
                            title: "distance".localized,
                            unit: settings.unitSystem.distanceUnit,
                            color: .blue
                        )
                        
                        UnitDetailRow(
                            icon: "scalemass",
                            title: "weight".localized, 
                            unit: settings.unitSystem.weightUnit,
                            color: .green
                        )
                        
                        UnitDetailRow(
                            icon: "ruler",
                            title: "height".localized,
                            unit: settings.unitSystem.heightUnit,
                            color: .orange
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                Section("language".localized) {
                    Button(action: {
                        showingLanguageSelection = true
                    }) {
                    HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            Text("language_selection".localized)
                        Spacer()
                            Text(SupportedLanguage(rawValue: LocalizationManager.shared.getCurrentLanguage())?.displayName ?? "English")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section("appearance".localized) {
                    Picker("theme".localized, selection: $settings.appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    
                    Toggle("haptic_feedback".localized, isOn: $settings.enableHapticFeedback)
                    Toggle("enable_sounds".localized, isOn: $settings.enableSounds)
                }
                
                Section("personal_information".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("weight".localized, systemImage: "scalemass")
                            Spacer()
                            Text(settings.formatUserWeight())
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        Picker("weight".localized, selection: Binding(
                            get: { settings.userWeight },
                            set: { settings.userWeight = $0 }
                        )) {
                            if settings.unitSystem == .metric {
                                ForEach(Array(stride(from: 30.0, through: 200.0, by: 0.1)), id: \.self) { weight in
                                    Text("\(String(format: "%.1f", weight)) kg").tag(weight)
                                }
                            } else {
                                // Imperial: Generate weights from 66.0 lbs to 440.0 lbs with 0.1 lb precision
                                ForEach(Array(stride(from: 66.0, through: 440.0, by: 0.1)), id: \.self) { weightInLbs in
                                    let weightInKg = weightInLbs / 2.20462 // Convert to kg for storage
                                    Text("\(String(format: "%.1f", weightInLbs)) lbs").tag(weightInKg)
                                }
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("height".localized, systemImage: "ruler")
                            Spacer()
                            Text(settings.formatUserHeight())
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        Picker("height".localized, selection: Binding(
                            get: { settings.userHeight },
                            set: { settings.userHeight = $0 }
                        )) {
                            if settings.unitSystem == .metric {
                                ForEach(Array(stride(from: 100, through: 250, by: 1)), id: \.self) { height in
                                    Text("\(Int(height)) cm").tag(Double(height))
                                }
                            } else {
                                // Imperial: Generate heights from 4'0" to 8'0" (48 to 96 inches total)
                                ForEach(Array(stride(from: 48, through: 96, by: 1)), id: \.self) { totalInches in
                                    let feet = totalInches / 12
                                    let inches = totalInches % 12
                                    let heightInCm = Double(totalInches) * 2.54 // Convert to cm for storage
                                    Text("\(feet)' \(inches)\"").tag(heightInCm)
                                }
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
                
                Section("goals".localized) {
                    HStack {
                        Text("daily_step_goal".localized)
                        Spacer()
                        Text("\(settings.dailyStepGoal)")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("daily_steps".localized + ": \(settings.dailyStepGoal)", 
                           value: $settings.dailyStepGoal, 
                           in: 1000...50000, 
                           step: 500)
                    .labelsHidden()
                }
                
                Section("step_tracking".localized) {
                    Picker("preferred_source".localized, selection: $settings.preferredStepSource) {
                        ForEach(StepTrackingSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    
                    HStack {
                        Text("step_sensitivity".localized)
                        Spacer()
                        Picker("step_sensitivity".localized, selection: $settings.stepSensitivity) {
                            ForEach(StepSensitivity.allCases) { sensitivity in
                                Text(sensitivity.displayName).tag(sensitivity)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("calibration_factor".localized, systemImage: "tuningfork")
                            Spacer()
                            Text(String(format: "%.1fx", settings.stepCalibrationFactor))
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        Slider(value: $settings.stepCalibrationFactor,
                              in: 0.5...2.0,
                              step: 0.1)
                        
                        Text("adjust_accuracy".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("notifications".localized) {
                    HStack {
                        Toggle("enable_notifications".localized, isOn: $settings.enableNotifications)
                            .onChange(of: settings.enableNotifications) {
                                if settings.enableNotifications && !notificationManager.isAuthorized {
                                    notificationManager.requestAuthorization()
                                }
                                goalTracker.updateNotificationSettings()
                            }
                    }
                    
                    if !notificationManager.isAuthorized && settings.enableNotifications {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("permission_required".localized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("allow_notifications".localized)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("settings".localized) {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if settings.enableNotifications {
                        Picker("goal_reminder".localized, selection: $settings.goalReminderTime) {
                            ForEach(GoalReminderTime.allCases) { time in
                                Text(time.displayName).tag(time)
                            }
                        }
                        .onChange(of: settings.goalReminderTime) {
                            goalTracker.updateNotificationSettings()
                        }
                        
                        Toggle("weekly_progress_report".localized, isOn: $settings.showWeeklyReport)
                            .onChange(of: settings.showWeeklyReport) {
                                goalTracker.updateNotificationSettings()
                            }
                        
                        // Test notification buttons
                        VStack(spacing: 8) {
                            Button("🎉 Test Achievement Notification")  {
                                goalTracker.sendTestNotification()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                            
                            Button("⏰ Test Reminder Notification") {
                                goalTracker.sendTestReminder()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
                
                Section("accessibility".localized) {
                    Toggle("voiceover_support".localized, isOn: $settings.enableVoiceOver)
                        .accessibilityHint("voiceover_hint".localized)
                    
                    Toggle("reduce_motion".localized, isOn: $settings.enableReduceMotion)
                        .accessibilityHint("reduce_motion_hint".localized)
                    
                    Toggle("high_contrast".localized, isOn: $settings.enableHighContrast)
                        .accessibilityHint("high_contrast_hint".localized)
                    
                    Toggle("large_text".localized, isOn: $settings.enableLargeText)
                        .accessibilityHint("large_text_hint".localized)
                    
                    Toggle("bold_text".localized, isOn: $settings.enableBoldText)
                        .accessibilityHint("bold_text_hint".localized)
                    
                    Picker("text_size".localized, selection: $settings.textSize) {
                        ForEach(AccessibilityTextSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .accessibilityHint("text_size_hint".localized)
                    
                    Picker("color_vision".localized, selection: $settings.colorBlindnessType) {
                        ForEach(ColorBlindnessType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .accessibilityHint("color_vision_hint".localized)
                    
                    // Show description for selected type
                    if settings.colorBlindnessType != .none {
                        Text(settings.colorBlindnessType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, -8)
                    }
                    
                    Button("open_system_accessibility".localized) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .foregroundColor(.blue)
                    .accessibilityHint("accessibility_hint".localized)
                    
                    // Accessibility Demo Section
                    VStack(alignment: .leading, spacing: 8) {
                        AccessibleText("accessibility_preview".localized, style: .headline)
                            .padding(.top)
                        
                        AccessibleCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                        .accessibleForegroundColor(.blue)
                                    AccessibleText("sample_text".localized, style: .body)
                                }
                                
                                AccessibleProgressRing(
                                    progress: 0.7,
                                    lineWidth: 4,
                                    size: CGSize(width: 50, height: 50)
                                )
                                
                                AccessibleButton(action: {
                                    // Demo button action
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        AccessibleText("demo_button".localized, style: .callout)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        AccessibleText("preview_description".localized, style: .caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                
                
                Section("frequently_asked_questions".localized) {
                    NavigationLink(destination: FAQView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("view_faqs".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                Section("about".localized) {
                    HStack {
                        Text("version".localized)
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("build".localized)
                        Spacer()
                        Text("2025.18w92.11")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("contact_support".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button("privacy_policy".localized) {
                         if let url = URL(string: "https://airforcerp.com/legal/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button("terms_of_service".localized) {
                        if let url = URL(string: "https://airforcerp.com/legal/terms") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .navigationTitle("settings".localized)
        }
        .accessibilityEnhanced()
        .sheet(isPresented: $showingLanguageSelection) {
            LanguageSelectionView()
        }
    }
}

struct FAQView: View {
    @State private var expandedItems: Set<Int> = []
    
    private let faqItems = [
        FAQItem(
            question: "faq_step_counting_question".localized,
            answer: "faq_step_counting_answer".localized,
        ),
        FAQItem(
            question: "faq_healthkit_sync_question".localized,
            answer: "faq_healthkit_sync_answer".localized,
        ),
        FAQItem(
            question: "faq_accuracy_question".localized,
            answer: "faq_accuracy_answer".localized
        ),
        FAQItem(
            question: "Can I set multiple goals?",
            answer: "Yes! You can set goals for steps, distance, calories burned, and active minutes. Each goal can be customized to your fitness level and preferences. Tap the 'Add New Goal' button in the Goals tab to create additional goals."
        ),
        FAQItem(
            question: "How are calories calculated?",
            answer: "Calories are calculated based on your walking speed, step length, and distance. You can enable 'Use Calculated Metrics' in settings to get more personalized calorie estimates based on your walking patterns."
        ),
        FAQItem(
            question: "What are active minutes?",
            answer: "Active minutes track the time you spend in moderate to vigorous physical activity. This includes walking, running, and other activities that get your heart rate up. The app calculates this based on your movement patterns and step data."
        ),
        FAQItem(
            question: "How do I edit or delete my goals?",
            answer: "To edit a goal, tap the pencil icon on any goal card or swipe left and tap 'Edit'. To delete a goal, tap the trash icon or swipe left and tap 'Delete'. You'll see a warning before the goal is permanently removed."
        ),
        FAQItem(
            question: "Why don't I see my trends data?",
            answer: "Trends data appears after you've been using the app for a few days. The app needs historical data to show meaningful trends. Make sure you're consistently using the app and that HealthKit permissions are enabled."
        ),
        FAQItem(
            question: "Can I use the app without an internet connection?",
            answer: "Yes! Movic Steps works completely offline. All your data is stored locally on your device and synced with HealthKit. You only need an internet connection for app updates or contacting support."
        ),
        FAQItem(
            question: "How do I reset my data?",
            answer: "To reset your data, go to Settings > Data & Privacy > Reset All Data. This will clear all your goals, progress, and settings. Your HealthKit data will remain unchanged. This action cannot be undone."
        ),
        FAQItem(
            question: "The app is not tracking my steps correctly. What should I do?",
            answer: "Try these troubleshooting steps: 1) Restart the app, 2) Check HealthKit permissions, 3) Make sure your phone is in your pocket when walking, 4) Calibrate your step length in settings, 5) Restart your iPhone if the issue persists."
        ),
        FAQItem(
            question: "How do I contact support?",
            answer: "You can contact our support team by tapping 'Contact Support' in the Settings tab. This will open your email app with our support address pre-filled. We typically respond within 24 hours."
        ),
        FAQItem(
            question: "How do I delete a goal?",
            answer: "To delete a goal, tap the pencil icon on any goal card or swipe left and tap 'Delete'. You'll see a warning before the goal is permanently removed."
        ),
        FAQItem(
            question: "Does Movic Steps work with Apple Watch?",
            answer: "Yes. If you grant permission, Movic Steps can read steps and workouts recorded by Apple Watch via HealthKit. The app automatically avoids double-counting by relying on HealthKit’s unified totals."
        ),
        FAQItem(
            question: "Why do my step totals look different from the Health app?",
            answer: "HealthKit resolves data from multiple sources using a priority system. If you use other fitness apps or an Apple Watch, totals may differ slightly. You can adjust source priority in the Health app > Sources > Data Sources & Access."
        ),
        FAQItem(
            question: "How do I change units between miles and kilometers?",
            answer: "Go to Settings > Units and choose Imperial (mi) or Metric (km). Distances and pace will update throughout the app immediately."
        ),
        FAQItem(
            question: "Can Movic Steps track distance on a treadmill?",
            answer: "Yes. Steps from indoor walking are recorded by Core Motion. For more accurate distance on treadmills, calibrate step length in Settings or log a few outdoor walks so iOS can improve indoor distance estimates."
        ),
        FAQItem(
            question: "How do I enable notifications and reminders?",
            answer: "Open Settings > Notifications and toggle Daily Reminders or Goal Nudges. You can set times, quiet hours, and whether reminders use sounds, haptics, or banners."
        ),
        FAQItem(
            question: "What is Background App Refresh used for?",
            answer: "Background App Refresh lets Movic Steps update widgets, badges, and goal progress periodically. It does not continuously run or drain battery; iOS schedules brief updates as needed."
        ),
        FAQItem(
            question: "How much battery does step tracking use?",
            answer: "Very little. Movic Steps reads from low-power motion coprocessors and HealthKit rather than using GPS continuously. Battery impact is comparable to the built-in Health app."
        ),
        FAQItem(
            question: "Do I need GPS for step tracking?",
            answer: "No. Steps are counted by Core Motion without GPS. GPS is only used for optional distance mapping during outdoor activities if you enable it."
        ),
        FAQItem(
            question: "Can I export my data?",
            answer: "Yes. Go to Settings > Data & Privacy > Export. You can export steps, distance, and goals as CSV for use in spreadsheets or backups."
        ),
        FAQItem(
            question: "How do I import or restore data on a new iPhone?",
            answer: "If you use iCloud and Health data syncing, your step history restores automatically after signing in. App-specific settings and goals restore from iCloud if you enabled iCloud Backup."
        ),
        FAQItem(
            question: "Does Movic Steps store my data on servers?",
            answer: "No. Your step data stays on your device and inside Apple Health. We only access HealthKit with your permission and do not upload your Health data to our servers."
        ),
        FAQItem(
            question: "I changed my daily goal—will past days update?",
            answer: "No. Goals are snapshot-based. Changing your goal affects future days; historical completion statuses remain as originally recorded."
        ),
        FAQItem(
            question: "What are Streaks and how do they work?",
            answer: "A streak increases each day you hit your primary step goal. Missing a day resets the streak. You can view streak history in the Progress tab."
        ),
        FAQItem(
            question: "Can I create custom challenges with friends?",
            answer: "Yes. Use the Challenges tab to create a step or active-minutes challenge, set duration, and share an invite link. Participants’ totals are compared via HealthKit sharing if they grant permission."
        ),
        FAQItem(
            question: "How often do widgets update?",
            answer: "iOS updates widgets periodically. For the freshest numbers, open the app or tap the widget. Live Activity on the Lock Screen can show more frequent updates during active sessions."
        ),
        FAQItem(
            question: "Why is the widget showing yesterday’s steps?",
            answer: "Widgets may cache data to conserve battery. Open the app for a moment to refresh, ensure Background App Refresh is enabled, and verify Health permissions."
        ),
        FAQItem(
            question: "Does Movic Steps support Lock Screen and Home Screen widgets?",
            answer: "Yes. Add them from the iOS widget gallery to see daily steps, distance, or goal completion at a glance."
        ),
        FAQItem(
            question: "How do I avoid double-counting steps from multiple devices?",
            answer: "HealthKit manages this automatically by prioritizing sources. If needed, change priority in Health app > Steps > Data Sources & Access, and place your primary device at the top."
        ),
        FAQItem(
            question: "Can I log steps manually?",
            answer: "Yes. In the History view, tap ‘+’ and add steps for a time window. Manual entries are saved to HealthKit and clearly labeled."
        ),
        FAQItem(
            question: "Is there support for Wheelchair mode?",
            answer: "If your device is set to Wheelchair mode in iOS accessibility, Apple Health records ‘Pushes’ instead of steps. Movic Steps reads these values and displays distance and activity accordingly."
        ),
        FAQItem(
            question: "Can I set quiet hours for notifications?",
            answer: "Yes. Go to Settings > Notifications > Quiet Hours and choose a time range to pause reminders overnight or during work."
        ),
        FAQItem(
            question: "How do I troubleshoot missing data after an iOS update?",
            answer: "Open the app, confirm Health permissions, and reboot your device. Also ensure ‘Fitness Tracking’ is enabled in Settings > Privacy & Security > Motion & Fitness."
        ),
        FAQItem(
            question: "What versions of iOS are supported?",
            answer: "Movic Steps supports iOS 16 and later. Some features like Lock Screen widgets require iOS 16+, and Live Activities may require iOS 16.1+."
        ),
        FAQItem(
            question: "Does the app support multiple profiles?",
            answer: "Health data is per Apple ID and device user. Movic Steps reads from the current user’s Health profile; multiple profiles on one device are not supported."
        ),
        FAQItem(
            question: "How do I change the app’s appearance?",
            answer: "Go to Settings > Appearance to choose Light, Dark, or System. You can also enable high-contrast mode for improved readability."
        ),
        FAQItem(
            question: "Can I sync steps to other apps?",
            answer: "If those apps read from HealthKit, your steps will be available to them once you grant permission in the Health app."
        ),
        FAQItem(
            question: "How are active minutes detected without a heart-rate monitor?",
            answer: "We infer activity intensity from motion patterns and cadence. If you use Apple Watch, heart-rate signals from workouts can improve active-minute detection."
        ),
        FAQItem(
            question: "How do I contact support from within the app?",
            answer: "Settings > Contact Support opens your email client with diagnostics (no Health data) attached. Send us details and we typically respond within 24 hours. Or use the Live Chat Support option."
        ),
        FAQItem(
            question: "How do I join the beta (TestFlight)?",
            answer: "From Settings > About > Join Beta, tap the TestFlight link if available. Beta builds may contain experimental features—feedback is appreciated!"
        )


    ]
    
    var body: some View {
        List {
            ForEach(Array(faqItems.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if expandedItems.contains(index) {
                                expandedItems.remove(index)
                            } else {
                                expandedItems.insert(index)
                            }
                        }
                    }) {
                        HStack {
                            Text(item.question)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: expandedItems.contains(index) ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if expandedItems.contains(index) {
                        Text(item.answer)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .navigationTitle("FAQs")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(PlainListStyle())
    }
}

struct FAQItem {
    let question: String
    let answer: String
}

struct ContactSupportView: View {
    @State private var showingCharlaWidget = false
    
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Contact Support")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose how you'd like to get help")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Support Options
            VStack(spacing: 16) {
                // AI Bot Support Option
                Button(action: {
                    showingCharlaWidget = true
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Assistant")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Get instant help from our AI bot")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                 // Email Support Option
                 Button(action: {
                     openEmailSupport()
                 }) {
                     HStack {
                         Image(systemName: "envelope.circle.fill")
                             .font(.title2)
                             .foregroundColor(.blue)
                         
                         VStack(alignment: .leading, spacing: 4) {
                             Text("Email Support")
                                 .font(.headline)
                                 .foregroundColor(.primary)
                             
                             Text("Send us an email at support@airforcerp.com")
                                 .font(.subheadline)
                                 .foregroundColor(.secondary)
                         }
                         
                         Spacer()
                         
                         Image(systemName: "arrow.right.circle.fill")
                             .font(.title2)
                             .foregroundColor(.blue)
                     }
                     .padding()
                     .background(
                         RoundedRectangle(cornerRadius: 12)
                             .fill(Color(.systemGray6))
                             .overlay(
                                 RoundedRectangle(cornerRadius: 12)
                                     .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                             )
                     )
                 }
                
                
                .padding(.horizontal)
                
                // Additional Info
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Response Time: Usually within 24 hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.secondary)
                        Text("Available: Monday - Friday, 9 AM - 6 PM EST")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
             .navigationTitle("Contact Support")
             .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCharlaWidget) {
                AIBotView()
            }
         }
     }
     
     private func openEmailSupport() {
         let email = "support@airforcerp.com"
         let subject = "Movic Steps Support Request"
         let body = """
         
         Please describe your issue or question below:
         
         
         
         ---
         Device: iPhone \(UIDevice.current.model)
         App Version: 1.1.0 (18w92.11)
         iOS Version: \(UIDevice.current.systemVersion)

         UUID: \(UUID().uuidString)
         """
         
         let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
         let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
         
         if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
             UIApplication.shared.open(url)
         }
     }
    
    struct EmailSupportView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var subject = "support_request_subject".localized
        @State private var emailBody = String(format: "support_request_body".localized, UIDevice.current.model, UIDevice.current.systemVersion)
        var deviceModel = UIDevice.current.model
        var appVersion = "1.1"
        var iosVersion = UIDevice.current.systemVersion
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("email_support_title".localized)
                            .font(.headline)
                        
                        Text("email_support_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("subject".localized + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("subject".localized, text: $subject)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("message".localized + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $emailBody)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("email_support_title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel".localized) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("send_email".localized) {
                            sendEmail()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        
        private func sendEmail() {
            let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let emailSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: "mailto:support@airforcerp.com?subject=\(emailSubject)&body=\(encodedBody)") {
                UIApplication.shared.open(url)
            }
            dismiss()
        }
    }
    
    struct AIBotView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var messages: [ChatMessage] = []
        @State private var currentMessage = ""
        @State private var isTyping = false
        @State private var chatbotData: ChatbotData?
        
        var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if isTyping {
                                    TypingIndicator()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) {
                            if let lastMessage = messages.last {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 12) {
                            TextField("chatbot_placeholder".localized, text: $currentMessage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    sendMessage()
                                }
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(currentMessage.isEmpty ? Color.gray : Color.blue)
                                    )
                            }
                            .disabled(currentMessage.isEmpty)
                        }
                        .padding()
                    }
                }
                .navigationTitle("ai_assistant".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("clear".localized) {
                            messages.removeAll()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("done".localized) {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    loadChatbotData()
                    addWelcomeMessage()
                }
            }
        }
        
        private func sendMessage() {
            guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            let userMessage = ChatMessage(content: currentMessage, isUser: true)
            messages.append(userMessage)
            
            let query = currentMessage
            currentMessage = ""
            
            // Simulate typing
            isTyping = true
            
            // Generate AI response
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let response = generateAIResponse(for: query)
                let botMessage = ChatMessage(content: response, isUser: false)
                messages.append(botMessage)
                isTyping = false
            }
        }
        
        private func addWelcomeMessage() {
            let welcomeMessage = ChatMessage(
                content: "👋 Hi! I'm your Movic Steps AI Assistant. I know everything about this app and can help you with:\n\n• Step counting and accuracy\n• Goal setting and management\n• HealthKit integration\n• Calorie and active minute calculations\n• Troubleshooting issues\n• App features and settings\n\nWhat would you like to know?",
                isUser: false
            )
            messages.append(welcomeMessage)
        }
        
        private func loadChatbotData() {
            guard let url = Bundle.main.url(forResource: "chatbot", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                print("Failed to load chatbot.json")
                return
            }
            
            do {
                chatbotData = try JSONDecoder().decode(ChatbotData.self, from: data)
            } catch {
                print("Failed to decode chatbot data: \(error)")
            }
        }
        
        private func generateAIResponse(for query: String) -> String {
            guard let data = chatbotData else {
                return "I'm having trouble accessing my knowledge base. Please try again later."
            }
            
            let lowercaseQuery = query.lowercased()
            
            // Check each response category
            for (category, responseData) in data.responses {
                if category == "default" { continue }
                
                for keyword in responseData.keywords {
                    if lowercaseQuery.contains(keyword) {
                        return responseData.response
                    }
                }
            }
            
            // Return default response with query substitution
            let defaultResponse = data.responses["default"]?.response ?? "I'm not sure how to help with that."
            return defaultResponse.replacingOccurrences(of: "{query}", with: query)
        }
    }
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    struct ChatBubble: View {
        let message: ChatMessage
        
        var body: some View {
            HStack {
                if message.isUser {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(message.content)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                                .font(.title3)
                                .padding(.top, 4)
                            
                            Text(message.content)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                        }
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 32)
                    }
                    Spacer()
                }
            }
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    struct TypingIndicator: View {
        @State private var animationOffset: CGFloat = 0
        
        var body: some View {
            HStack {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .font(.title3)
                        .padding(.top, 4)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                                .offset(y: animationOffset)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: animationOffset
                                )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                }
                Spacer()
            }
            .onAppear {
                animationOffset = -4
            }
        }
    }
    
    // MARK: - Chatbot Data Structures
    struct ChatbotData: Codable {
        let responses: [String: ResponseData]
    }
    
    struct ResponseData: Codable {
        let keywords: [String]
        let response: String
}

#Preview {
    SimpleSettingsView()
    }
}

// MARK: - Unit System UI Components
struct UnitSystemCard: View {
    let unit: UnitSystem
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: unit == .metric ? "globe.americas" : "globe.americas.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Title
                Text(unit.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Subtitle
                Text(unit == .metric ? "km, kg, cm" : "miles, lbs, ft/in")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.adjustedForColorBlindness(userSettings.colorBlindnessType) : Color(.systemGray6))
                    .shadow(
                        color: isSelected ? Color.blue.adjustedForColorBlindness(userSettings.colorBlindnessType).opacity(0.3) : Color.clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UnitDetailRow: View {
    let icon: String
    let title: String
    let unit: String
    let color: Color
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.adjustedForColorBlindness(userSettings.colorBlindnessType).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color.adjustedForColorBlindness(userSettings.colorBlindnessType))
            }
            
            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Unit
            Text(unit)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color.adjustedForColorBlindness(userSettings.colorBlindnessType))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(color.adjustedForColorBlindness(userSettings.colorBlindnessType).opacity(0.1))
                )
        }
        .padding(.horizontal, 4)
    }
}
