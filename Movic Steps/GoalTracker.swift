//
//  GoalTracker.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import SwiftUI
import SwiftData

class GoalTracker: ObservableObject {
    static let shared = GoalTracker()
    
    @Published var dailyStepGoalAchieved = false
    @Published var lastNotificationDate: Date?
    
    private let notificationManager = NotificationManager.shared
    private let userSettings = UserSettings.shared
    
    // Track which milestones have been reached today
    private var milestonesReached: Set<Int> = []
    private var goalsAchievedToday: Set<String> = []
    
    // Milestone thresholds
    private let milestones = [1000, 2500, 5000, 7500, 10000, 12500, 15000, 20000, 25000, 30000, 35000, 40000, 45000, 50000, 55000, 60000, 65000, 70000, 75000, 80000, 85000, 90000, 95000, 100000]
    
    private init() {
        resetDailyTracking()
    }
    
    // MARK: - Goal Progress Monitoring
    func updateStepProgress(_ currentSteps: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastNotificationDay = lastNotificationDate.map { Calendar.current.startOfDay(for: $0) }
        
        // Reset tracking if it's a new day
        if lastNotificationDay != today {
            resetDailyTracking()
        }
        
        // Check daily step goal
        checkDailyStepGoal(currentSteps: currentSteps)
        
        // Check milestones
        checkMilestones(currentSteps: currentSteps)
        
        // Check if we need encouragement (if user is behind on goals)
        checkForEncouragement(currentSteps: currentSteps)
        
        lastNotificationDate = Date()
    }
    
    func updateGoalProgress(_ goals: [HealthGoal], healthData: (steps: Int, distance: Double, calories: Double, activeMinutes: Int)) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastNotificationDay = lastNotificationDate.map { Calendar.current.startOfDay(for: $0) }
        
        // Reset tracking if it's a new day
        if lastNotificationDay != today {
            resetDailyTracking()
        }
        
        for goal in goals where goal.isActive {
            let goalId = "\(goal.type.rawValue)_\(today.timeIntervalSince1970)"
            
            // Update current value based on health data
            let currentValue: Double
            switch goal.type {
            case .steps:
                currentValue = Double(healthData.steps)
            case .distance:
                currentValue = healthData.distance
            case .calories:
                currentValue = healthData.calories
            case .activeMinutes:
                currentValue = Double(healthData.activeMinutes)
            }
            
            goal.currentValue = currentValue
            let progress = goal.progress
            
            // Check if goal was just achieved (100% or overachiever 150-200%)
            if progress >= 1.0 && !goalsAchievedToday.contains(goalId) {
                notificationManager.sendGoalAchievementNotification(
                    goalType: goal.type,
                    currentValue: currentValue,
                    targetValue: goal.targetValue
                )
                goalsAchievedToday.insert(goalId)
                
                // Add haptic feedback
                if userSettings.enableHapticFeedback {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }
                
                if progress >= 1.5 {
                    print("🚨 OVERACHIEVER! \(goal.type.rawValue) - \(currentValue)/\(goal.targetValue) (\(Int(progress * 100))%)")
                } else {
                    print("🎉 Goal achieved: \(goal.type.rawValue) - \(currentValue)/\(goal.targetValue)")
                }
            }
            // Check if user needs encouragement (goal is less than 50% complete and it's past noon)
            else if progress < 0.5 && shouldSendEncouragement() && !goalsAchievedToday.contains("\(goalId)_reminder") {
                let timeRemaining = getTimeRemainingInDay()
                notificationManager.sendGoalFailureNotification(
                    goalType: goal.type,
                    currentValue: currentValue,
                    targetValue: goal.targetValue,
                    timeRemaining: timeRemaining
                )
                goalsAchievedToday.insert("\(goalId)_reminder")
                
                print("⏰ Sent reminder for \(goal.type.rawValue) - \(Int(progress * 100))% complete")
            }
        }
        
        lastNotificationDate = Date()
    }
    
    // MARK: - Daily Step Goal Tracking
    private func checkDailyStepGoal(currentSteps: Int) {
        let dailyGoal = userSettings.dailyStepGoal
        
        if currentSteps >= dailyGoal && !dailyStepGoalAchieved {
            dailyStepGoalAchieved = true
            
            notificationManager.sendGoalAchievementNotification(
                goalType: .steps,
                currentValue: Double(currentSteps),
                targetValue: Double(dailyGoal)
            )
            
            // Add haptic feedback
            if userSettings.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
            
            print("🎉 Daily step goal achieved: \(currentSteps)/\(dailyGoal)")
        }
    }
    
    // MARK: - Milestone Tracking
    private func checkMilestones(currentSteps: Int) {
        for milestone in milestones {
            if currentSteps >= milestone && !milestonesReached.contains(milestone) {
                milestonesReached.insert(milestone)
                notificationManager.sendMilestoneNotification(milestone: milestone, currentSteps: currentSteps)
                
                // Add haptic feedback for milestones
                if userSettings.enableHapticFeedback {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                print("🏆 Milestone reached: \(milestone) steps")
            }
        }
    }
    
    // MARK: - Encouragement Logic
    private func checkForEncouragement(currentSteps: Int) {
        let dailyGoal = userSettings.dailyStepGoal
        let progress = Double(currentSteps) / Double(dailyGoal)
        
        // Send encouragement if user is significantly behind and it's getting late in the day
        if progress < 0.3 && shouldSendLateEncouragement() {
            notificationManager.sendEncouragementNotification()
            print("💪 Sent encouragement notification - user at \(Int(progress * 100))% of daily goal")
        }
    }
    
    // MARK: - Timing Logic
    private func shouldSendEncouragement() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Send reminders between 2 PM and 8 PM
        return hour >= 14 && hour <= 20
    }
    
    private func shouldSendLateEncouragement() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Send late encouragement between 6 PM and 9 PM
        return hour >= 18 && hour <= 21
    }
    
    private func getTimeRemainingInDay() -> String {
        let now = Date()
        let calendar = Calendar.current
        let endOfDay = calendar.dateInterval(of: .day, for: now)?.end ?? now
        let timeInterval = endOfDay.timeIntervalSince(now)
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    // MARK: - Daily Reset
    private func resetDailyTracking() {
        dailyStepGoalAchieved = false
        milestonesReached.removeAll()
        goalsAchievedToday.removeAll()
        print("🔄 Daily tracking reset")
    }
    
    // MARK: - Manual Triggers
    func sendTestNotification() {
        notificationManager.sendGoalAchievementNotification(
            goalType: .steps,
            currentValue: 10000,
            targetValue: 10000
        )
    }
    
    func sendTestReminder() {
        notificationManager.sendGoalFailureNotification(
            goalType: .steps,
            currentValue: 3000,
            targetValue: 10000,
            timeRemaining: "5 hours"
        )
    }
    
    // MARK: - Weekly Summary
    func generateWeeklySummary(weeklySteps: [Int]) -> String {
        let totalSteps = weeklySteps.reduce(0, +)
        let averageSteps = totalSteps / max(weeklySteps.count, 1)
        let maxSteps = weeklySteps.max() ?? 0
        let daysGoalMet = weeklySteps.filter { $0 >= userSettings.dailyStepGoal }.count
        
        return """
        📊 Weekly Summary:
        • Total Steps: \(totalSteps.formatted())
        • Daily Average: \(averageSteps.formatted())
        • Best Day: \(maxSteps.formatted()) steps
        • Goals Met: \(daysGoalMet)/7 days
        
        \(getWeeklyMotivation(daysGoalMet: daysGoalMet))
        """
    }
    
    private func getWeeklyMotivation(daysGoalMet: Int) -> String {
        switch daysGoalMet {
        case 7:
            return "🏆 Perfect week! You're unstoppable!"
        case 5...6:
            return "🌟 Excellent work! You're crushing your goals!"
        case 3...4:
            return "💪 Good progress! Keep building that momentum!"
        case 1...2:
            return "🚀 Every step counts! Let's aim higher next week!"
        default:
            return "🌱 New week, fresh start! You've got this!"
        }
    }
    
    // MARK: - Settings Integration
    func updateNotificationSettings() {
        notificationManager.updateNotificationSettings()
    }
}

// MARK: - Extensions
extension GoalTracker {
    func getProgressSummary(currentSteps: Int) -> String {
        let dailyGoal = userSettings.dailyStepGoal
        let progress = Double(currentSteps) / Double(dailyGoal)
        let percentage = Int(progress * 100)
        
        if progress >= 1.0 {
            return "🎉 Goal achieved! \(currentSteps) steps (\(percentage)%)"
        } else if progress >= 0.8 {
            return "🔥 Almost there! \(currentSteps) steps (\(percentage)%)"
        } else if progress >= 0.5 {
            return "💪 Halfway there! \(currentSteps) steps (\(percentage)%)"
        } else if progress >= 0.25 {
            return "🚀 Good start! \(currentSteps) steps (\(percentage)%)"
        } else {
            return "🌱 Just getting started! \(currentSteps) steps (\(percentage)%)"
        }
    }
}
