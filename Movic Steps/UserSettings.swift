//
//  UserSettings.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import SwiftUI

// MARK: - Unit System Enums
enum UnitSystem: String, CaseIterable, Identifiable {
    case metric = "metric"
    case imperial = "imperial"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "miles"
        }
    }
    
    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }
    
    var heightUnit: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "ft/in"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum GoalReminderTime: String, CaseIterable, Identifiable {
    case morning = "08:00"
    case noon = "12:00"
    case afternoon = "16:00"
    case evening = "20:00"
    case off = "off"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .morning: return "Morning (8:00 AM)"
        case .noon: return "Noon (12:00 PM)"
        case .afternoon: return "Afternoon (4:00 PM)"
        case .evening: return "Evening (8:00 PM)"
        case .off: return "Off"
        }
    }
}

enum StepSensitivity: String, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Less sensitive - fewer false positives"
        case .medium: return "Balanced sensitivity"
        case .high: return "More sensitive - detects subtle movements"
        }
    }
}

enum StepTrackingSource: String, CaseIterable, Identifiable {
    case healthKit = "healthkit"
    case accelerometer = "accelerometer"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .healthKit: return "HealthKit"
        case .accelerometer: return "Accelerometer"
        }
    }
    
    var description: String {
        switch self {
        case .healthKit: return "Uses Apple's HealthKit for accurate step counting"
        case .accelerometer: return "Real-time step detection using device sensors"
        }
    }
}

enum FloorSensitivity: String, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Only detects significant elevation changes"
        case .medium: return "Balanced floor detection sensitivity"
        case .high: return "Detects subtle elevation changes"
        }
    }
    
    var threshold: Double {
        switch self {
        case .low: return 2.5
        case .medium: return 2.0
        case .high: return 1.5
        }
    }
}

enum AccessibilityTextSize: String, CaseIterable, Identifiable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
}

enum ColorBlindnessType: String, CaseIterable, Identifiable {
    case none = "none"
    case protanopia = "protanopia"
    case deuteranopia = "deuteranopia"
    case tritanopia = "tritanopia"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .protanopia: return "Protanopia (Red-blind)"
        case .deuteranopia: return "Deuteranopia (Green-blind)"
        case .tritanopia: return "Tritanopia (Blue-blind)"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No color vision adjustments"
        case .protanopia: return "Difficulty distinguishing red and green colors"
        case .deuteranopia: return "Difficulty distinguishing red and green colors"
        case .tritanopia: return "Difficulty distinguishing blue and yellow colors"
        }
    }
}

// MARK: - User Settings Manager
class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var unitSystem: UnitSystem {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: "unitSystem")
        }
    }
    
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme")
        }
    }
    
    @Published var dailyStepGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyStepGoal, forKey: "dailyStepGoal")
        }
    }
    
    @Published var dailyStairsGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyStairsGoal, forKey: "dailyStairsGoal")
        }
    }
    
    @Published var dailySleepGoal: Int {
        didSet {
            UserDefaults.standard.set(dailySleepGoal, forKey: "dailySleepGoal")
        }
    }
    
    @Published var dailyCalorieGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyCalorieGoal, forKey: "dailyCalorieGoal")
        }
    }
    
    @Published var enableNotifications: Bool {
        didSet {
            UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
        }
    }
    
    @Published var goalReminderTime: GoalReminderTime {
        didSet {
            UserDefaults.standard.set(goalReminderTime.rawValue, forKey: "goalReminderTime")
        }
    }
    
    @Published var showWeeklyReport: Bool {
        didSet {
            UserDefaults.standard.set(showWeeklyReport, forKey: "showWeeklyReport")
        }
    }
    
    @Published var enableHapticFeedback: Bool {
        didSet {
            UserDefaults.standard.set(enableHapticFeedback, forKey: "enableHapticFeedback")
        }
    }
    
    @Published var enableSounds: Bool {
        didSet {
            UserDefaults.standard.set(enableSounds, forKey: "enableSounds")
        }
    }
    
    @Published var privacyMode: Bool {
        didSet {
            UserDefaults.standard.set(privacyMode, forKey: "privacyMode")
        }
    }
    
    @Published var stepSensitivity: StepSensitivity {
        didSet {
            UserDefaults.standard.set(stepSensitivity.rawValue, forKey: "stepSensitivity")
        }
    }
    
    @Published var preferredStepSource: StepTrackingSource {
        didSet {
            UserDefaults.standard.set(preferredStepSource.rawValue, forKey: "preferredStepSource")
        }
    }
    
    @Published var userWeight: Double {
        didSet {
            UserDefaults.standard.set(userWeight, forKey: "userWeight")
        }
    }
    
    @Published var userHeight: Double {
        didSet {
            UserDefaults.standard.set(userHeight, forKey: "userHeight")
        }
    }
    
    @Published var stepCalibrationFactor: Double {
        didSet {
            UserDefaults.standard.set(stepCalibrationFactor, forKey: "stepCalibrationFactor")
        }
    }
    
    @Published var walkingSpeed: Double {
        didSet {
            UserDefaults.standard.set(walkingSpeed, forKey: "walkingSpeed")
        }
    }
    
    @Published var stepLength: Double {
        didSet {
            UserDefaults.standard.set(stepLength, forKey: "stepLength")
        }
    }
    
    @Published var useCalculatedMetrics: Bool {
        didSet {
            UserDefaults.standard.set(useCalculatedMetrics, forKey: "useCalculatedMetrics")
        }
    }
    
    // MARK: - Floor Tracking Settings
    @Published var enableFloorTracking: Bool {
        didSet {
            UserDefaults.standard.set(enableFloorTracking, forKey: "enableFloorTracking")
        }
    }
    
    @Published var floorHeight: Double {
        didSet {
            UserDefaults.standard.set(floorHeight, forKey: "floorHeight")
        }
    }
    
    @Published var floorSensitivity: FloorSensitivity {
        didSet {
            UserDefaults.standard.set(floorSensitivity.rawValue, forKey: "floorSensitivity")
        }
    }
    
    // MARK: - Accessibility Settings
    @Published var enableVoiceOver: Bool {
        didSet {
            UserDefaults.standard.set(enableVoiceOver, forKey: "enableVoiceOver")
        }
    }
    
    @Published var enableReduceMotion: Bool {
        didSet {
            UserDefaults.standard.set(enableReduceMotion, forKey: "enableReduceMotion")
        }
    }
    
    @Published var enableHighContrast: Bool {
        didSet {
            UserDefaults.standard.set(enableHighContrast, forKey: "enableHighContrast")
        }
    }
    
    @Published var textSize: AccessibilityTextSize {
        didSet {
            UserDefaults.standard.set(textSize.rawValue, forKey: "textSize")
        }
    }
    
    @Published var enableLargeText: Bool {
        didSet {
            UserDefaults.standard.set(enableLargeText, forKey: "enableLargeText")
        }
    }
    
    @Published var enableBoldText: Bool {
        didSet {
            UserDefaults.standard.set(enableBoldText, forKey: "enableBoldText")
        }
    }
    
    @Published var colorBlindnessType: ColorBlindnessType {
        didSet {
            UserDefaults.standard.set(colorBlindnessType.rawValue, forKey: "colorBlindnessType")
        }
    }
    
    // MARK: - Motor Accessibility
    @Published var enableSwitchControl: Bool {
        didSet {
            UserDefaults.standard.set(enableSwitchControl, forKey: "enableSwitchControl")
        }
    }
    
    @Published var enableVoiceControl: Bool {
        didSet {
            UserDefaults.standard.set(enableVoiceControl, forKey: "enableVoiceControl")
        }
    }
    
    @Published var enableAssistiveTouch: Bool {
        didSet {
            UserDefaults.standard.set(enableAssistiveTouch, forKey: "enableAssistiveTouch")
        }
    }
    
    @Published var enableTouchAccommodations: Bool {
        didSet {
            UserDefaults.standard.set(enableTouchAccommodations, forKey: "enableTouchAccommodations")
        }
    }
    
    // MARK: - Cognitive Accessibility
    @Published var enableGuidedAccess: Bool {
        didSet {
            UserDefaults.standard.set(enableGuidedAccess, forKey: "enableGuidedAccess")
        }
    }
    
    @Published var enableTimeLimit: Bool {
        didSet {
            UserDefaults.standard.set(enableTimeLimit, forKey: "enableTimeLimit")
        }
    }
    
    @Published var enableSimpleInterface: Bool {
        didSet {
            UserDefaults.standard.set(enableSimpleInterface, forKey: "enableSimpleInterface")
        }
    }
    
    @Published var enableClearInstructions: Bool {
        didSet {
            UserDefaults.standard.set(enableClearInstructions, forKey: "enableClearInstructions")
        }
    }
    
    private init() {
        // Load saved settings or set defaults
        let unitSystemString = UserDefaults.standard.string(forKey: "unitSystem") ?? UnitSystem.metric.rawValue
        self.unitSystem = UnitSystem(rawValue: unitSystemString) ?? .metric
        
        let appThemeString = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        self.appTheme = AppTheme(rawValue: appThemeString) ?? .system
        
        self.dailyStepGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal") == 0 ? 10000 : UserDefaults.standard.integer(forKey: "dailyStepGoal")
        
        self.dailyStairsGoal = UserDefaults.standard.integer(forKey: "dailyStairsGoal") == 0 ? 10 : UserDefaults.standard.integer(forKey: "dailyStairsGoal")
        self.dailySleepGoal = UserDefaults.standard.integer(forKey: "dailySleepGoal") == 0 ? 8 : UserDefaults.standard.integer(forKey: "dailySleepGoal")
        self.dailyCalorieGoal = UserDefaults.standard.integer(forKey: "dailyCalorieGoal") == 0 ? 2000 : UserDefaults.standard.integer(forKey: "dailyCalorieGoal")
        
        self.enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
        
        let goalReminderString = UserDefaults.standard.string(forKey: "goalReminderTime") ?? GoalReminderTime.evening.rawValue
        self.goalReminderTime = GoalReminderTime(rawValue: goalReminderString) ?? .evening
        
        self.showWeeklyReport = UserDefaults.standard.object(forKey: "showWeeklyReport") == nil ? true : UserDefaults.standard.bool(forKey: "showWeeklyReport")
        
        self.enableHapticFeedback = UserDefaults.standard.object(forKey: "enableHapticFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "enableHapticFeedback")
        
        self.enableSounds = UserDefaults.standard.object(forKey: "enableSounds") == nil ? true : UserDefaults.standard.bool(forKey: "enableSounds")
        
        self.privacyMode = UserDefaults.standard.bool(forKey: "privacyMode")
        
        let stepSensitivityString = UserDefaults.standard.string(forKey: "stepSensitivity") ?? StepSensitivity.medium.rawValue
        self.stepSensitivity = StepSensitivity(rawValue: stepSensitivityString) ?? .medium
        
        let stepSourceString = UserDefaults.standard.string(forKey: "preferredStepSource") ?? StepTrackingSource.healthKit.rawValue
        self.preferredStepSource = StepTrackingSource(rawValue: stepSourceString) ?? .healthKit
        
        self.userWeight = UserDefaults.standard.object(forKey: "userWeight") as? Double ?? 70.0 // Default to 70kg
        self.userHeight = UserDefaults.standard.object(forKey: "userHeight") as? Double ?? 175.0 // Default to 175cm
        self.stepCalibrationFactor = UserDefaults.standard.object(forKey: "stepCalibrationFactor") as? Double ?? 1.0
        
        // Initialize walking-related settings
        self.walkingSpeed = UserDefaults.standard.object(forKey: "walkingSpeed") as? Double ?? 1.4 // Default to 1.4 m/s (5 km/h)
        self.stepLength = UserDefaults.standard.object(forKey: "stepLength") as? Double ?? 0.7 // Default to 0.7m (70cm)
        self.useCalculatedMetrics = UserDefaults.standard.object(forKey: "useCalculatedMetrics") as? Bool ?? true
        
        // Initialize floor tracking settings
        self.enableFloorTracking = UserDefaults.standard.object(forKey: "enableFloorTracking") as? Bool ?? false
        self.floorHeight = UserDefaults.standard.object(forKey: "floorHeight") as? Double ?? 3.0 // Default to 3 meters
        let floorSensitivityString = UserDefaults.standard.string(forKey: "floorSensitivity") ?? FloorSensitivity.medium.rawValue
        self.floorSensitivity = FloorSensitivity(rawValue: floorSensitivityString) ?? .medium
        
        // Initialize accessibility settings
        self.enableVoiceOver = UserDefaults.standard.bool(forKey: "enableVoiceOver")
        self.enableReduceMotion = UserDefaults.standard.bool(forKey: "enableReduceMotion")
        self.enableHighContrast = UserDefaults.standard.bool(forKey: "enableHighContrast")
        self.enableLargeText = UserDefaults.standard.bool(forKey: "enableLargeText")
        self.enableBoldText = UserDefaults.standard.bool(forKey: "enableBoldText")
        
        let textSizeString = UserDefaults.standard.string(forKey: "textSize") ?? AccessibilityTextSize.medium.rawValue
        self.textSize = AccessibilityTextSize(rawValue: textSizeString) ?? .medium
        
        let colorBlindnessString = UserDefaults.standard.string(forKey: "colorBlindnessType") ?? ColorBlindnessType.none.rawValue
        self.colorBlindnessType = ColorBlindnessType(rawValue: colorBlindnessString) ?? .none
        
        // Motor Accessibility
        self.enableSwitchControl = UserDefaults.standard.bool(forKey: "enableSwitchControl")
        self.enableVoiceControl = UserDefaults.standard.bool(forKey: "enableVoiceControl")
        self.enableAssistiveTouch = UserDefaults.standard.bool(forKey: "enableAssistiveTouch")
        self.enableTouchAccommodations = UserDefaults.standard.bool(forKey: "enableTouchAccommodations")
        
        // Cognitive Accessibility
        self.enableGuidedAccess = UserDefaults.standard.bool(forKey: "enableGuidedAccess")
        self.enableTimeLimit = UserDefaults.standard.bool(forKey: "enableTimeLimit")
        self.enableSimpleInterface = UserDefaults.standard.bool(forKey: "enableSimpleInterface")
        self.enableClearInstructions = UserDefaults.standard.bool(forKey: "enableClearInstructions")
    }
    
    // MARK: - Unit Conversion Methods
    func formatDistance(_ meters: Double) -> String {
        switch unitSystem {
        case .metric:
            if meters < 1000 {
                return String(format: "%.0f m", meters)
            } else {
                return String(format: "%.1f km", meters / 1000)
            }
        case .imperial:
            let miles = meters * 0.000621371
            if miles < 0.1 {
                let feet = meters * 3.28084
                return String(format: "%.0f ft", feet)
            } else {
                return String(format: "%.1f mi", miles)
            }
        }
    }
    
    func formatWeight(_ kg: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f kg", kg)
        case .imperial:
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
    }
    
    func formatHeight(_ cm: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.0f cm", cm)
        case .imperial:
            let totalInches = cm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)' \(inches)\""
        }
    }
    
    func formatUserWeight() -> String {
        return formatWeight(userWeight)
    }
    
    func formatUserHeight() -> String {
        return formatHeight(userHeight)
    }
    
    func formatSpeed(_ metersPerSecond: Double) -> String {
        switch unitSystem {
        case .metric:
            let kmPerHour = metersPerSecond * 3.6
            return String(format: "%.1f km/h", kmPerHour)
        case .imperial:
            let milesPerHour = metersPerSecond * 2.237
            return String(format: "%.1f mph", milesPerHour)
        }
    }
    
    // MARK: - Walking Calculations
    
    /// Calculate calories burned based on steps, distance, and user metrics
    func calculateCaloriesBurned(steps: Int, distance: Double) -> Double {
        // Safety check for zero values
        guard walkingSpeed > 0, stepLength > 0, userWeight > 0 else {
            print("⚠️ Invalid calculation parameters - walkingSpeed: \(walkingSpeed), stepLength: \(stepLength), userWeight: \(userWeight)")
            return 0.0
        }
        
        // Use distance if available, otherwise calculate from steps and step length
        let actualDistance = distance > 0 ? distance : Double(steps) * stepLength
        
        // Calculate walking time in hours
        let walkingTimeHours = actualDistance / (walkingSpeed * 3600) // Convert m/s to m/h
        
        // Calculate calories using MET (Metabolic Equivalent of Task) for walking
        // MET for walking at 5 km/h (1.4 m/s) is approximately 3.5
        let metValue = 3.5
        
        // Calories = MET × weight(kg) × time(hours)
        let calories = metValue * userWeight * walkingTimeHours
        
        return max(0, calories)
    }
    
    /// Calculate active minutes based on walking speed and distance
    func calculateActiveMinutes(steps: Int, distance: Double) -> Int {
        // Safety check for zero values
        guard walkingSpeed > 0, stepLength > 0 else {
            print("⚠️ Invalid calculation parameters - walkingSpeed: \(walkingSpeed), stepLength: \(stepLength)")
            return 0
        }
        
        // Use distance if available, otherwise calculate from steps and step length
        let actualDistance = distance > 0 ? distance : Double(steps) * stepLength
        
        // Calculate walking time in minutes
        let walkingTimeMinutes = actualDistance / (walkingSpeed * 60) // Convert m/s to m/min
        
        // Only count as active if walking at a reasonable pace (faster than 1 m/s)
        if walkingSpeed >= 1.0 {
            return Int(walkingTimeMinutes)
        } else {
            // For very slow walking, count only 50% of time as active
            return Int(walkingTimeMinutes * 0.5)
        }
    }
    
    /// Calculate distance from steps using step length
    func calculateDistanceFromSteps(_ steps: Int) -> Double {
        return Double(steps) * stepLength
    }
    
    /// Calculate steps from distance using step length
    func calculateStepsFromDistance(_ distance: Double) -> Int {
        guard stepLength > 0 else {
            print("⚠️ Invalid stepLength for calculation: \(stepLength)")
            return 0
        }
        return Int(distance / stepLength)
    }
    
    /// Get estimated walking speed based on user height and age
    func getEstimatedWalkingSpeed() -> Double {
        // Basic estimation based on height
        // Taller people generally walk faster
        let heightFactor = userHeight / 175.0 // Normalize to average height
        let baseSpeed = 1.4 // 5 km/h in m/s
        return baseSpeed * heightFactor
    }
    
    /// Get estimated step length based on user height
    func getEstimatedStepLength() -> Double {
        // Step length is approximately 0.4 times height
        return userHeight * 0.4 / 100.0 // Convert cm to meters
    }
    
    /// Auto-calculate walking parameters based on user metrics
    func autoCalculateWalkingParameters() {
        walkingSpeed = getEstimatedWalkingSpeed()
        stepLength = getEstimatedStepLength()
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        unitSystem = .metric
        appTheme = .system
        dailyStepGoal = 10000
        dailyStairsGoal = 10
        dailySleepGoal = 8
        dailyCalorieGoal = 2000
        enableNotifications = true
        goalReminderTime = .evening
        showWeeklyReport = true
        enableHapticFeedback = true
        enableSounds = true
        privacyMode = false
        stepSensitivity = .medium
        preferredStepSource = .healthKit
        userWeight = unitSystem == .metric ? 70.0 : 154.0
        userHeight = unitSystem == .metric ? 175.0 : 69.0
        stepCalibrationFactor = 1.0
        walkingSpeed = 1.4
        stepLength = 0.7
        useCalculatedMetrics = true
        
        // Reset floor tracking settings
        enableFloorTracking = false
        floorHeight = 3.0
        floorSensitivity = .medium
        
        // Reset accessibility settings
        enableVoiceOver = false
        enableReduceMotion = false
        enableHighContrast = false
        enableLargeText = false
        enableBoldText = false
        textSize = .medium
        colorBlindnessType = .none
        
        // Motor Accessibility
        enableSwitchControl = false
        enableVoiceControl = false
        enableAssistiveTouch = false
        enableTouchAccommodations = false
        
        // Cognitive Accessibility
        enableGuidedAccess = false
        enableTimeLimit = false
        enableSimpleInterface = false
        enableClearInstructions = true
    }
    
}

// Having autism means I should have to give Accessiblity settings a full page of code