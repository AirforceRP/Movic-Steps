//
//  MoreView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI

struct MoreView: View {
    @State private var showingMilestone = true
    @State private var selectedCategory: HealthCategory?
    
    enum HealthCategory: String, CaseIterable {
        case heartRate = "Heart Rate"
        case workouts = "Workouts"
        case sleep = "Sleep"
        case nutrition = "Nutrition"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .workouts: return "figure.mixed.cardio"
            case .sleep: return "moon.fill"
            case .nutrition: return "fork.knife"
            case .settings: return "gearshape"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .workouts: return .pink
            case .sleep: return .indigo
            case .nutrition: return .brown
            case .settings: return .gray
            }
        }
        
        var description: String {
            switch self {
            case .heartRate: return "Monitor your heart health"
            case .workouts: return "Track your fitness activities"
            case .sleep: return "Analyze your sleep patterns"
            case .nutrition: return "Manage your daily nutrition"
            case .settings: return "Customize your experience"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Milestone Notification
                        if showingMilestone {
                            MilestoneCard()
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                        
                        // Health Categories Grid
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Health & Fitness")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(HealthCategory.allCases, id: \.self) { category in
                                    HealthCategoryCard(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = category
                                        }
                                        
                                        // Navigate to the specific view
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            // Handle navigation here
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Quick Stats
                        QuickStatsSection()
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Milestone Card
struct MilestoneCard: View {
    @State private var sparkleAnimation = false
    @State private var scaleAnimation = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .scaleEffect(scaleAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: scaleAnimation)
                
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Milestone Reached!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Fantastic! You've reached 7,500 steps today! Keep up the great work!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    ForEach(0..<3) { _ in
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .scaleEffect(sparkleAnimation ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.5)), value: sparkleAnimation)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .onAppear {
            sparkleAnimation = true
            scaleAnimation = true
        }
    }
}

// MARK: - Health Category Card
struct HealthCategoryCard: View {
    let category: MoreView.HealthCategory
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    @State private var iconAnimation = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(category.color)
                        .scaleEffect(iconAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: iconAnimation)
                }
                
                VStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(category.color)
                        
                        Text("Selected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(category.color)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? category.color.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(
                color: isSelected ? category.color.opacity(0.2) : .black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            iconAnimation = true
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            action()
        }
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                QuickStatCard(
                    title: "Steps",
                    value: "7,500",
                    icon: "figure.walk",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Calories",
                    value: "420",
                    icon: "flame",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "Active",
                    value: "45m",
                    icon: "clock",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @State private var valueAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .scaleEffect(valueAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: valueAnimation)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .onAppear {
            valueAnimation = true
        }
    }
}

#Preview {
    MoreView()
}
