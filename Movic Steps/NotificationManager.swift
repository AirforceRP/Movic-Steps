//
//  NotificationManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/20/25.
//  Small changes made by me
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined



   // Man this file Sucks Ass
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                
                if granted {
                    print("Notification permission granted")
                    self?.scheduleInitialNotifications()
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Goal Achievement Notifications
    func sendGoalAchievementNotification(goalType: HealthGoal.GoalType, currentValue: Double, targetValue: Double) {
        guard isAuthorized && UserSettings.shared.enableNotifications else { return }
        
        let progress = currentValue / targetValue
        let percentage = Int(progress * 100)
        
        let content = UNMutableNotificationContent()
        let formattedValue = formatGoalValue(goalType: goalType, value: currentValue)
        let formattedTarget = formatGoalValue(goalType: goalType, value: targetValue)
        
        // Check if this is an overachiever (150-200% of goal)
        if progress >= 1.5 && progress <= 2.0 {
            content.title = "🚨 OVERACHIEVER ALERT! 🚨"
            
            switch goalType {
            case .steps:
                content.body = getRandomStepsOverachieverMessage(current: formattedValue, target: formattedTarget, percentage: percentage)
            case .distance:
                content.body = getRandomDistanceOverachieverMessage(current: formattedValue, target: formattedTarget, percentage: percentage)
            case .calories:
                content.body = getRandomCaloriesOverachieverMessage(current: formattedValue, target: formattedTarget, percentage: percentage)
            case .activeMinutes:
                content.body = getRandomActiveMinutesOverachieverMessage(current: formattedValue, target: formattedTarget, percentage: percentage)
            }
            
            content.categoryIdentifier = "OVERACHIEVER_ALERT"
        } else {
            // Regular goal achievement
            content.title = getRandomTitle(for: .goalAchieved)
            
            switch goalType {
            case .steps:
                content.body = getRandomStepsAchievementMessage(target: formattedTarget)
            case .distance:
                content.body = getRandomDistanceAchievementMessage(value: formattedValue)
            case .calories:
                content.body = getRandomCaloriesAchievementMessage(value: formattedValue)
            case .activeMinutes:
                content.body = getRandomActiveMinutesAchievementMessage(value: formattedValue)
            }
            
            content.categoryIdentifier = "GOAL_ACHIEVEMENT"
        }
        
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        content.badge = 1
        
        // Add celebration action for regular goals
        let celebrateAction = UNNotificationAction(
            identifier: "CELEBRATE_ACTION",
            title: "🎉 Celebrate",
            options: []
        )
        
        let shareAction = UNNotificationAction(
            identifier: "SHARE_ACTION",
            title: "📱 Share Achievement",
            options: []
        )
        
        // Add fire extinguisher action for overachievers
        let fireExtinguisherAction = UNNotificationAction(
            identifier: "FIRE_EXTINGUISHER_ACTION",
            title: "🧯 Cool Down",
            options: []
        )
        
        let goalCategory = UNNotificationCategory(
            identifier: "GOAL_ACHIEVEMENT",
            actions: [celebrateAction, shareAction],
            intentIdentifiers: [],
            options: []
        )
        
        let overachieverCategory = UNNotificationCategory(
            identifier: "OVERACHIEVER_ALERT",
            actions: [fireExtinguisherAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([goalCategory, overachieverCategory])
        
        let request = UNNotificationRequest(
            identifier: "goal_achievement_\(goalType.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Send immediately
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send goal achievement notification: \(error)")
            } else {
                print("✅ Goal achievement notification sent for \(goalType.rawValue)")
            }
        }
    }
    
    func sendGoalFailureNotification(goalType: HealthGoal.GoalType, currentValue: Double, targetValue: Double, timeRemaining: String) {
        guard isAuthorized && UserSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = getRandomGoalReminderTitle()
        
        let formattedCurrent = formatGoalValue(goalType: goalType, value: currentValue)
        let formattedTarget = formatGoalValue(goalType: goalType, value: targetValue)
        let progress = (currentValue / targetValue) * 100
        
        switch goalType {
        case .steps:
            content.body = getRandomStepsReminderMessage(current: formattedCurrent, target: formattedTarget, progress: Int(progress), timeRemaining: timeRemaining)
        case .distance:
            content.body = getRandomDistanceReminderMessage(current: formattedCurrent, target: formattedTarget, progress: Int(progress), timeRemaining: timeRemaining)
        case .calories:
            content.body = getRandomCaloriesReminderMessage(current: formattedCurrent, target: formattedTarget, progress: Int(progress), timeRemaining: timeRemaining)
        case .activeMinutes:
            content.body = getRandomActiveMinutesReminderMessage(current: formattedCurrent, target: formattedTarget, progress: Int(progress), timeRemaining: timeRemaining)
        }
        
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        content.categoryIdentifier = "GOAL_REMINDER"
        
        let motivateAction = UNNotificationAction(
            identifier: "MOTIVATE_ACTION",
            title: "💪 Get Moving",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "⏰ Remind Later",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "GOAL_REMINDER",
            actions: [motivateAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([category])
        
        let request = UNNotificationRequest(
            identifier: "goal_reminder_\(goalType.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Send immediately
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send goal reminder notification: \(error)")
            } else {
                print("✅ Goal reminder notification sent for \(goalType.rawValue)")
            }
        }
    }
    
    // MARK: - Daily Reminders
    func scheduleDailyGoalReminder() {
        guard isAuthorized && UserSettings.shared.enableNotifications else { return }
        guard UserSettings.shared.goalReminderTime != .off else { return }
        
        // Remove existing daily reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_goal_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = getRandomTitle(for: .reminder)
        content.body = getRandomReminderMessage()
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // Parse reminder time
        let timeComponents = UserSettings.shared.goalReminderTime.rawValue.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let checkProgressAction = UNNotificationAction(
            identifier: "CHECK_PROGRESS_ACTION",
            title: "📊 Check Progress",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [checkProgressAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([category])
        
        let request = UNNotificationRequest(
            identifier: "daily_goal_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily reminder: \(error)")
            } else {
                print("✅ Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // MARK: - Milestone Notifications
    func sendMilestoneNotification(milestone: Int, currentSteps: Int) {
        guard isAuthorized && UserSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Milestone Reached!"
        content.body = "Fantastic! You've reached \(milestone) steps today! Keep up the great work! 🚶‍♂️✨"
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "milestone_\(milestone)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send milestone notification: \(error)")
            } else {
                print("✅ Milestone notification sent for \(milestone) steps")
            }
        }
    }
    
    // MARK: - Weekly Summary
    func scheduleWeeklySummaryNotification() {
        guard isAuthorized && UserSettings.shared.enableNotifications && UserSettings.shared.showWeeklyReport else { return }
        
        // Remove existing weekly summary
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])
        
        let content = UNMutableNotificationContent()
        content.title = getRandomTitle(for: .weekly)
        content.body = getRandomWeeklyMessage()
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        
        // Schedule for Sunday at 8 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule weekly summary: \(error)")
            } else {
                print("✅ Weekly summary notification scheduled")
            }
        }
    }
    
    // MARK: - Encouragement Notifications
    func sendEncouragementNotification() {
        guard isAuthorized && UserSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = getRandomTitle(for: .encouragement)
        content.body = getRandomEncouragementMessage()
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        
        let request = UNNotificationRequest(
            identifier: "encouragement_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send encouragement notification: \(error)")
            } else {
                print("✅ Encouragement notification sent")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatGoalValue(goalType: HealthGoal.GoalType, value: Double) -> String {
        switch goalType {
        case .steps:
            return String(Int(value))
        case .distance:
            return UserSettings.shared.formatDistance(value)
        case .calories:
            return String(Int(value))
        case .activeMinutes:
            return String(Int(value))
        }
    }
    
    private func scheduleInitialNotifications() {
        scheduleDailyGoalReminder()
        scheduleWeeklySummaryNotification()
    }
    
    // MARK: - Notification Management
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("🗑️ All notifications cancelled")
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled notification: \(identifier)")
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        center.getPendingNotificationRequests(completionHandler: completion)
    }
    
    func updateNotificationSettings() {
        if UserSettings.shared.enableNotifications && isAuthorized {
            scheduleDailyGoalReminder()
            scheduleWeeklySummaryNotification()
        } else {
            cancelAllNotifications()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let notification = response.notification
        
        switch actionIdentifier {
        case "CELEBRATE_ACTION":
            // Trigger celebration animation or haptic feedback
            if UserSettings.shared.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
            print("🎉 User celebrated achievement!")
            
        case "SHARE_ACTION":
            // Handle sharing achievement
            print("📱 User wants to share achievement")
            
        case "MOTIVATE_ACTION":
            // Open app to step tracking view
            print("💪 User wants motivation - opening app")
            
        case "SNOOZE_ACTION":
            // Schedule reminder for 1 hour later
            scheduleSnoozeReminder()
            print("⏰ User snoozed reminder")
            
        case "CHECK_PROGRESS_ACTION":
            // Open app to show progress
            print("📊 User wants to check progress")
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            print("👆 User tapped notification")
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func scheduleSnoozeReminder() {
        let content = UNMutableNotificationContent()
        content.title = getRandomTitle(for: .reminder)
        content.body = getRandomReminderMessage()
        content.sound = UserSettings.shared.enableSounds ? UNNotificationSound(named: UNNotificationSoundName("Movic Sound notification.m4a")) : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour
        
        let request = UNNotificationRequest(
            identifier: "snooze_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule snooze reminder: \(error)")
            } else {
                print("✅ Snooze reminder scheduled for 1 hour")
            }
        }
    }
    
    // MARK: - Random Phrase Generation
    private enum NotificationType {
        case goalAchieved, reminder, encouragement, milestone, weekly
    }
    
    private func getRandomTitle(for type: NotificationType) -> String {
        switch type {
        case .goalAchieved:
            let titles = [
                "🎉 Goal Achieved!",
                "🏆 Mission Accomplished!",
                "⭐ You Did It!",
                "🎯 Target Reached!",
                "👏 Amazing Work!",
                "🚀 Goal Crushed!",
                "💪 Victory!"
            ]
            return titles.randomElement() ?? "🎉 Goal Achieved!"
            
        case .reminder:
            let titles = [
                "🎯 Daily Goal Check",
                "⏰ Step Reminder",
                "📱 Health Check-In",
                "🚶‍♂️ Move Time!",
                "💪 Stay Active!",
                "🌟 Progress Update",
                "🎪 Activity Alert"
            ]
            return titles.randomElement() ?? "🎯 Daily Goal Check"
            
        case .encouragement:
            let titles = [
                "💪 Keep Going!",
                "🌟 You've Got This!",
                "🚀 Stay Strong!",
                "⚡ Power Up!",
                "🔥 On Fire!",
                "🎯 Almost There!",
                "👑 Champion Mode!"
            ]
            return titles.randomElement() ?? "💪 Keep Going!"
            
        case .milestone:
            let titles = [
                "🏅 Milestone Reached!",
                "🎊 New Record!",
                "⭐ Achievement Unlocked!",
                "🏆 Personal Best!",
                "🚀 Level Up!",
                "💎 Milestone Moment!",
                "🎯 Progress Milestone!"
            ]
            return titles.randomElement() ?? "🏅 Milestone Reached!"
            
        case .weekly:
            let titles = [
                "📊 Weekly Summary",
                "📈 Week in Review",
                "🗓️ Weekly Report",
                "📋 Your Week's Progress",
                "🎯 Weekly Achievements",
                "📊 7-Day Summary",
                "🏆 Weekly Highlights"
            ]
            return titles.randomElement() ?? "📊 Weekly Summary"
        }
    }
    
    private func getRandomStepsAchievementMessage(target: String) -> String {
        let messages = [
            "Congratulations! You've reached your daily step goal of \(target) steps! 🚶‍♂️",
            "Amazing work! \(target) steps completed today! Your dedication is inspiring! 👏",
            "You did it! \(target) steps in the bag! Time to celebrate your success! 🎉",
            "Fantastic! Your daily goal of \(target) steps is complete! Keep up the momentum! 🌟",
            "Mission accomplished! \(target) steps achieved! You're unstoppable! 💪",
            "Boom! \(target) steps conquered today! Your consistency is paying off! 🚀",
            "Outstanding! You've walked \(target) steps today! Every step counts! ⭐"
        ]
        return messages.randomElement() ?? "Congratulations! You've reached your daily step goal of \(target) steps! 🚶‍♂️"
    }
    
    private func getRandomDistanceAchievementMessage(value: String) -> String {
        let messages = [
            "Amazing! You've covered \(value) today, reaching your distance goal! 🏃‍♀️",
            "Incredible journey! \(value) completed! You're going the distance! 🌟",
            "What a trek! \(value) conquered today! Your endurance is remarkable! 💪",
            "Distance champion! \(value) achieved! Every mile matters! 🏆",
            "Fantastic coverage! \(value) in the books! Keep exploring! 🚀",
            "Journey complete! \(value) traveled today! Adventure awaits tomorrow! ⭐",
            "Distance goal smashed! \(value) covered! You're on a roll! 🎯"
        ]
        return messages.randomElement() ?? "Amazing! You've covered \(value) today, reaching your distance goal! 🏃‍♀️"
    }
    
    private func getRandomCaloriesAchievementMessage(value: String) -> String {
        let messages = [
            "Great job! You've burned \(value) calories, meeting your daily target! 🔥",
            "Calorie crusher! \(value) burned today! Your metabolism is on fire! 💪",
            "Energy expended! \(value) calories conquered! Feel that burn! ⚡",
            "Fantastic fuel usage! \(value) calories burned! You're a calorie-burning machine! 🚀",
            "Heat generated! \(value) calories eliminated today! Keep the fire burning! 🌟",
            "Calorie goal demolished! \(value) burned! Your dedication is incredible! 🏆",
            "Energy transformation complete! \(value) calories processed! Amazing work! ⭐"
        ]
        return messages.randomElement() ?? "Great job! You've burned \(value) calories, meeting your daily target! 🔥"
    }
    
    private func getRandomActiveMinutesAchievementMessage(value: String) -> String {
        let messages = [
            "Excellent! You've been active for \(value) minutes today! ⏱️",
            "Time well spent! \(value) minutes of activity completed! Every minute counts! 💪",
            "Active achievement unlocked! \(value) minutes in motion! Keep moving! 🚀",
            "Motion milestone! \(value) minutes of activity achieved! You're unstoppable! 🌟",
            "Activity goal conquered! \(value) minutes of movement! Time invested wisely! ⭐",
            "Movement mastery! \(value) minutes of activity completed! Stay in motion! 🏆",
            "Active time target hit! \(value) minutes achieved! Your body thanks you! 💎"
        ]
        return messages.randomElement() ?? "Excellent! You've been active for \(value) minutes today! ⏱️"
    }
    
    // MARK: - Overachiever Messages (150-200% of goal)
    private func getRandomStepsOverachieverMessage(current: String, target: String, percentage: Int) -> String {
        let messages = [
            "🚨 FIRE ALERT! You've burned through \(current) steps (\(percentage)% of \(target))! Call the fire department! 🧯🔥",
            "🔥 You're literally on fire! \(current) steps when you only needed \(target)! Someone get a fire extinguisher! 🧯",
            "🚨 EMERGENCY! You've exceeded your step goal by \(percentage-100)%! This is an overachievement emergency! 🧯🔥",
            "🔥 FIRE! FIRE! You've walked \(current) steps! That's \(percentage)% of your goal! Quick, someone call 911! 🧯",
            "🚨 ALERT! You've gone \(percentage-100)% over your \(target) step goal! You're burning up the track! 🔥🧯",
            "🔥 You're absolutely blazing! \(current) steps is \(percentage)% of your goal! Time to cool down! 🧯",
            "🚨 OVERACHIEVEMENT ALERT! You've crushed your step goal by \(percentage-100)%! You're too hot to handle! 🔥🧯",
            "🔥 FIRE EXTINGUISHER NEEDED! You've walked \(current) steps (\(percentage)%)! You're on fire! 🧯",
            "🚨 You've exceeded your step goal by \(percentage-100)%! This level of dedication is flammable! 🔥🧯",
            "🔥 EMERGENCY OVERACHIEVER! \(current) steps when you only needed \(target)! Someone get water! 🧯"
        ]
        return messages.randomElement() ?? "🚨 FIRE ALERT! You've burned through \(current) steps (\(percentage)% of \(target))! Call the fire department! 🧯🔥"
    }
    
    private func getRandomDistanceOverachieverMessage(current: String, target: String, percentage: Int) -> String {
        let messages = [
            "🚨 FIRE ALERT! You've traveled \(current) (\(percentage)% of \(target))! You're burning up the road! 🧯🔥",
            "🔥 You're literally on fire! \(current) distance when you only needed \(target)! Someone get a fire extinguisher! 🧯",
            "🚨 EMERGENCY! You've exceeded your distance goal by \(percentage-100)%! This is an overachievement emergency! 🧯🔥",
            "🔥 FIRE! FIRE! You've covered \(current)! That's \(percentage)% of your goal! Quick, someone call 911! 🧯",
            "🚨 ALERT! You've gone \(percentage-100)% over your \(target) distance goal! You're burning up the track! 🔥🧯",
            "🔥 You're absolutely blazing! \(current) is \(percentage)% of your goal! Time to cool down! 🧯",
            "🚨 OVERACHIEVEMENT ALERT! You've crushed your distance goal by \(percentage-100)%! You're too hot to handle! 🔥🧯",
            "🔥 FIRE EXTINGUISHER NEEDED! You've traveled \(current) (\(percentage)%)! You're on fire! 🧯",
            "🚨 You've exceeded your distance goal by \(percentage-100)%! This level of dedication is flammable! 🔥🧯",
            "🔥 EMERGENCY OVERACHIEVER! \(current) when you only needed \(target)! Someone get water! 🧯"
        ]
        return messages.randomElement() ?? "🚨 FIRE ALERT! You've traveled \(current) (\(percentage)% of \(target))! You're burning up the road! 🧯🔥"
    }
    
    private func getRandomCaloriesOverachieverMessage(current: String, target: String, percentage: Int) -> String {
        let messages = [
            "🚨 FIRE ALERT! You've burned \(current) calories (\(percentage)% of \(target))! You're literally on fire! 🧯🔥",
            "🔥 You're burning up! \(current) calories when you only needed \(target)! Someone get a fire extinguisher! 🧯",
            "🚨 EMERGENCY! You've exceeded your calorie goal by \(percentage-100)%! This is an overachievement emergency! 🧯🔥",
            "🔥 FIRE! FIRE! You've burned \(current) calories! That's \(percentage)% of your goal! Quick, someone call 911! 🧯",
            "🚨 ALERT! You've gone \(percentage-100)% over your \(target) calorie goal! You're burning up the gym! 🔥🧯",
            "🔥 You're absolutely blazing! \(current) calories is \(percentage)% of your goal! Time to cool down! 🧯",
            "🚨 OVERACHIEVEMENT ALERT! You've crushed your calorie goal by \(percentage-100)%! You're too hot to handle! 🔥🧯",
            "🔥 FIRE EXTINGUISHER NEEDED! You've burned \(current) calories (\(percentage)%)! You're on fire! 🧯",
            "🚨 You've exceeded your calorie goal by \(percentage-100)%! This level of dedication is flammable! 🔥🧯",
            "🔥 EMERGENCY OVERACHIEVER! \(current) calories when you only needed \(target)! Someone get water! 🧯"
        ]
        return messages.randomElement() ?? "🚨 FIRE ALERT! You've burned \(current) calories (\(percentage)% of \(target))! You're literally on fire! 🧯🔥"
    }
    
    private func getRandomActiveMinutesOverachieverMessage(current: String, target: String, percentage: Int) -> String {
        let messages = [
            "🚨 FIRE ALERT! You've been active for \(current) minutes (\(percentage)% of \(target))! You're burning up! 🧯🔥",
            "🔥 You're literally on fire! \(current) active minutes when you only needed \(target)! Someone get a fire extinguisher! 🧯",
            "🚨 EMERGENCY! You've exceeded your active time goal by \(percentage-100)%! This is an overachievement emergency! 🧯🔥",
            "🔥 FIRE! FIRE! You've been active for \(current) minutes! That's \(percentage)% of your goal! Quick, someone call 911! 🧯",
            "🚨 ALERT! You've gone \(percentage-100)% over your \(target) active time goal! You're burning up the clock! 🔥🧯",
            "🔥 You're absolutely blazing! \(current) active minutes is \(percentage)% of your goal! Time to cool down! 🧯",
            "🚨 OVERACHIEVEMENT ALERT! You've crushed your active time goal by \(percentage-100)%! You're too hot to handle! 🔥🧯",
            "🔥 FIRE EXTINGUISHER NEEDED! You've been active for \(current) minutes (\(percentage)%)! You're on fire! 🧯",
            "🚨 You've exceeded your active time goal by \(percentage-100)%! This level of dedication is flammable! 🔥🧯",
            "🔥 EMERGENCY OVERACHIEVER! \(current) active minutes when you only needed \(target)! Someone get water! 🧯"
        ]
        return messages.randomElement() ?? "🚨 FIRE ALERT! You've been active for \(current) minutes (\(percentage)% of \(target))! You're burning up! 🧯🔥"
    }
    
    private func getRandomReminderMessage() -> String {
        let messages = [
            "How are you doing with your daily step goal? Let's check your progress!",
            "Time for a quick activity check! How's your day going?",
            "Ready to take some steps? Your goals are waiting for you!",
            "Just a friendly reminder to keep moving! Every step counts!",
            "Your health journey continues! How are you feeling today?",
            "Step by step, you're getting closer to your goals!",
            "A little movement can make a big difference! Ready to get active?",
            "Your future self will thank you for staying active today!",
            "Progress check time! Let's see how you're doing!",
            "Remember: small steps lead to big achievements!"
        ]
        return messages.randomElement() ?? "How are you doing with your daily step goal? Let's check your progress!"
    }
    
    private func getRandomEncouragementMessage() -> String {
        let messages = [
            "You're doing great! Keep up the fantastic work! 🌟",
            "Every step counts! You're making progress! 💪",
            "Don't give up! You're closer than you think! 🎯",
            "Your dedication is inspiring! Keep pushing forward! 🚀",
            "Small steps, big results! You've got this! ⭐",
            "Progress isn't always perfect, but it's always worth it! 💎",
            "Your health journey is unique and valuable! Keep going! 🏆",
            "Believe in yourself! You're capable of amazing things! 🌟",
            "Every day is a new opportunity to move forward! 💪",
            "Your commitment to health is admirable! Stay strong! ⚡"
        ]
        return messages.randomElement() ?? "You're doing great! Keep up the fantastic work! 🌟"
    }
    
    private func getRandomWeeklyMessage() -> String {
        let messages = [
            "Your weekly fitness report is ready! See how you performed this week.",
            "Time to review your amazing week of progress! Check out your achievements!",
            "Weekly wrap-up is here! Discover what you accomplished this week!",
            "Seven days of dedication! Your weekly summary awaits!",
            "Week complete! Time to celebrate your progress and plan ahead!",
            "Your weekly health journey recap is ready! See how far you've come!",
            "Another week of progress in the books! Check out your accomplishments!"
        ]
        return messages.randomElement() ?? "Your weekly fitness report is ready! See how you performed this week."
    }
    
    private func getRandomGoalReminderTitle() -> String {
        let titles = [
            "⏰ Goal Check-in",
            "📊 Progress Update",
            "🎯 How's It Going?",
            "💪 Keep Pushing!",
            "🚶‍♂️ Step Check",
            "⚡ Quick Status",
            "🌟 Progress Report",
            "🔥 Stay on Track!",
            "📈 Goal Monitor",
            "💎 Almost There!"
        ]
        return titles.randomElement() ?? "⏰ Goal Check-in"
    }
    
    private func getRandomStepsReminderMessage(current: String, target: String, progress: Int, timeRemaining: String) -> String {
        let messages = [
            "You're at \(current) steps (\(progress)% of your \(target) goal). \(timeRemaining) left - you can do it! 💪",
            "Great progress! \(current) steps completed (\(progress)% there). \(timeRemaining) to reach your \(target) goal! 🚶‍♂️",
            "Keep moving! You've taken \(current) steps (\(progress)% done). \(timeRemaining) to hit \(target)! 🎯",
            "Awesome pace! \(current) steps logged (\(progress)% complete). \(timeRemaining) remaining for your \(target) target! ⚡",
            "You're crushing it! \(current) steps down (\(progress)% achieved). \(timeRemaining) left to reach \(target)! 🌟",
            "Step by step! \(current) completed (\(progress)% of \(target)). \(timeRemaining) to go - stay strong! 💎",
            "Making moves! \(current) steps in (\(progress)% there). \(timeRemaining) until you hit \(target)! 🚀",
            "Progress check: \(current) steps (\(progress)% of your \(target) goal). \(timeRemaining) left - finish strong! 🔥"
        ]
        return messages.randomElement() ?? "You're at \(current) steps (\(progress)% of your \(target) goal). \(timeRemaining) left - you can do it! 💪"
    }
    
    private func getRandomDistanceReminderMessage(current: String, target: String, progress: Int, timeRemaining: String) -> String {
        let messages = [
            "You've covered \(current) (\(progress)% of your \(target) goal). \(timeRemaining) to go! 🏃‍♀️",
            "Distance update! \(current) traveled (\(progress)% there). \(timeRemaining) left to reach \(target)! 🌟",
            "Great journey so far! \(current) completed (\(progress)% of \(target)). \(timeRemaining) remaining! 💪",
            "Keep exploring! \(current) covered (\(progress)% done). \(timeRemaining) until you hit \(target)! 🚀",
            "Miles matter! \(current) logged (\(progress)% achieved). \(timeRemaining) to reach your \(target) goal! ⚡",
            "Distance progress: \(current) (\(progress)% of \(target)). \(timeRemaining) left - keep going! 🎯",
            "On the move! \(current) completed (\(progress)% there). \(timeRemaining) to your \(target) target! 💎",
            "Journey check: \(current) traveled (\(progress)% of \(target)). \(timeRemaining) remaining - finish strong! 🔥"
        ]
        return messages.randomElement() ?? "You've covered \(current) (\(progress)% of your \(target) goal). \(timeRemaining) to go! 🏃‍♀️"
    }
    
    private func getRandomCaloriesReminderMessage(current: String, target: String, progress: Int, timeRemaining: String) -> String {
        let messages = [
            "You've burned \(current) calories (\(progress)% of your \(target) goal). Keep moving! 🔥",
            "Calorie update! \(current) burned (\(progress)% there). \(timeRemaining) to reach \(target)! 💪",
            "Heat check! \(current) calories down (\(progress)% of \(target)). \(timeRemaining) left! ⚡",
            "Energy expenditure: \(current) calories (\(progress)% complete). \(timeRemaining) to hit \(target)! 🌟",
            "Burn report! \(current) calories eliminated (\(progress)% achieved). \(timeRemaining) remaining! 🚀",
            "Calorie progress: \(current) burned (\(progress)% of \(target)). \(timeRemaining) left - keep the fire burning! 💎",
            "Metabolism check! \(current) calories processed (\(progress)% there). \(timeRemaining) to reach \(target)! 🎯",
            "Energy update: \(current) calories (\(progress)% of \(target)). \(timeRemaining) remaining - stay active! ⚡"
        ]
        return messages.randomElement() ?? "You've burned \(current) calories (\(progress)% of your \(target) goal). Keep moving! 🔥"
    }
    
    private func getRandomActiveMinutesReminderMessage(current: String, target: String, progress: Int, timeRemaining: String) -> String {
        let messages = [
            "You've been active for \(current) minutes (\(progress)% of your \(target) goal). \(timeRemaining) left! ⏱️",
            "Activity update! \(current) minutes logged (\(progress)% there). \(timeRemaining) to reach \(target)! 💪",
            "Time in motion: \(current) minutes (\(progress)% of \(target)). \(timeRemaining) remaining! 🚀",
            "Active time check! \(current) minutes completed (\(progress)% done). \(timeRemaining) to hit \(target)! ⚡",
            "Movement report! \(current) minutes active (\(progress)% achieved). \(timeRemaining) left! 🌟",
            "Activity progress: \(current) minutes (\(progress)% of \(target)). \(timeRemaining) to go - stay moving! 💎",
            "Motion update! \(current) minutes in (\(progress)% there). \(timeRemaining) until you reach \(target)! 🎯",
            "Active minutes check: \(current) logged (\(progress)% of \(target)). \(timeRemaining) remaining - keep it up! 🔥"
        ]
        return messages.randomElement() ?? "You've been active for \(current) minutes (\(progress)% of your \(target) goal). \(timeRemaining) left! ⏱️"
    }
}
