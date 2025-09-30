//
//  GoalsView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import SwiftData

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct GoalsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @EnvironmentObject var goalTracker: GoalTracker
    @Environment(\.modelContext) private var modelContext
    let _goals: [HealthGoal]
    @State private var showingAddGoal = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Goals
                    if !_goals.filter({ $0.isActive }).isEmpty {
                        ActiveGoalsSection(goals: _goals.filter { $0.isActive })
                    }
                    
                    // Add Goal Button, Also Note to James to not touch this
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Goal")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType).opacity(0.1))
                        .foregroundColor(.blue.adjustedForColorBlindness(UserSettings.shared.colorBlindnessType))
                        .cornerRadius(12)
                    }
                    
                    // Goal Categories
                    GoalCategoriesSection()
                    
                }
                .padding()
            }
            .navigationTitle("Goals")
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
            .onAppear {
                updateGoalProgress()
                // Update goal tracker with current health data
                healthKitManager.updateGoalsWithHealthData(_goals)

                // Update this took a while to figure out
            }
        }
    }
    
    private func updateGoalProgress() {
        for goal in _goals where goal.isActive {
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
        }
    }
}

struct ActiveGoalsSection: View {
    let goals: [HealthGoal]
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditGoal: HealthGoal?
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: HealthGoal?
    @State private var deletedGoalIds: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Goals")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(goals.filter { !deletedGoalIds.contains($0.id) }, id: \.id) { goal in
                    GoalCard(goal: goal, onEdit: {
                        print("Edit callback triggered for goal: \(goal.type)")
                        showingEditGoal = goal
                    }, onDelete: {
                        print("Delete callback triggered for goal: \(goal.type)")
                        goalToDelete = goal
                        showingDeleteAlert = true
                    })
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity).combined(with: .move(edge: .trailing))
                        ))
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
            .animation(.easeInOut(duration: 0.3), value: deletedGoalIds)
        }
        .sheet(item: $showingEditGoal) { goal in
            EditGoalView(goal: goal)
        }
        .onChange(of: showingEditGoal) { newValue in
            print("showingEditGoal changed to: \(newValue?.type.rawValue ?? "nil")")
        }
        .alert("⚠️ Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                goalToDelete = nil
            }
            Button("Delete Forever", role: .destructive) {
                if let goal = goalToDelete {
                    // Add haptic feedback for deletion
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    
                    // Add to deleted set for animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deletedGoalIds.insert(goal.id)
                    }
                    
                    // Delay the actual deletion to allow animation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        modelContext.delete(goal)
                        goalToDelete = nil
                        
                        // Add success haptic feedback
                        let successFeedback = UINotificationFeedbackGenerator()
                        successFeedback.notificationOccurred(.success)
                    }
                }
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("⚠️ WARNING: This action cannot be undone!")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("Once deleted, you'll need to create this goal again from scratch. All progress data will be permanently lost.")
                    .font(.subheadline)
                
                if let goal = goalToDelete {
                    Text("Goal: \(goal.type.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct GoalCard: View {
    let goal: HealthGoal
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    @StateObject private var userSettings = UserSettings.shared
    
    init(goal: HealthGoal, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.goal = goal
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    private var progressColor: Color {
        // Check if custom color is set (premium feature)
        if let customColorHex = goal.customColor,
           let customColor = Color(hex: customColorHex) {
            return customColor.adjustedForColorBlindness(userSettings.colorBlindnessType)
        }
        
        // Default color scheme
        if goal.progress >= 1.0 { return .green.adjustedForColorBlindness(userSettings.colorBlindnessType) }
        else if goal.progress >= 0.7 { return .blue.adjustedForColorBlindness(userSettings.colorBlindnessType) }
        else if goal.progress >= 0.4 { return .orange.adjustedForColorBlindness(userSettings.colorBlindnessType) }
        else { return .red.adjustedForColorBlindness(userSettings.colorBlindnessType) }
    }
    
    private var icon: String {
        switch goal.type {
        case .steps: return "figure.walk"
        case .distance: return "location"
        case .calories: return "flame"
        case .activeMinutes: return "clock"
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
    
    private var formattedCurrentValue: String {
        switch goal.type {
        case .steps:
            return "\(Int(goal.currentValue))"
        case .distance:
            if userSettings.unitSystem == .metric {
                return String(format: "%.1f", goal.currentValue / 1000) // Convert meters to km
            } else {
                let miles = goal.currentValue * 0.000621371 // Convert meters to miles
                return String(format: "%.1f", miles)
            }
        case .calories:
            return "\(Int(goal.currentValue))"
        case .activeMinutes:
            return "\(Int(goal.currentValue))"
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(progressColor)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(goal.type.rawValue.capitalized)
                        .font(.headline)
                        .textCase(.uppercase)
                    
                    Text("\(formattedCurrentValue) / \(formattedTargetValue) \(unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                if goal.progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green.adjustedForColorBlindness(userSettings.colorBlindnessType))
                        .font(.title2)
                    }
                    
                    // Edit button
                    Button(action: {
                        print("Edit button tapped for goal: \(goal.type)")
                        onEdit?()
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Delete button
                    Button(action: {
                        print("Delete button tapped for goal: \(goal.type)")
                        onDelete?()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.5), value: goal.progress)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(goal.progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct GoalCategoriesSection: View {
    private let categories = [
        GoalCategory(title: "Daily Steps", icon: "figure.walk", color: .blue, description: "Track your daily step count"),
        GoalCategory(title: "Distance", icon: "location", color: .green, description: "Set distance goals"),
        GoalCategory(title: "Calories", icon: "flame", color: .orange, description: "Burn calories through activity"),
        GoalCategory(title: "Active Time", icon: "clock", color: .purple, description: "Stay active throughout the day")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Categories")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(categories, id: \.title) { category in
                    CategoryCard(category: category)
                }
            }
        }
    }
}

struct GoalCategory {
    let title: String
    let icon: String
    let color: Color
    let description: String
}

struct CategoryCard: View {
    let category: GoalCategory
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color.adjustedForColorBlindness(userSettings.colorBlindnessType))
            
            Text(category.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(category.description)
                .font(.caption)
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
    }
}


struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var selectedType: HealthGoal.GoalType = .steps
    @State private var targetValue: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAnimating = false
    
    private let goalTypes: [(HealthGoal.GoalType, String, String, String)] = [
        (.steps, "Daily Steps", "Set a daily step goal", "figure.walk"),
        (.distance, "Distance", "Set a daily distance goal", "location"),
        (.calories, "Calories", "Set a daily calorie burn goal", "flame"),
        (.activeMinutes, "Active Minutes", "Set a daily active time goal", "clock")
    ]
    
    private var currentGoalType: (HealthGoal.GoalType, String, String, String) {
        goalTypes.first { $0.0 == selectedType } ?? goalTypes[0]
    }
    
    private var quickPresets: [Double] {
        switch selectedType {
        case .steps:
            return [5000, 8000, 10000, 12000, 15000, 20000]
        case .distance:
            return userSettings.unitSystem == .metric ? [2.0, 3.0, 5.0, 8.0, 10.0, 15.0] : [1.0, 2.0, 3.0, 5.0, 6.0, 10.0]
        case .calories:
            return [200, 300, 400, 500, 600, 800]
        case .activeMinutes:
            return [30, 45, 60, 90, 120, 150]
        }
    }
    
    private var unit: String {
        switch selectedType {
        case .steps:
            return "steps"
        case .distance:
            return userSettings.unitSystem.distanceUnit
        case .calories:
            return "cal"
        case .activeMinutes:
            return "min"
        }
    }
    
    private var isValidInput: Bool {
        guard let value = Double(targetValue) else { return false }
        return value > 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: currentGoalType.3)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text("Add New Goal")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(currentGoalType.2)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Goal Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Goal Type")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(goalTypes, id: \.0) { type, title, description, icon in
                                GoalTypeCard(
                                    type: type,
                                    title: title,
                                    description: description,
                                    icon: icon,
                                    isSelected: selectedType == type,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedType = type
                                            targetValue = "" // Reset target value when type changes
                                        }
                                        
                                        // Add haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                )
                            }
                        }
                    }
                    
                    // Target Value Input
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Target Value")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Enter target value", text: $targetValue)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isValidInput ? Color.green : Color.clear, lineWidth: 2)
                                    )
                                
                                Text(unit)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !targetValue.isEmpty && !isValidInput {
                                Text("Please enter a valid number greater than 0")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                            }
                        }
                        
                        // Quick Presets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Options")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(quickPresets, id: \.self) { preset in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            targetValue = String(format: preset.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", preset)
                                        }
                                        
                                        // Add haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        Text(formatPresetValue(preset))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(targetValue == String(format: preset.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", preset) ? .white : .blue)
                    .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                    .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(targetValue == String(format: preset.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", preset) ? Color.blue : Color.blue.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                    .foregroundColor(isValidInput ? .blue : .gray)
                }
            }
            .alert("Invalid Input", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
    
    private func formatPresetValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private func saveGoal() {
        guard let value = Double(targetValue), value > 0 else {
            alertMessage = "Please enter a valid number greater than 0 for your goal."
            showingAlert = true
            return
        }
        
        // Validate reasonable ranges
        let isValidRange: Bool
        switch selectedType {
        case .steps:
            isValidRange = value >= 1000 && value <= 100000
            if !isValidRange {
                alertMessage = "Step goals should be between 1,000 and 100,000 steps."
            }
        case .distance:
            let maxDistance = userSettings.unitSystem == .metric ? 100.0 : 60.0
            isValidRange = value >= 0.1 && value <= maxDistance
            if !isValidRange {
                alertMessage = "Distance goals should be between 0.1 and \(maxDistance) \(unit)."
            }
        case .calories:
            isValidRange = value >= 50 && value <= 2000
            if !isValidRange {
                alertMessage = "Calorie goals should be between 50 and 2,000 calories."
            }
        case .activeMinutes:
            isValidRange = value >= 5 && value <= 480
            if !isValidRange {
                alertMessage = "Active minute goals should be between 5 and 480 minutes."
            }
        }
        
        guard isValidRange else {
            showingAlert = true
            return
        }
        
        // Convert distance to meters if needed
        let finalValue: Double
        if selectedType == .distance && userSettings.unitSystem == .imperial {
            finalValue = value * 1609.34 // Convert miles to meters
        } else {
            finalValue = value
        }
        
        let newGoal = HealthGoal(type: selectedType, targetValue: finalValue)
        modelContext.insert(newGoal)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var userSettings = UserSettings.shared
    
    let goal: HealthGoal
    
    @State private var targetValue: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAnimating = false
    
    private var unit: String {
        switch goal.type {
        case .steps:
            return "steps"
        case .distance:
            return userSettings.unitSystem.distanceUnit
        case .calories:
            return "cal"
        case .activeMinutes:
            return "min"
        }
    }
    
    private var quickPresets: [Double] {
        switch goal.type {
        case .steps:
            return [5000, 8000, 10000, 12000, 15000, 20000]
        case .distance:
            return userSettings.unitSystem == .metric ? [2.0, 3.0, 5.0, 8.0, 10.0, 15.0] : [1.0, 2.0, 3.0, 5.0, 6.0, 10.0]
        case .calories:
            return [200, 300, 400, 500, 600, 800]
        case .activeMinutes:
            return [30, 45, 60, 90, 120, 150]
        }
    }
    
    private var isValidInput: Bool {
        guard let value = Double(targetValue) else { return false }
        return value > 0
    }
    
    private var icon: String {
        switch goal.type {
        case .steps: return "figure.walk"
        case .distance: return "location"
        case .calories: return "flame"
        case .activeMinutes: return "clock"
        }
    }
    
    private var title: String {
        switch goal.type {
        case .steps: return "Daily Steps"
        case .distance: return "Distance"
        case .calories: return "Calories"
        case .activeMinutes: return "Active Minutes"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text("Edit Goal")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Update your \(title.lowercased()) goal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Current Goal Info
                    VStack(spacing: 12) {
                        Text("Current Goal")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text(formatCurrentValue())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(unit)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    
                    // Target Value Input
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New Target Value")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Enter new target value", text: $targetValue)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isValidInput ? Color.green : Color.clear, lineWidth: 2)
                                    )
                                
                                Text(unit)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !targetValue.isEmpty && !isValidInput {
                                Text("Please enter a valid number greater than 0")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                            }
                        }
                        
                        // Quick Presets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Options")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(quickPresets, id: \.self) { preset in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            targetValue = String(format: preset.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", preset)
                                        }
                                        
                                        // Add haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        Text(formatPresetValue(preset))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(targetValue == String(format: preset.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", preset) ? .white : .blue)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(targetValue == String(format: preset.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", preset) ? Color.blue : Color.blue.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                    .foregroundColor(isValidInput ? .blue : .gray)
                }
            }
            .alert("Invalid Input", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                isAnimating = true
                // Initialize with current target value
                targetValue = formatCurrentValue()
            }
        }
    }
    
    private func formatCurrentValue() -> String {
        let value = goal.targetValue
        
        // Convert meters to appropriate unit for display
        if goal.type == .distance && userSettings.unitSystem == .imperial {
            let miles = value * 0.000621371
            return String(format: miles.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", miles)
        } else if goal.type == .distance && userSettings.unitSystem == .metric {
            let km = value / 1000
            return String(format: km.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", km)
        } else {
            return String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)
        }
    }
    
    private func formatPresetValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private func saveGoal() {
        guard let value = Double(targetValue), value > 0 else {
            alertMessage = "Please enter a valid number greater than 0 for your goal."
            showingAlert = true
            return
        }
        
        // Validate reasonable ranges
        let isValidRange: Bool
        switch goal.type {
        case .steps:
            isValidRange = value >= 1000 && value <= 100000
            if !isValidRange {
                alertMessage = "Step goals should be between 1,000 and 100,000 steps."
            }
        case .distance:
            let maxDistance = userSettings.unitSystem == .metric ? 100.0 : 60.0
            isValidRange = value >= 0.1 && value <= maxDistance
            if !isValidRange {
                alertMessage = "Distance goals should be between 0.1 and \(maxDistance) \(unit)."
            }
        case .calories:
            isValidRange = value >= 50 && value <= 2000
            if !isValidRange {
                alertMessage = "Calorie goals should be between 50 and 2,000 calories."
            }
        case .activeMinutes:
            isValidRange = value >= 5 && value <= 480
            if !isValidRange {
                alertMessage = "Active minute goals should be between 5 and 480 minutes."
            }
        }
        
        guard isValidRange else {
            showingAlert = true
            return
        }
        
        // Convert distance to meters if needed
        let finalValue: Double
        if goal.type == .distance && userSettings.unitSystem == .imperial {
            finalValue = value * 1609.34 // Convert miles to meters
        } else {
            finalValue = value
        }
        
        // Update the goal
        goal.targetValue = finalValue
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

struct GoalTypeCard: View {
    let type: HealthGoal.GoalType
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    GoalsView(healthKitManager: HealthKitManager(), _goals: [])
}
