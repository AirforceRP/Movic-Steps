//
//  HeartRateManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import HealthKit
import Combine
import SwiftUI

class HeartRateManager: ObservableObject {
    static let shared = HeartRateManager()
    
    @Published var currentHeartRate: Int = 0
    @Published var restingHeartRate: Int = 0
    @Published var maxHeartRate: Int = 0
    @Published var averageHeartRate: Int = 0
    @Published var heartRateZones: [HeartRateZone] = []
    @Published var todayHeartRateData: [HeartRateDataPoint] = []
    @Published var isLoading = false
    @Published var isAuthorized = false
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    
    private init() {
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available")
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        isAuthorized = status == .sharingAuthorized
        
        if isAuthorized {
            fetchHeartRateData()
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchHeartRateData()
                } else {
                    print("❌ Heart rate authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    func fetchHeartRateData() {
        guard isAuthorized else { return }
        
        isLoading = true
        
        // Fetch current heart rate (last 5 minutes)
        fetchCurrentHeartRate()
        
        // Fetch resting heart rate
        fetchRestingHeartRate()
        
        // Fetch today's heart rate data
        fetchTodayHeartRateData()
        
        // Calculate heart rate zones
        calculateHeartRateZones()
    }
    
    private func fetchCurrentHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: HKQuery.predicateForSamples(
                withStart: Calendar.current.date(byAdding: .minute, value: -5, to: Date()),
                end: Date(),
                options: .strictEndDate
            ),
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRate = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                    self?.currentHeartRate = heartRate
                }
                self?.isLoading = false
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            ),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKQuantitySample] {
                    let heartRates = samples.map { Int($0.quantity.doubleValue(for: HKUnit(from: "count/min"))) }
                    if !heartRates.isEmpty {
                        self?.restingHeartRate = heartRates.min() ?? 0
                        self?.averageHeartRate = heartRates.reduce(0, +) / heartRates.count
                    }
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayHeartRateData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            ),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKQuantitySample] {
                    let dataPoints = samples.map { sample in
                        HeartRateDataPoint(
                            value: Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min"))),
                            timestamp: sample.startDate
                        )
                    }
                    self?.todayHeartRateData = dataPoints
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func calculateHeartRateZones() {
        // Estimate max heart rate using 220 - age formula
        // For now, we'll use a default of 180 for demonstration
        let estimatedMaxHR = 180
        
        heartRateZones = [
            HeartRateZone(name: "Rest", min: 0, max: Int(Double(estimatedMaxHR) * 0.5), color: Color.blue),
            HeartRateZone(name: "Fat Burn", min: Int(Double(estimatedMaxHR) * 0.5), max: Int(Double(estimatedMaxHR) * 0.6), color: Color.green),
            HeartRateZone(name: "Cardio", min: Int(Double(estimatedMaxHR) * 0.6), max: Int(Double(estimatedMaxHR) * 0.7), color: Color.yellow),
            HeartRateZone(name: "Peak", min: Int(Double(estimatedMaxHR) * 0.7), max: Int(Double(estimatedMaxHR) * 0.85), color: Color.orange),
            HeartRateZone(name: "Max", min: Int(Double(estimatedMaxHR) * 0.85), max: estimatedMaxHR, color: Color.red)
        ]
    }
    
    // MARK: - Heart Rate Analysis
    func getCurrentZone() -> HeartRateZone? {
        return heartRateZones.first { zone in
            currentHeartRate >= zone.min && currentHeartRate < zone.max
        }
    }
    
    func getHeartRateStatus() -> HeartRateStatus {
        if currentHeartRate == 0 {
            return .noData
        } else if currentHeartRate < 60 {
            return .low
        } else if currentHeartRate > 100 {
            return .high
        } else {
            return .normal
        }
    }
}

// MARK: - Data Models
struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let value: Int
    let timestamp: Date
}

struct HeartRateZone: Identifiable {
    let id = UUID()
    let name: String
    let min: Int
    let max: Int
    let color: Color
    
    var range: String {
        "\(min)-\(max) BPM"
    }
}

enum HeartRateStatus {
    case noData
    case low
    case normal
    case high
    
    var description: String {
        switch self {
        case .noData: return "No Data"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .noData: return Color.gray
        case .low: return Color.blue
        case .normal: return Color.green
        case .high: return Color.red
        }
    }
}
