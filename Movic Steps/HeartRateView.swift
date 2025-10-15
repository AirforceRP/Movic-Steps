//
//  HeartRateView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import HealthKit

struct HeartRateView: View {
    @StateObject private var heartRateManager = HeartRateManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedTimeframe: TimeFrame = .today
    @State private var showingHeartRateChart = false
    
    enum TimeFrame: String, CaseIterable {
        case today = "today"
        case week = "week"
        case month = "month"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .today: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .year: return "This Year"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.red.opacity(0.1), Color.pink.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 28) {
                        // Header
                        HeartRateHeaderView()
                        
                    // Time frame selector
                    HeartRateTimeFrameSelector(selectedTimeframe: $selectedTimeframe)
                        
                        // Current heart rate card
                        CurrentHeartRateCard(
                            heartRate: heartRateManager.currentHeartRate,
                            status: heartRateManager.getHeartRateStatus(),
                            zone: heartRateManager.getCurrentZone()
                        )
                        
                        // Heart rate metrics
                        HeartRateMetricsView(
                            resting: heartRateManager.restingHeartRate,
                            average: heartRateManager.averageHeartRate,
                            max: heartRateManager.maxHeartRate
                        )
                        
                        // Heart rate zones
                        HeartRateZonesView(zones: heartRateManager.heartRateZones)
                        
                        // Quick actions
                        HeartRateQuickActionsView(
                            onViewChart: { showingHeartRateChart = true },
                            onRefresh: { heartRateManager.fetchHeartRateData() }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            heartRateManager.fetchHeartRateData()
        }
        .sheet(isPresented: $showingHeartRateChart) {
            HeartRateChartView(data: heartRateManager.todayHeartRateData)
        }
        .onAppear {
            if !heartRateManager.isAuthorized {
                heartRateManager.requestAuthorization()
            } else {
                heartRateManager.fetchHeartRateData()
            }
        }
    }
}

// MARK: - Header View
struct HeartRateHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Heart Rate Monitor")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track your cardiovascular health")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundColor(.red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Time Frame Selector
struct HeartRateTimeFrameSelector: View {
    @Binding var selectedTimeframe: HeartRateView.TimeFrame
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(HeartRateView.TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeframe = timeframe
                    }
                }) {
                    Text(timeframe.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    selectedTimeframe == timeframe ? 
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color(.systemGray6), Color(.systemGray6).opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(
                                    color: selectedTimeframe == timeframe ? Color.red.opacity(0.3) : Color.clear,
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        )
                        .scaleEffect(selectedTimeframe == timeframe ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Current Heart Rate Card
struct CurrentHeartRateCard: View {
    let heartRate: Int
    let status: HeartRateStatus
    let zone: HeartRateZone?
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Heart Rate")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        Text(status.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(status.color)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                }
            }
            
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(heartRate)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text("BPM")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                if heartRate > 0 {
                    Text("Beats per minute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let zone = zone {
                HStack(spacing: 12) {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 16, height: 16)
                        .shadow(color: zone.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(zone.name) Zone")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(zone.range)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(zone.color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(zone.color.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(zone.color.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Heart Rate Metrics
struct HeartRateMetricsView: View {
    let resting: Int
    let average: Int
    let max: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Rate Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                HeartRateMetricCard(
                    title: "Resting",
                    value: "\(resting)",
                    unit: "BPM",
                    color: .blue,
                    icon: "heart.circle"
                )
                
                HeartRateMetricCard(
                    title: "Average",
                    value: "\(average)",
                    unit: "BPM",
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                HeartRateMetricCard(
                    title: "Max",
                    value: "\(max)",
                    unit: "BPM",
                    color: .red,
                    icon: "arrow.up.circle"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Heart Rate Zones
struct HeartRateZonesView: View {
    let zones: [HeartRateZone]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Rate Zones")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(zones) { zone in
                    HeartRateZoneRow(zone: zone)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Heart Rate Zone Row
struct HeartRateZoneRow: View {
    let zone: HeartRateZone
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(zone.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(zone.range)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(zone.color.opacity(0.1))
        )
    }
}

// MARK: - Quick Actions
struct HeartRateQuickActionsView: View {
    let onViewChart: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                HeartRateQuickActionButton(
                    title: "View Chart",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ) {
                    onViewChart()
                }
                
                HeartRateQuickActionButton(
                    title: "Refresh Data",
                    icon: "arrow.clockwise",
                    color: .green
                ) {
                    onRefresh()
                }
                
                HeartRateQuickActionButton(
                    title: "Set Alerts",
                    icon: "bell",
                    color: .orange
                ) {
                    // Alert setting action
                }
                
                HeartRateQuickActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    // Export action
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Heart Rate Chart View
struct HeartRateChartView: View {
    let data: [HeartRateDataPoint]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if data.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Heart Rate Data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Start a workout or enable heart rate monitoring to see your data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Simple line chart representation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Heart Rate Over Time")
                            .font(.headline)
                        
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(data.prefix(20)) { point in
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: CGFloat(point.value) / 2)
                            }
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Heart Rate Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Metric Card
struct HeartRateMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                
                Text(unit)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.08), color.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Heart Rate Quick Action Button
struct HeartRateQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    HeartRateView()
}
