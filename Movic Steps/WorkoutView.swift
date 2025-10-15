//
//  WorkoutView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import HealthKit

struct WorkoutView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var heartRateManager = HeartRateManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedWorkoutType: WorkoutType = .walking
    @State private var isWorkoutActive = false
    @State private var workoutStartTime: Date?
    @State private var showingWorkoutHistory = false
    
    enum WorkoutType: String, CaseIterable {
        case walking = "walking"
        case running = "running"
        case cycling = "cycling"
        case swimming = "swimming"
        case strength = "strength"
        case yoga = "yoga"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .walking: return "Walking"
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .swimming: return "Swimming"
            case .strength: return "Strength Training"
            case .yoga: return "Yoga"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .walking: return "figure.walk"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .swimming: return "figure.pool.swim"
            case .strength: return "dumbbell"
            case .yoga: return "figure.mind.and.body"
            case .other: return "figure.mixed.cardio"
            }
        }
        
        var color: Color {
            switch self {
            case .walking: return .blue
            case .running: return .red
            case .cycling: return .green
            case .swimming: return .cyan
            case .strength: return .orange
            case .yoga: return .purple
            case .other: return .gray
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [selectedWorkoutType.color.opacity(0.1), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        WorkoutHeaderView()
                        
                        // Workout type selector
                        WorkoutTypeSelector(selectedType: $selectedWorkoutType)
                        
                        // Main workout card
                        if isWorkoutActive {
                            ActiveWorkoutCard(
                                workoutType: selectedWorkoutType,
                                startTime: workoutStartTime ?? Date(),
                                onStop: stopWorkout
                            )
                        } else {
                            WorkoutStartCard(
                                workoutType: selectedWorkoutType,
                                onStart: startWorkout
                            )
                        }
                        
                        // Workout metrics
                        WorkoutMetricsView(
                            healthKitManager: healthKitManager,
                            heartRateManager: heartRateManager
                        )
                        
                        // Recent workouts
                        RecentWorkoutsSection(onViewAll: { showingWorkoutHistory = true })
                        
                        // Quick actions
                        WorkoutQuickActionsView(
                            onViewHistory: { showingWorkoutHistory = true },
                            onRefresh: { healthKitManager.fetchTodayData() }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            healthKitManager.fetchTodayData()
        }
        .sheet(isPresented: $showingWorkoutHistory) {
            WorkoutHistoryView()
        }
        .onAppear {
            if !healthKitManager.isAuthorized {
                healthKitManager.requestAuthorization()
            } else {
                healthKitManager.fetchTodayData()
            }
        }
    }
    
    private func startWorkout() {
        isWorkoutActive = true
        workoutStartTime = Date()
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        workoutStartTime = nil
    }
}

// MARK: - Header View
struct WorkoutHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track your fitness activities")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "figure.mixed.cardio")
                .font(.title)
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Workout Type Selector
struct WorkoutTypeSelector: View {
    @Binding var selectedType: WorkoutView.WorkoutType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Workout Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(WorkoutView.WorkoutType.allCases, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(selectedType == type ? .white : type.color)
                            
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedType == type ? .white : .primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == type ? type.color : Color(.systemGray6))
                        )
                    }
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

// MARK: - Workout Start Card
struct WorkoutStartCard: View {
    let workoutType: WorkoutView.WorkoutType
    let onStart: () -> Void
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(workoutType.color.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Image(systemName: workoutType.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(workoutType.color)
            }
            
            VStack(spacing: 12) {
                Text("Ready to \(workoutType.displayName.lowercased())?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Tap start to begin tracking your workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Button(action: onStart) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Start Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [workoutType.color, workoutType.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: workoutType.color.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    onStart()
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
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
            pulseAnimation = true
        }
    }
}

// MARK: - Active Workout Card
struct ActiveWorkoutCard: View {
    let workoutType: WorkoutView.WorkoutType
    let startTime: Date
    let onStop: () -> Void
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("In Progress")
                        .font(.subheadline)
                        .foregroundColor(workoutType.color)
                }
                
                Spacer()
                
                Image(systemName: workoutType.icon)
                    .font(.title)
                    .foregroundColor(workoutType.color)
            }
            
            VStack(spacing: 8) {
                Text(formatTime(elapsedTime))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text("Elapsed Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onStop) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("Stop Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.red)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Workout Metrics
struct WorkoutMetricsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var heartRateManager: HeartRateManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Workout Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WorkoutMetricCard(
                    title: "Steps",
                    value: "\(healthKitManager.todaySteps)",
                    unit: "steps",
                    color: .blue,
                    icon: "figure.walk"
                )
                
                WorkoutMetricCard(
                    title: "Distance",
                    value: String(format: "%.1f", healthKitManager.todayDistance),
                    unit: "km",
                    color: .green,
                    icon: "location"
                )
                
                WorkoutMetricCard(
                    title: "Calories",
                    value: "\(healthKitManager.todayCalories)",
                    unit: "kcal",
                    color: .orange,
                    icon: "flame"
                )
                
                WorkoutMetricCard(
                    title: "Heart Rate",
                    value: "\(heartRateManager.currentHeartRate)",
                    unit: "BPM",
                    color: .red,
                    icon: "heart"
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

// MARK: - Recent Workouts
struct RecentWorkoutsSection: View {
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All", action: onViewAll)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(0..<3) { index in
                    WorkoutRow(
                        type: .walking,
                        duration: "25 min",
                        date: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
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

// MARK: - Workout Row
struct WorkoutRow: View {
    let type: WorkoutView.WorkoutType
    let duration: String
    let date: Date
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(type.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Actions
struct WorkoutQuickActionsView: View {
    let onViewHistory: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                WorkoutQuickActionButton(
                    title: "Workout History",
                    icon: "clock.arrow.circlepath",
                    color: .blue
                ) {
                    onViewHistory()
                }
                
                WorkoutQuickActionButton(
                    title: "Refresh Data",
                    icon: "arrow.clockwise",
                    color: .green
                ) {
                    onRefresh()
                }
                
                WorkoutQuickActionButton(
                    title: "Set Goals",
                    icon: "target",
                    color: .orange
                ) {
                    // Goal setting action
                }
                
                WorkoutQuickActionButton(
                    title: "Share Progress",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    // Share action
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

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout History")
                    .font(.title)
                    .padding()
                
                Text("Your workout history will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Workout History")
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

// MARK: - Quick Action Button
struct WorkoutQuickActionButton: View {
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
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Workout Metric Card
struct WorkoutMetricCard: View {
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
    WorkoutView()
}
