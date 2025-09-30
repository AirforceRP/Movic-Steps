//
//  CalibrationView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI

struct CalibrationView: View {
    @ObservedObject var stepCounter: AccelerometerStepCounter
    @Environment(\.dismiss) private var dismiss
    @State private var calibrationSteps = 0
    @State private var knownSteps = 20
    @State private var isCalibrating = false
    @State private var calibrationComplete = false
    @State private var showingInstructions = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if showingInstructions {
                    instructionsView
                } else if isCalibrating {
                    calibrationInProgressView
                } else if calibrationComplete {
                    calibrationCompleteView
                } else {
                    setupView
                }
            }
            .padding()
            .navigationTitle("Step Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if calibrationComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("step_calibration".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("calibration_description".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                InstructionStep(number: 1, text: "instruction_1".localized)
                InstructionStep(number: 2, text: "instruction_2".localized)
                InstructionStep(number: 3, text: "instruction_3".localized)
                InstructionStep(number: 4, text: "instruction_4".localized)
            }
            
            Spacer()
            
            Button(action: {
                showingInstructions = false
            }) {
                Text("start_calibration".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
    
    private var setupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Setup Calibration")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Text("How many steps will you walk?")
                    .font(.headline)
                
                HStack {
                    Button(action: { knownSteps = max(10, knownSteps - 5) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(knownSteps) steps")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(width: 120)
                    
                    Button(action: { knownSteps = min(100, knownSteps + 5) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                Text("Recommended: 20-50 steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: startCalibration) {
                Text("Begin Walking")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
    }
    
    private var calibrationInProgressView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(Double(calibrationSteps) / Double(knownSteps), 1.0))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: calibrationSteps)
                
                VStack {
                    Text("\(calibrationSteps)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Walk \(knownSteps) steps")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Hold your phone naturally and walk at your normal pace")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: completeCalibration) {
                    Text("I've Walked \(knownSteps) Steps")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    isCalibrating = false
                    calibrationSteps = 0
                    stepCounter.resetStepCount()
                }) {
                    Text("Start Over")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .onReceive(stepCounter.$currentSteps) { steps in
            calibrationSteps = steps
        }
    }
    
    private var calibrationCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Calibration Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ResultRow(label: "Steps You Walked", value: "\(knownSteps)")
                ResultRow(label: "Steps Detected", value: "\(calibrationSteps)")
                ResultRow(label: "Calibration Factor", value: String(format: "%.2fx", stepCounter.getCalibrationFactor()))
                
                let accuracy = calibrationSteps > 0 ? (Double(min(knownSteps, calibrationSteps)) / Double(max(knownSteps, calibrationSteps))) * 100 : 0
                ResultRow(label: "Accuracy", value: String(format: "%.1f%%", accuracy))
            }
            
            Text("Your step counter has been calibrated for improved accuracy!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    private func startCalibration() {
        isCalibrating = true
        calibrationSteps = 0
        stepCounter.startCalibration()
        stepCounter.startTracking()
    }
    
    private func completeCalibration() {
        stepCounter.stopTracking()
        stepCounter.calibrateWithKnownSteps(knownSteps)
        isCalibrating = false
        calibrationComplete = true
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    CalibrationView(stepCounter: AccelerometerStepCounter())
}
