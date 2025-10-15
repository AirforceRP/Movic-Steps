//
//  StepTrackingView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import HealthKit

struct StepTrackingView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var stepCounter = AccelerometerStepCounter()
    @Environment(\.modelContext) private var modelContext
    @State private var showingPermissionAlert = false
    @State private var isTrackingSteps = false
    @State private var selectedStepSource: StepSource = .healthKit
    
    enum StepSource: String, CaseIterable {
        case healthKit = "HealthKit"
        case accelerometer = "Accelerometer"
        
        var icon: String {
            switch self {
            case .healthKit: return "heart.fill"
            case .accelerometer: return "gyroscope"
            }
        }
    }
    
    private var currentSteps: Int {
        switch selectedStepSource {
        case .healthKit:
            return healthKitManager.todaySteps
        case .accelerometer:
            return stepCounter.currentSteps
        }
    }
    
    private var currentFloors: Int {
        switch selectedStepSource {
        case .healthKit:
            return healthKitManager.todayFloors
        case .accelerometer:
            return stepCounter.currentFloors
        }
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.pink.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    if !healthKitManager.isAuthorized && selectedStepSource == .healthKit {
                        ModernPermissionView(healthKitManager: healthKitManager)
                    } else {
                        // Step Source Selector
                        StepSourceSelector(
                            selectedSource: $selectedStepSource,
                            isTracking: $isTrackingSteps,
                            stepCounter: stepCounter
                        )
                        
                        // Main step counter with modern design
                        ModernStepCounterCard(
                            steps: currentSteps,
                            floors: currentFloors,
                            goal: userSettings.dailyStepGoal,
                            isLoading: healthKitManager.isLoading,
                            source: selectedStepSource
                        )
                        
                        // Health metrics grid with equal height cards
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ModernMetricCard(
                                title: "distance_title".localized,
                                value: userSettings.formatDistance(healthKitManager.todayDistance),
                                icon: "location.fill",
                                color: .blue.adjustedForColorBlindness(userSettings.colorBlindnessType),
                                trend: .up
                            )
                            
                            ModernMetricCard(
                                title: "calories_title".localized,
                                value: String(format: "%.0f", healthKitManager.todayCalories),
                                icon: "flame.fill",
                                color: .orange.adjustedForColorBlindness(userSettings.colorBlindnessType),
                                trend: .stable
                            )
                            
                            ModernMetricCard(
                                title: "active_time_title".localized,
                                value: "\(healthKitManager.todayActiveMinutes) \("min_label".localized)",
                                icon: "clock.fill",
                                color: .green.adjustedForColorBlindness(userSettings.colorBlindnessType),
                                trend: .up
                            )
                            
                            ModernMetricCard(
                                title: "floors_title".localized,
                                value: "\(currentFloors) \("floors_label".localized)",
                                icon: "building.2.fill",
                                color: .indigo.adjustedForColorBlindness(userSettings.colorBlindnessType),
                                trend: .up
                            )
                            
                            ModernMetricCard(
                                title: "pace_title".localized,
                                value: calculatePace(),
                                icon: "speedometer",
                                color: .purple.adjustedForColorBlindness(userSettings.colorBlindnessType),
                                trend: .stable
                            )
                        }
                        
                        // Apple Watch Status
                        // WatchStatusView()
                        
                        // Accelerometer visualization (when using accelerometer)
                        if selectedStepSource == .accelerometer && isTrackingSteps {
                            AccelerometerVisualization(stepCounter: stepCounter)
                        }
                        
                        // Modern quick actions
                        ModernQuickActionsView(
                            healthKitManager: healthKitManager,
                            stepCounter: stepCounter,
                            isTracking: $isTrackingSteps,
                            selectedSource: selectedStepSource
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("dashboard_title".localized)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            healthKitManager.fetchTodayData()
        }
        .onAppear {
            // Start accelerometer if it was previously selected
            if selectedStepSource == .accelerometer && isTrackingSteps {
                stepCounter.startTracking()
            }
        }
    }
    
    private func calculatePace() -> String {
        guard healthKitManager.todaySteps > 0 && healthKitManager.todayActiveMinutes > 0 else {
            return "0 \("steps_per_min".localized)"
        }
        let pace = Double(healthKitManager.todaySteps) / Double(healthKitManager.todayActiveMinutes)
        return String(format: "%.0f %@", pace, "steps_per_min".localized)
    }
}

// MARK: - Modern UI Components

struct StepSourceSelector: View {
    @Binding var selectedSource: StepTrackingView.StepSource
    @Binding var isTracking: Bool
    let stepCounter: AccelerometerStepCounter
    
    var body: some View {
        GlassmorphismCard {
            VStack(spacing: 16) {
                Text("step_tracking_source".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                sourceButtons
                
                if selectedSource == .accelerometer {
                    accelerometerStatus
                }
            }
        }
    }
    
    private var sourceButtons: some View {
        HStack(spacing: 12) {
            ForEach(StepTrackingView.StepSource.allCases, id: \.self) { source in
                SourceButton(
                    source: source,
                    isSelected: selectedSource == source,
                    action: { selectSource(source) }
                )
            }
        }
    }
    
    private var accelerometerStatus: some View {
        HStack {
            Text("real_time_tracking".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isTracking {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .pulseEffect(color: .green)
                    
                    Text("active_status".localized)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func selectSource(_ source: StepTrackingView.StepSource) {
        selectedSource = source
        
        if source == .accelerometer && !isTracking {
            stepCounter.startTracking()
            isTracking = true
        } else if source == .healthKit && isTracking {
            stepCounter.stopTracking()
            isTracking = false
        }
    }
}

struct SourceButton: View {
    let source: StepTrackingView.StepSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: source.icon)
                    .font(.caption)
                Text(source.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(buttonBackground)
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(buttonOverlay)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? AnyShapeStyle(Color.accentGradient(for: UserSettings.shared.colorBlindnessType)) : AnyShapeStyle(Color.clear))
    }
    
    private var buttonOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
    }
}

struct ModernStepCounterCard: View {
    let steps: Int
    let floors: Int
    let goal: Int
    let isLoading: Bool
    let source: StepTrackingView.StepSource
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }
    
    var body: some View {
        GradientCard(gradient: Color.accentGradient(for: UserSettings.shared.colorBlindnessType)) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("steps_today".localized)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("via \(source.rawValue)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: source.icon)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                ZStack {
                    AnimatedProgressRing(
                        progress: progress,
                        lineWidth: 15,
                        size: 200,
                        colors: [.white, .white.opacity(0.8), .white.opacity(0.6)]
                    )
                    
                    VStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        } else {
                            AnimatedCounter(value: steps)
                                .foregroundColor(.white)
                            
                            Text("steps_label".localized)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\("goal_label".localized): \(goal.formatted())")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(floors) \("floors_label".localized)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))% \("complete_label".localized)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct AccelerometerVisualization: View {
    @ObservedObject var stepCounter: AccelerometerStepCounter
    @State private var wavePhase: CGFloat = 0
    
    var body: some View {
        GlassmorphismCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Motion Sensor")
                        .font(.headline)
                    
                    Spacer()
                    
                    if stepCounter.isTracking {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                                .frame(width: 8, height: 8)
                                .pulseEffect(color: .green.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                            
                            Text("Detecting")
                                .font(.caption)
                                .foregroundColor(.green.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                        }
                    }
                }
                
                // Accelerometer data visualization
                HStack(spacing: 20) {
                    VStack {
                        Text("X")
                            .font(.caption)
                            .foregroundColor(.red.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                        
                        Text(String(format: "%.2f", stepCounter.acceleration.x))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    VStack {
                        Text("Y")
                            .font(.caption)
                            .foregroundColor(.green.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                        
                        Text(String(format: "%.2f", stepCounter.acceleration.y))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    VStack {
                        Text("Z")
                            .font(.caption)
                            .foregroundColor(.blue.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                        
                        Text(String(format: "%.2f", stepCounter.acceleration.z))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                
                // Wave visualization
                WaveShape(phase: wavePhase, amplitude: abs(stepCounter.acceleration.y) * 50)
                    .stroke(Color.blue.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType).opacity(0.6), lineWidth: 2)
                    .frame(height: 60)
                    .animation(.easeInOut(duration: 0.1), value: stepCounter.acceleration.y)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * 4 * .pi + phase)
            let y = midY + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct ModernPermissionView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        GradientCard(gradient: Color.primaryGradient(for: UserSettings.shared.colorBlindnessType)) {
            VStack(spacing: 24) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .pulseEffect(color: .white, intensity: 0.3)
                
                VStack(spacing: 12) {
                    Text("Health Data Access")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enable HealthKit to track your steps and health metrics automatically.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Button(action: {
                    healthKitManager.requestAuthorization()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                        Text("Grant Access")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.white)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct ModernQuickActionsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var stepCounter: AccelerometerStepCounter
    @Binding var isTracking: Bool
    let selectedSource: StepTrackingView.StepSource
    @State private var showingCalibration = false
    @State private var showingGoalSetting = false
    @State private var showingHistory = false
    
    var body: some View {
        GlassmorphismCard {
            VStack(spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StepQuickActionButton(
                        title: "Refresh Data",
                        icon: "arrow.clockwise",
                        color: .blue
                    ) {
                        refreshData()
                    }
                    
                    if selectedSource == .accelerometer {
                        StepQuickActionButton(
                            title: isTracking ? "Stop Tracking" : "Start Tracking",
                            icon: isTracking ? "stop.circle" : "play.circle",
                            color: isTracking ? .red : .green
                        ) {
                            toggleTracking()
                        }
                        
                        StepQuickActionButton(
                            title: "Reset Steps",
                            icon: "arrow.counterclockwise",
                            color: .orange
                        ) {
                            resetSteps()
                        }
                        
                        StepQuickActionButton(
                            title: "Calibrate",
                            icon: "tuningfork",
                            color: .purple
                        ) {
                            showingCalibration = true
                        }
                    } else {
                        StepQuickActionButton(
                            title: "Set Goal",
                            icon: "target",
                            color: .green
                        ) {
                            showingGoalSetting = true
                        }
                        
                        StepQuickActionButton(
                            title: "View History",
                            icon: "clock.arrow.circlepath",
                            color: .orange
                        ) {
                            showingHistory = true
                        }
                        
                        // StepQuickActionButton(
                        //     title: "Sync with Apple Watch",
                        //     icon: "applewatch",
                        //     color: .green
                        // ) {
                        //     healthKitManager.syncWithAppleWatch()
                        // }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCalibration) {
            CalibrationView(stepCounter: stepCounter)
        }
        .sheet(isPresented: $showingGoalSetting) {
            GoalSettingView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(healthKitManager: healthKitManager)
        }
    }
    
    private func toggleTracking() {
        if isTracking {
            stepCounter.stopTracking()
        } else {
            stepCounter.startTracking()
        }
        isTracking.toggle()
    }
    
    private func refreshData() {
        healthKitManager.fetchTodayData()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func resetSteps() {
        stepCounter.resetStepCount()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct StepQuickActionButton: View {
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

struct StepCounterCard: View {
    let steps: Int
    let goal: Int
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: min(Double(steps) / Double(goal), 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [
                                .blue.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType),
                                .purple.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: steps)
                
                VStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else {
                        Text("\(steps)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("steps")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Goal: \(goal.formatted()) steps")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct MetricCard: View {
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
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct PermissionView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Health Data Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("To track your steps and provide health insights, we need access to your Health data.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Grant Access") {
                healthKitManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct QuickActionsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: {
                    healthKitManager.fetchTodayData()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // Add goal setting action
                }) {
                    HStack {
                        Image(systemName: "target")
                        Text("Set Goal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    StepTrackingView(healthKitManager: HealthKitManager())
}
