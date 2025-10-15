//
//  AccelerometerStepCounter.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import CoreMotion
import Combine
import QuartzCore
import UIKit

class AccelerometerStepCounter: ObservableObject {
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private let goalTracker = GoalTracker.shared
    private let userSettings = UserSettings.shared
    
    @Published var currentSteps: Int = 0
    @Published var currentFloors: Int = 0
    @Published var isTracking: Bool = false
    @Published var acceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    
    // Method to manually update goal progress
    func updateGoalProgress() {
        goalTracker.updateStepProgress(currentSteps)
    }
    
    // Step detection parameters
    private var stepThreshold: Double = 1.2
    private var minTimeBetweenSteps: TimeInterval = 0.3
    private var lastStepTime: TimeInterval = 0
    private var accelerationHistory: [Double] = []
    private let historySize = 10
    
    // Floor detection parameters
    private var lastAltitude: Double = 0
    private var altitudeHistory: [Double] = []
    private var floorDetectionEnabled: Bool = false
    private var lastFloorTime: TimeInterval = 0
    private var minTimeBetweenFloors: TimeInterval = 2.0
    
    // Smoothing and filtering
    private var filteredAcceleration: Double = 0
    private let smoothingFactor: Double = 0.1
    
    init() {
        setupMotionManager()
        requestMotionPermissions()
        enableFloorDetection()
    }
    
    private func setupMotionManager() {
        motionManager.accelerometerUpdateInterval = 0.1 // 10 Hz
        motionManager.deviceMotionUpdateInterval = 0.1
    }
    
    private func requestMotionPermissions() {
        // Check if motion data is available
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available")
            return
        }
        
        // For iOS 17+, we might need to request permission
        if #available(iOS 17.0, *) {
            // Request motion permission if needed
            startAccelerometerUpdates()
        } else {
            startAccelerometerUpdates()
        }
    }
    
    func startTracking() {
        guard !isTracking else { return }
        
        isTracking = true
        currentSteps = 0
        currentFloors = 0
        updateGoalProgress()
        
        // Use CMPedometer for more accurate step counting when available
        if CMPedometer.isStepCountingAvailable() {
            startPedometerTracking()
        } else {
            // Fallback to accelerometer-based detection
            startAccelerometerUpdates()
        }
    }
    
    func stopTracking() {
        isTracking = false
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        pedometer.stopUpdates()
    }
    
    private func startPedometerTracking() {
        let startDate = Date()
        
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let self = self, let data = data else {
                if let error = error {
                    print("Pedometer error: \(error.localizedDescription)")
                    // Fallback to accelerometer
                    self?.startAccelerometerUpdates()
                }
                return
            }
            
            DispatchQueue.main.async {
                self.currentSteps = data.numberOfSteps.intValue
                self.updateGoalProgress()
            }
        }
    }
    
    private func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            self.acceleration = data.acceleration
            self.processAccelerometerData(data.acceleration)
        }
        
        // Also start device motion for better accuracy
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }
                
                self.processDeviceMotion(motion)
            }
        }
    }
    
    private func processAccelerometerData(_ acceleration: CMAcceleration) {
        // Calculate magnitude of acceleration vector
        let magnitude = sqrt(acceleration.x * acceleration.x + 
                           acceleration.y * acceleration.y + 
                           acceleration.z * acceleration.z)
        
        // Apply low-pass filter to smooth the data
        filteredAcceleration = smoothingFactor * magnitude + (1 - smoothingFactor) * filteredAcceleration
        
        // Add to history
        accelerationHistory.append(filteredAcceleration)
        if accelerationHistory.count > historySize {
            accelerationHistory.removeFirst()
        }
        
        // Detect steps using peak detection
        detectStep()
        
        // Detect floor changes
        detectFloorChange()
    }
    
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        // Use user acceleration (gravity removed) for better step detection
        let userAcceleration = motion.userAcceleration
        let magnitude = sqrt(userAcceleration.x * userAcceleration.x + 
                           userAcceleration.y * userAcceleration.y + 
                           userAcceleration.z * userAcceleration.z)
        
        // Process this more accurate data
        processAccelerationMagnitude(magnitude)
    }
    
    private func processAccelerationMagnitude(_ magnitude: Double) {
        // Apply smoothing
        filteredAcceleration = smoothingFactor * magnitude + (1 - smoothingFactor) * filteredAcceleration
        
        // Add to history
        accelerationHistory.append(filteredAcceleration)
        if accelerationHistory.count > historySize {
            accelerationHistory.removeFirst()
        }
        
        // Detect steps
        detectStep()
    }
    
    private func detectStep() {
        guard accelerationHistory.count >= historySize else { return }
        
        let currentTime = CACurrentMediaTime()
        
        // Check if enough time has passed since last step
        guard currentTime - lastStepTime > minTimeBetweenSteps else { return }
        
        // Get recent values for peak detection
        let recentValues = Array(accelerationHistory.suffix(5))
        let currentValue = recentValues.last ?? 0
        
        // Simple peak detection: current value is higher than threshold and higher than neighbors
        if currentValue > stepThreshold {
            let isLocalMaximum = recentValues.enumerated().allSatisfy { index, value in
                index == recentValues.count - 1 || value <= currentValue
            }
            
            if isLocalMaximum {
                // Additional validation: check if there's a valley before this peak
                let hasValley = accelerationHistory.dropLast(2).suffix(3).min() ?? 0 < stepThreshold * 0.7
                
                if hasValley {
                    registerStep()
                    lastStepTime = currentTime
                }
            }
        }
    }
    
    private func registerStep() {
        DispatchQueue.main.async {
            // Apply calibration factor
            let calibrationFactor = UserSettings.shared.stepCalibrationFactor
            let adjustedStep = Int(1.0 * calibrationFactor)
            self.currentSteps += max(1, adjustedStep)
            
            // Add haptic feedback for step detection
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    // Calibration methods
    func calibrateStepThreshold(sensitivity: Double) {
        // Adjust threshold based on user preference (0.5 - 2.0)
        stepThreshold = 1.0 + (sensitivity - 0.5) * 1.0
    }
    
    func resetStepCount() {
        currentSteps = 0
        updateGoalProgress()
    }
    
    // MARK: - Calibration Methods
    func startCalibration() {
        // Reset for calibration
        currentSteps = 0
        lastStepTime = 0
        updateGoalProgress()
        accelerationHistory.removeAll()
    }
    
    func calibrateWithKnownSteps(_ knownSteps: Int) {
        guard currentSteps > 0 && knownSteps > 0 else { return }
        
        let newCalibrationFactor = Double(knownSteps) / Double(currentSteps)
        UserSettings.shared.stepCalibrationFactor = newCalibrationFactor
        
        // Apply calibration to current count
        currentSteps = knownSteps
        updateGoalProgress()
    }
    
    func getCalibrationFactor() -> Double {
        return UserSettings.shared.stepCalibrationFactor
    }
    
    // MARK: - Floor Detection Methods
    
    private func enableFloorDetection() {
        floorDetectionEnabled = userSettings.enableFloorTracking
    }
    
    private func detectFloorChange() {
        guard floorDetectionEnabled else { return }
        
        let currentTime = CACurrentMediaTime()
        
        // Check if enough time has passed since last floor detection
        guard currentTime - lastFloorTime > minTimeBetweenFloors else { return }
        
        // Simple floor detection based on vertical acceleration patterns
        // This is a basic implementation - in a real app, you'd use barometric pressure
        let verticalAcceleration = abs(acceleration.z)
        let threshold = userSettings.floorSensitivity.threshold
        
        if verticalAcceleration > threshold {
            // Check if this represents a significant vertical movement
            let recentValues = Array(accelerationHistory.suffix(5))
            let isSignificantChange = recentValues.allSatisfy { $0 > threshold * 0.8 }
            
            if isSignificantChange {
                registerFloorClimbed()
                lastFloorTime = currentTime
            }
        }
    }
    
    private func registerFloorClimbed() {
        DispatchQueue.main.async {
            self.currentFloors += 1
            
            // Add haptic feedback for floor detection
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    func resetFloorCount() {
        currentFloors = 0
    }
    
    deinit {
        stopTracking()
    }
}

// MARK: - Step Detection Settings
extension AccelerometerStepCounter {
    enum StepSensitivity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        
        var threshold: Double {
            switch self {
            case .low: return 1.5
            case .medium: return 1.2
            case .high: return 0.9
            }
        }
        
        var minTimeBetweenSteps: TimeInterval {
            switch self {
            case .low: return 0.4
            case .medium: return 0.3
            case .high: return 0.2
            }
        }
    }
    
    func setSensitivity(_ sensitivity: StepSensitivity) {
        stepThreshold = sensitivity.threshold
        minTimeBetweenSteps = sensitivity.minTimeBetweenSteps
    }
}
