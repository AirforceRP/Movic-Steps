//
//  GoalSettingView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/20/25.
//  9/20/25 - Added a new goal setting view
//  179 Lines of Code
//

import SwiftUI

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = UserSettings.shared
    @State private var tempGoal: Int
    @State private var goalChanged = false
    
    init() {
        let currentGoal = UserSettings.shared.dailyStepGoal
        _tempGoal = State(initialValue: currentGoal)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.green.adjustedForColorBlindness(settings.colorBlindnessType))
                    
                    Text("Set Your Daily Goal")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Choose a step goal that challenges you while being achievable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Goal Selector
                VStack(spacing: 20) {
                    Text("\(tempGoal)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green.adjustedForColorBlindness(settings.colorBlindnessType))
                        .animation(.easeInOut(duration: 0.2), value: tempGoal)
                    
                    Text("steps per day")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Slider
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { Double(tempGoal) },
                            set: { newValue in
                                let roundedValue = Int(newValue / 500) * 500
                                if roundedValue != tempGoal {
                                    tempGoal = roundedValue
                                    goalChanged = true
                                }
                            }
                        ), in: 1000...50000, step: 500)
                        .accentColor(.green.adjustedForColorBlindness(settings.colorBlindnessType))
                        
                        HStack {
                            Text("1,000")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("50,000")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Quick Goal Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Options")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        GoalOptionButton(goal: 5000, currentGoal: $tempGoal, goalChanged: $goalChanged)
                        GoalOptionButton(goal: 8000, currentGoal: $tempGoal, goalChanged: $goalChanged)
                        GoalOptionButton(goal: 10000, currentGoal: $tempGoal, goalChanged: $goalChanged)
                        GoalOptionButton(goal: 12000, currentGoal: $tempGoal, goalChanged: $goalChanged)
                        GoalOptionButton(goal: 15000, currentGoal: $tempGoal, goalChanged: $goalChanged)
                        GoalOptionButton(goal: 20000, currentGoal: $tempGoal, goalChanged: $goalChanged)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveGoal) {
                    Text("Save Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(goalChanged ? Color.green.adjustedForColorBlindness(settings.colorBlindnessType) : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!goalChanged)
            }
            .padding()
            .navigationTitle("Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveGoal() {
        settings.dailyStepGoal = tempGoal
        goalChanged = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

struct GoalOptionButton: View {
    let goal: Int
    @Binding var currentGoal: Int
    @Binding var goalChanged: Bool
    @StateObject private var settings = UserSettings.shared
    
    private var isSelected: Bool {
        currentGoal == goal
    }
    
    var body: some View {
        Button(action: {
            currentGoal = goal
            goalChanged = true
        }) {
            VStack(spacing: 4) {
                Text("\(goal)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.adjustedForColorBlindness(settings.colorBlindnessType).opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.green.adjustedForColorBlindness(settings.colorBlindnessType) : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundColor(isSelected ? .green.adjustedForColorBlindness(settings.colorBlindnessType) : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

#Preview {
    GoalSettingView()
}
