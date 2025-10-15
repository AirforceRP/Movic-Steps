//
//  FloorTrackingSetupView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI

struct FloorTrackingSetupView: View {
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingFloorHeightPicker = false
    @State private var showingSensitivityInfo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.indigo)
                            .pulseEffect(color: .indigo, intensity: 0.3)
                        
                        Text("floor_tracking_setup".localized)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("floor_tracking_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Enable Floor Tracking Toggle
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("enable_floor_tracking".localized)
                                    .font(.headline)
                                
                                Text("floor_tracking_toggle_description".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $userSettings.enableFloorTracking)
                                .labelsHidden()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    if userSettings.enableFloorTracking {
                        // Floor Height Configuration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("floor_height_configuration".localized)
                                .font(.headline)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("floor_height".localized)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", userSettings.floorHeight)) \(userSettings.unitSystem == .metric ? "m" : "ft")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.indigo)
                                }
                                
                                Slider(
                                    value: $userSettings.floorHeight,
                                    in: userSettings.unitSystem == .metric ? 2.0...5.0 : 6.0...16.0,
                                    step: userSettings.unitSystem == .metric ? 0.1 : 0.5
                                )
                                .accentColor(.indigo)
                                
                                Text("floor_height_description".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        
                        // Floor Sensitivity Configuration
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("floor_sensitivity".localized)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingSensitivityInfo = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                Picker("floor_sensitivity".localized, selection: $userSettings.floorSensitivity) {
                                    ForEach(FloorSensitivity.allCases) { sensitivity in
                                        Text(sensitivity.displayName).tag(sensitivity)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                Text(userSettings.floorSensitivity.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        
                        // Floor Tracking Tips
                        VStack(alignment: .leading, spacing: 12) {
                            Text("floor_tracking_tips".localized)
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(
                                    icon: "location.fill",
                                    text: "floor_tip_location".localized
                                )
                                
                                TipRow(
                                    icon: "iphone",
                                    text: "floor_tip_device".localized
                                )
                                
                                TipRow(
                                    icon: "tuningfork",
                                    text: "floor_tip_calibration".localized
                                )
                                
                                TipRow(
                                    icon: "battery.100",
                                    text: "floor_tip_battery".localized
                                )
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("floor_tracking_setup".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingSensitivityInfo) {
            FloorSensitivityInfoView()
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct FloorSensitivityInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("sensitivity_levels".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(FloorSensitivity.allCases) { sensitivity in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(sensitivity.displayName)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("threshold: \(String(format: "%.1f", sensitivity.threshold))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(sensitivity.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("how_it_works".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("floor_detection_explanation".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding()
            }
            .navigationTitle("sensitivity_info".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FloorTrackingSetupView()
}
