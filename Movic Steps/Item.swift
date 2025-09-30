//
//  Item.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import SwiftData
import HealthKit

@Model
final class StepData {
    var date: Date
    var steps: Int
    var distance: Double // in meters
    var calories: Double
    var activeMinutes: Int
    
    init(date: Date, steps: Int = 0, distance: Double = 0, calories: Double = 0, activeMinutes: Int = 0) {
        self.date = date
        self.steps = steps
        self.distance = distance
        self.calories = calories
        self.activeMinutes = activeMinutes
    }
}

@Model
final class HealthGoal: Identifiable {
    var id: UUID
    var type: GoalType
    var targetValue: Double
    var currentValue: Double
    var isActive: Bool
    var createdDate: Date
    var customColor: String? // Store color as hex string for premium users
    var customIcon: String? // Store custom icon name for premium users
    
    enum GoalType: String, CaseIterable, Codable {
        case steps = "steps"
        case distance = "distance"
        case calories = "calories"
        case activeMinutes = "activeMinutes"
    }
    
    init(type: GoalType, targetValue: Double, currentValue: Double = 0, isActive: Bool = true) {
        self.id = UUID()
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.isActive = isActive
        self.createdDate = Date()
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
}

@Model
final class HealthInsight {
    var id: UUID
    var title: String
    var insightDescription: String
    var category: InsightCategory
    var date: Date
    var isRead: Bool
    
    enum InsightCategory: String, CaseIterable, Codable {
        case achievement = "achievement"
        case improvement = "improvement"
        case trend = "trend"
        case goal = "goal"
        case health = "health"
    }
    
    init(title: String, description: String, category: InsightCategory) {
        self.id = UUID()
        self.title = title
        self.insightDescription = description
        self.category = category
        self.date = Date()
        self.isRead = false
    }
}
