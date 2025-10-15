//
//  SleepManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import HealthKit
import Combine
import SwiftUI

class SleepManager: ObservableObject {
    static let shared = SleepManager()
    
    @Published var todaySleepData: SleepData = SleepData(
        totalSleep: 0,
        deepSleep: 0,
        lightSleep: 0,
        remSleep: 0,
        bedTime: nil,
        wakeTime: nil
    )
    @Published var todaySleepStages: [SleepStage] = []
    @Published var weeklySleepData: [SleepData] = []
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
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let status = healthStore.authorizationStatus(for: sleepType)
        isAuthorized = status == .sharingAuthorized
        
        if isAuthorized {
            fetchSleepData()
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchSleepData()
                } else {
                    print("❌ Sleep authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    func fetchSleepData() {
        guard isAuthorized else { return }
        
        isLoading = true
        
        // Fetch today's sleep data
        fetchTodaySleepData()
        
        // Fetch weekly sleep data
        fetchWeeklySleepData()
        
        isLoading = false
    }
    
    private func fetchTodaySleepData() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            ),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKCategorySample] {
                    self?.processSleepSamples(samples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWeeklySleepData() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? Date()
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: HKQuery.predicateForSamples(
                withStart: startOfWeek,
                end: endOfWeek,
                options: .strictStartDate
            ),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKCategorySample] {
                    self?.processWeeklySleepSamples(samples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func processSleepSamples(_ samples: [HKCategorySample]) {
        var totalSleep: Double = 0
        var deepSleep: Double = 0
        var lightSleep: Double = 0
        var remSleep: Double = 0
        var bedTime: Date?
        var wakeTime: Date?
        
        var stages: [SleepStage] = []
        
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // Convert to hours
            totalSleep += duration
            
            // Categorize sleep stages based on HealthKit values
            let stageValue = sample.value
            let stageName: String
            let stageColor: Color
            
            switch stageValue {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                stageName = "In Bed"
                stageColor = .gray
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                stageName = "Light Sleep"
                stageColor = .green
                lightSleep += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                stageName = "Deep Sleep"
                stageColor = .blue
                deepSleep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                stageName = "REM Sleep"
                stageColor = .purple
                remSleep += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                stageName = "Awake"
                stageColor = .orange
            default:
                stageName = "Unknown"
                stageColor = .gray
            }
            
            if bedTime == nil {
                bedTime = sample.startDate
            }
            wakeTime = sample.endDate
            
            stages.append(SleepStage(
                name: stageName,
                duration: formatDuration(duration),
                percentage: (duration / totalSleep) * 100,
                color: stageColor
            ))
        }
        
        todaySleepData = SleepData(
            totalSleep: totalSleep,
            deepSleep: deepSleep,
            lightSleep: lightSleep,
            remSleep: remSleep,
            bedTime: bedTime,
            wakeTime: wakeTime
        )
        
        todaySleepStages = stages
    }
    
    private func processWeeklySleepSamples(_ samples: [HKCategorySample]) {
        let calendar = Calendar.current
        var dailySleepData: [Date: SleepData] = [:]
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
            
            if dailySleepData[day] == nil {
                dailySleepData[day] = SleepData(
                    totalSleep: 0,
                    deepSleep: 0,
                    lightSleep: 0,
                    remSleep: 0,
                    bedTime: nil,
                    wakeTime: nil
                )
            }
            
            var dayData = dailySleepData[day]!
            dayData = SleepData(
                totalSleep: dayData.totalSleep + duration,
                deepSleep: dayData.deepSleep + (sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ? duration : 0),
                lightSleep: dayData.lightSleep + (sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ? duration : 0),
                remSleep: dayData.remSleep + (sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ? duration : 0),
                bedTime: dayData.bedTime ?? sample.startDate,
                wakeTime: sample.endDate
            )
            dailySleepData[day] = dayData
        }
        
        weeklySleepData = dailySleepData.values.sorted { $0.bedTime ?? Date() < $1.bedTime ?? Date() }
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
