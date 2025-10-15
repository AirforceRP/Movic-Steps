//
//  HealthKitManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import HealthKit // Grab HealthKit from IPhone 
import SwiftUI // This is just 

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let goalTracker = GoalTracker.shared
    private let userSettings = UserSettings.shared
    // private let watchManager = WatchConnectivityManager.shared
    
    @Published var isAuthorized = false
    @Published var todaySteps = 0
    @Published var todayDistance = 0.0
    @Published var todayCalories = 0.0
    @Published var todayActiveMinutes = 0
    @Published var todayFloors = 0
    @Published var isLoading = false
    
    // Flag to prevent circular updates
    private var isRecalculating = false
    
    // Method to update goal progress
    private func updateGoalProgress() {
        goalTracker.updateStepProgress(todaySteps)
    }
    
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let activeMinutesType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    private let floorsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
    
    init() {
        NSLog("🏁 HealthKitManager init called")
        checkHealthKitAvailability()
    }
    
    private func checkHealthKitAvailability() {
        #if targetEnvironment(simulator)
        // Always use simulated data in simulator
        NSLog("Running in simulator - using simulated health data")
        simulateHealthData()
        return
        #endif
        
        guard HKHealthStore.isHealthDataAvailable() else {
            NSLog("HealthKit is not available on this device")
            return
        }
    }
    
    // func syncWithAppleWatch() {
    //     watchManager.sendDataToWatch(
    //         steps: todaySteps,
    //         goal: userSettings.dailyStepGoal,
    //         distance: todayDistance,
    //         calories: todayCalories,
    //         activeMinutes: todayActiveMinutes
    //     )
    // }
    
    #if targetEnvironment(simulator)
    private func simulateHealthData() {
        // Simulate some health data for the simulator
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthorized = true
            self.todaySteps = 7543
            self.todayDistance = 5420.0 // meters
            self.todayFloors = 12 // floors climbed
            self.isLoading = false
            
            // Calculate calories and active minutes using the calculation methods
            if self.userSettings.useCalculatedMetrics {
                self.recalculateDerivedMetrics()
            } else {
                // Fallback to hardcoded values if calculations are disabled
                self.todayCalories = 287.5
                self.todayActiveMinutes = 45
            }
            
            // Update goal progress after setting data
            self.updateGoalProgress()
        }
    }
    #endif
    
    // MARK: - Calculated Metrics
    
    /// Recalculate calories and active minutes based on steps and distance
    private func recalculateDerivedMetrics() {
        // Prevent circular updates
        guard !isRecalculating else { 
            NSLog("⚠️ Skipping recalculation - already in progress")
            return 
        }
        isRecalculating = true
        
        NSLog("🔄 Starting recalculation with - Steps: \(todaySteps), Distance: \(todayDistance)m, Weight: \(userSettings.userWeight)kg, Speed: \(userSettings.walkingSpeed)m/s, StepLength: \(userSettings.stepLength)m")
        
        do {
            // Calculate calories based on walking data
            todayCalories = userSettings.calculateCaloriesBurned(steps: todaySteps, distance: todayDistance)
            
            // Calculate active minutes based on walking data
            todayActiveMinutes = userSettings.calculateActiveMinutes(steps: todaySteps, distance: todayDistance)
            
            // If no distance from HealthKit, calculate it from steps
            if todayDistance == 0 {
                todayDistance = userSettings.calculateDistanceFromSteps(todaySteps)
            }
            
            NSLog("✅ Recalculated metrics - Steps: \(todaySteps), Distance: \(todayDistance)m, Calories: \(todayCalories), Active: \(todayActiveMinutes)min")
        } catch {
            print("❌ Error recalculating metrics: \(error)")
            // Set safe default values
            todayCalories = 0.0
            todayActiveMinutes = 0
        }
        
        // Reset flag
        isRecalculating = false
    }
    
    func requestAuthorization() {
        #if targetEnvironment(simulator)
        // On simulator, just simulate authorization
        print("Simulating HealthKit authorization for simulator")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.simulateHealthData()
        }
        return
        #endif
        
        let typesToRead: Set<HKObjectType> = [
            stepType,
            distanceType,
            activeEnergyType,
            activeMinutesType,
            floorsType
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isAuthorized = success
                if success {
                    print("✅ HealthKit authorization successful")
                    // Add a small delay to ensure the authorization is fully processed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.fetchTodayData()
                    }
                } else if let error = error {
                    print("❌ HealthKit authorization failed: \(error.localizedDescription)")
                } else {
                    print("⚠️ HealthKit authorization was denied by user")
                }
            }
        }
    }
    
    func fetchTodayData() {
        guard isAuthorized else { 
            print("⚠️ fetchTodayData called but not authorized")
            return 
        }
        
        print("🔄 Starting to fetch HealthKit data...")
        
        #if targetEnvironment(simulator)
        // On simulator, just update with mock data
        simulateHealthData()
        return
        #endif
        
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let group = DispatchGroup()
        
        // Fetch steps
        group.enter()
        let stepsQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("❌ Error fetching steps: \(error.localizedDescription)")
            } else if let result = result, let sum = result.sumQuantity() {
                DispatchQueue.main.async {
                    // round to nearest integer
                    self?.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
                    print("📊 Fetched steps: \(self?.todaySteps ?? 0)")
                }
            }
            group.leave()
        }
        healthStore.execute(stepsQuery)
        
        // Fetch distance
        group.enter()
        let distanceQuery = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("❌ Error fetching distance: \(error.localizedDescription)")
            } else if let result = result, let sum = result.sumQuantity() {
                DispatchQueue.main.async {
                    // round to nearest integer
                    self?.todayDistance = sum.doubleValue(for: HKUnit.meter())
                    print("📊 Fetched distance: \(self?.todayDistance ?? 0)m")
                }
            }
            group.leave()
        }
        healthStore.execute(distanceQuery)
        
        // Fetch calories
        group.enter()
        let caloriesQuery = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("❌ Error fetching calories: \(error.localizedDescription)")
            } else if let result = result, let sum = result.sumQuantity() {
                DispatchQueue.main.async {
                    // round to nearest integer
                    self?.todayCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                    print("📊 Fetched calories: \(self?.todayCalories ?? 0) kcal")
                }
            }
            group.leave()
        }
        healthStore.execute(caloriesQuery)
        
        // Fetch active minutes
        group.enter()
        let activeMinutesQuery = HKStatisticsQuery(quantityType: activeMinutesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("❌ Error fetching active minutes: \(error.localizedDescription)")
            } else if let result = result, let sum = result.sumQuantity() {
                DispatchQueue.main.async {
                    // round to nearest integer
                    self?.todayActiveMinutes = Int(sum.doubleValue(for: HKUnit.minute()))
                    print("📊 Fetched active minutes: \(self?.todayActiveMinutes ?? 0) min")
                }
            }
            group.leave()
        }
        healthStore.execute(activeMinutesQuery)
        
        // Fetch floors climbed
        group.enter()
        let floorsQuery = HKStatisticsQuery(quantityType: floorsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("❌ Error fetching floors: \(error.localizedDescription)")
            } else if let result = result, let sum = result.sumQuantity() {
                DispatchQueue.main.async {
                    // round to nearest integer
                    self?.todayFloors = Int(sum.doubleValue(for: HKUnit.count()))
                    print("📊 Fetched floors: \(self?.todayFloors ?? 0) floors")
                }
            }
            group.leave()
        }
        healthStore.execute(floorsQuery)
        
        group.notify(queue: .main) {
            self.isLoading = false
            
            // If using calculated metrics, recalculate calories and active minutes
            if self.userSettings.useCalculatedMetrics {
                self.recalculateDerivedMetrics()
            }
            
            // Update goal tracker with all health data
            self.updateGoalTracking()
            
            // Update goal progress after all data is loaded
            self.updateGoalProgress()
        }
    }
    
    func fetchStepsForDateRange(startDate: Date, endDate: Date, completion: @escaping ([HKQuantitySample]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let samples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    completion(samples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchWeeklySteps(completion: @escaping ([Int]) -> Void) {
        #if targetEnvironment(simulator)
        // On simulator, return mock weekly data
        let mockWeeklySteps = [6200, 8100, 7543, 9200, 6800, 10500, 7900]
        DispatchQueue.main.async {
            completion(mockWeeklySteps)
        }
        return
        #endif
        
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        fetchStepsForDateRange(startDate: weekAgo, endDate: today) { samples in
            var dailySteps: [Int] = Array(repeating: 0, count: 7)
            
            for sample in samples {
                guard let weekday = calendar.dateComponents([.weekday], from: sample.startDate).weekday,
                      weekday >= 1 && weekday <= 7 else {
                    print("⚠️ Invalid weekday for sample: \(sample.startDate)")
                    continue
                }
                let dayIndex = weekday - 1
                let steps = Int(sample.quantity.doubleValue(for: HKUnit.count()))
                dailySteps[dayIndex] += steps
            }
            
            completion(dailySteps)
        }
    }
    
    // Goal Tracking Integration
    private func updateGoalTracking() {
        // This method is called whenever health data is updated
        // If this runs, I’m taking full credit; if not, it was cache’s fault.
        // The goal tracker will be notified through the published properties
        print("📊 Health data updated - Steps: \(todaySteps), Distance: \(todayDistance)m, Calories: \(todayCalories), Active: \(todayActiveMinutes)min")
    }
    
    func updateGoalsWithHealthData(_ goals: [HealthGoal]) {
        let healthData = (
            steps: todaySteps,
            distance: todayDistance,
            calories: todayCalories,
            activeMinutes: todayActiveMinutes
        )
        
        goalTracker.updateGoalProgress(goals, healthData: healthData)
    }
}
