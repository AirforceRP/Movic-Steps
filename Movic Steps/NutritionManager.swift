//
//  NutritionManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import HealthKit
import Combine
import SwiftUI

class NutritionManager: ObservableObject {
    static let shared = NutritionManager()
    
    @Published var todayNutrition: NutritionData = NutritionData(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        vitamins: [:],
        minerals: [:]
    )
    @Published var todayMeals: [MealItem] = []
    @Published var isLoading = false
    @Published var isAuthorized = false
    
    private let healthStore = HKHealthStore()
    
    private init() {
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available")
            return
        }
        
        let nutritionTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!
        ]
        
        var allAuthorized = true
        for type in nutritionTypes {
            let status = healthStore.authorizationStatus(for: type)
            if status != .sharingAuthorized {
                allAuthorized = false
                break
            }
        }
        
        isAuthorized = allAuthorized
        
        if isAuthorized {
            fetchNutritionData()
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let nutritionTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: nutritionTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchNutritionData()
                } else {
                    print("❌ Nutrition authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    func fetchNutritionData() {
        guard isAuthorized else { return }
        
        isLoading = true
        
        // Fetch today's nutrition data
        fetchTodayNutritionData()
        
        // Generate sample meals for demonstration
        generateSampleMeals()
        
        isLoading = false
    }
    
    private func fetchTodayNutritionData() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Fetch calories
        fetchNutritionValue(for: .dietaryEnergyConsumed, predicate: predicate) { [weak self] calories in
            DispatchQueue.main.async {
                self?.todayNutrition = NutritionData(
                    calories: Int(calories),
                    protein: self?.todayNutrition.protein ?? 0,
                    carbs: self?.todayNutrition.carbs ?? 0,
                    fat: self?.todayNutrition.fat ?? 0,
                    fiber: self?.todayNutrition.fiber ?? 0,
                    vitamins: self?.todayNutrition.vitamins ?? [:],
                    minerals: self?.todayNutrition.minerals ?? [:]
                )
            }
        }
        
        // Fetch protein
        fetchNutritionValue(for: .dietaryProtein, predicate: predicate) { [weak self] protein in
            DispatchQueue.main.async {
                self?.todayNutrition = NutritionData(
                    calories: self?.todayNutrition.calories ?? 0,
                    protein: protein,
                    carbs: self?.todayNutrition.carbs ?? 0,
                    fat: self?.todayNutrition.fat ?? 0,
                    fiber: self?.todayNutrition.fiber ?? 0,
                    vitamins: self?.todayNutrition.vitamins ?? [:],
                    minerals: self?.todayNutrition.minerals ?? [:]
                )
            }
        }
        
        // Fetch carbs
        fetchNutritionValue(for: .dietaryCarbohydrates, predicate: predicate) { [weak self] carbs in
            DispatchQueue.main.async {
                self?.todayNutrition = NutritionData(
                    calories: self?.todayNutrition.calories ?? 0,
                    protein: self?.todayNutrition.protein ?? 0,
                    carbs: carbs,
                    fat: self?.todayNutrition.fat ?? 0,
                    fiber: self?.todayNutrition.fiber ?? 0,
                    vitamins: self?.todayNutrition.vitamins ?? [:],
                    minerals: self?.todayNutrition.minerals ?? [:]
                )
            }
        }
        
        // Fetch fat
        fetchNutritionValue(for: .dietaryFatTotal, predicate: predicate) { [weak self] fat in
            DispatchQueue.main.async {
                self?.todayNutrition = NutritionData(
                    calories: self?.todayNutrition.calories ?? 0,
                    protein: self?.todayNutrition.protein ?? 0,
                    carbs: self?.todayNutrition.carbs ?? 0,
                    fat: fat,
                    fiber: self?.todayNutrition.fiber ?? 0,
                    vitamins: self?.todayNutrition.vitamins ?? [:],
                    minerals: self?.todayNutrition.minerals ?? [:]
                )
            }
        }
        
        // Fetch fiber
        fetchNutritionValue(for: .dietaryFiber, predicate: predicate) { [weak self] fiber in
            DispatchQueue.main.async {
                self?.todayNutrition = NutritionData(
                    calories: self?.todayNutrition.calories ?? 0,
                    protein: self?.todayNutrition.protein ?? 0,
                    carbs: self?.todayNutrition.carbs ?? 0,
                    fat: self?.todayNutrition.fat ?? 0,
                    fiber: fiber,
                    vitamins: self?.todayNutrition.vitamins ?? [:],
                    minerals: self?.todayNutrition.minerals ?? [:]
                )
            }
        }
        
        // Generate sample vitamins and minerals
        generateSampleVitaminsAndMinerals()
    }
    
    private func fetchNutritionValue(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }
        
        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let samples = samples as? [HKQuantitySample] {
                let total = samples.reduce(0.0) { total, sample in
                    total + sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                }
                completion(total)
            } else {
                completion(0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func generateSampleMeals() {
        let calendar = Calendar.current
        let now = Date()
        
        todayMeals = [
            MealItem(
                name: "Breakfast",
                calories: 350,
                time: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
                icon: "sunrise",
                color: Color.orange
            ),
            MealItem(
                name: "Lunch",
                calories: 550,
                time: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now) ?? now,
                icon: "sun.max",
                color: Color.yellow
            ),
            MealItem(
                name: "Dinner",
                calories: 650,
                time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now,
                icon: "moon",
                color: Color.blue
            ),
            MealItem(
                name: "Snack",
                calories: 200,
                time: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: now) ?? now,
                icon: "heart",
                color: Color.red
            )
        ]
    }
    
    private func generateSampleVitaminsAndMinerals() {
        let vitamins = [
            "Vitamin C": 85.0,
            "Vitamin D": 15.0,
            "Vitamin E": 12.0,
            "Vitamin K": 120.0,
            "B12": 2.4,
            "Folate": 400.0
        ]
        
        let minerals = [
            "Calcium": 1000.0,
            "Iron": 18.0,
            "Magnesium": 400.0,
            "Potassium": 3500.0,
            "Zinc": 11.0,
            "Sodium": 2300.0
        ]
        
        todayNutrition = NutritionData(
            calories: todayNutrition.calories,
            protein: todayNutrition.protein,
            carbs: todayNutrition.carbs,
            fat: todayNutrition.fat,
            fiber: todayNutrition.fiber,
            vitamins: vitamins,
            minerals: minerals
        )
    }
}
