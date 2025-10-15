//
//  NutritionView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import HealthKit

struct NutritionView: View {
    @StateObject private var nutritionManager = NutritionManager.shared
    @StateObject private var enhancedNutritionManager = EnhancedNutritionManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedTimeframe: TimeFrame = .today
    @State private var showingAddFood = false
    @State private var showingNutritionGoals = false
    @State private var showingBarcodeScanner = false
    @State private var showingMealPlanner = false
    @State private var selectedMealType: NutritionMeal.MealType = .breakfast
    
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
                    colors: [Color.green.opacity(0.1), Color.orange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        NutritionHeaderView()
                        
                    // Time frame selector
                    NutritionTimeFrameSelector(selectedTimeframe: $selectedTimeframe)
                        
                        // Calorie summary card
                        CalorieSummaryCard(
                            consumed: nutritionManager.todayNutrition.calories,
                            goal: userSettings.dailyCalorieGoal,
                            burned: 0 // This would come from HealthKit
                        )
                        
                        // Macronutrients
                        MacronutrientsView(
                            protein: nutritionManager.todayNutrition.protein,
                            carbs: nutritionManager.todayNutrition.carbs,
                            fat: nutritionManager.todayNutrition.fat,
                            fiber: nutritionManager.todayNutrition.fiber
                        )
                        
                        // Micronutrients
                        MicronutrientsView(
                            vitamins: nutritionManager.todayNutrition.vitamins,
                            minerals: nutritionManager.todayNutrition.minerals
                        )
                        
                        // Recent meals
                        RecentMealsSection(
                            meals: nutritionManager.todayMeals,
                            onAddFood: { showingAddFood = true }
                        )
                        
                        // Quick actions
                        NutritionQuickActionsView(
                            onAddFood: { showingAddFood = true },
                            onSetGoals: { showingNutritionGoals = true },
                            onRefresh: { nutritionManager.fetchNutritionData() },
                            onBarcodeScan: { showingBarcodeScanner = true },
                            onMealPlan: { showingMealPlanner = true }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            nutritionManager.fetchNutritionData()
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView()
        }
        .sheet(isPresented: $showingNutritionGoals) {
            NutritionGoalsView()
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(
                isPresented: $showingBarcodeScanner,
                onBarcodeScanned: { barcode in
                    handleBarcodeScanned(barcode)
                }
            )
        }
        .sheet(isPresented: $showingMealPlanner) {
            MealPlannerView(selectedMealType: $selectedMealType)
        }
        .onAppear {
            if !nutritionManager.isAuthorized {
                nutritionManager.requestAuthorization()
            } else {
                nutritionManager.fetchNutritionData()
            }
        }
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        // Create a sample scanned food item
        let scannedFood = ScannedFood(
            name: "Sample Food Item",
            barcode: barcode,
            calories: 250,
            protein: 15,
            carbs: 30,
            fat: 8,
            fiber: 5,
            sugar: 12,
            sodium: 400,
            cholesterol: 20,
            servingSize: "1 serving",
            brand: "Sample Brand",
            dateScanned: Date()
        )
        
        enhancedNutritionManager.addScannedFood(scannedFood)
    }
}

// MARK: - Header View
struct NutritionHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track your daily nutrition intake")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "fork.knife")
                .font(.title)
                .foregroundColor(.green)
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
struct NutritionTimeFrameSelector: View {
    @Binding var selectedTimeframe: NutritionView.TimeFrame
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(NutritionView.TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: { selectedTimeframe = timeframe }) {
                    Text(timeframe.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeframe == timeframe ? Color.green : Color(.systemGray6))
                        )
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

// MARK: - Calorie Summary Card
struct CalorieSummaryCard: View {
    let consumed: Int
    let goal: Int
    let burned: Int
    @State private var flameAnimation = false
    
    private var remaining: Int {
        goal - consumed + burned
    }
    
    private var progress: Double {
        min(Double(consumed) / Double(goal), 1.0)
    }
    
    private var progressColor: Color {
        if progress > 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .green
        } else if progress >= 0.6 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calorie Balance")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(progressColor)
                            .frame(width: 8, height: 8)
                        
                        Text(remaining >= 0 ? "\(remaining) remaining" : "\(abs(remaining)) over goal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(progressColor)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(flameAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: flameAnimation)
                    
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .scaleEffect(flameAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: flameAnimation)
                }
            }
            
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(consumed)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text("kcal")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                if consumed > 0 {
                    Text("of \(goal) calorie goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Calorie progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Goal Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(min(progress, 1.0)) * 200, height: 8)
                        .animation(.easeInOut(duration: 1.0), value: progress)
                }
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
            flameAnimation = true
        }
    }
}

// MARK: - Macronutrients
struct MacronutrientsView: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MacroCard(
                    title: "Protein",
                    value: String(format: "%.1f", protein),
                    unit: "g",
                    color: .red,
                    icon: "fish"
                )
                
                MacroCard(
                    title: "Carbs",
                    value: String(format: "%.1f", carbs),
                    unit: "g",
                    color: .blue,
                    icon: "leaf"
                )
                
                MacroCard(
                    title: "Fat",
                    value: String(format: "%.1f", fat),
                    unit: "g",
                    color: .yellow,
                    icon: "drop"
                )
                
                MacroCard(
                    title: "Fiber",
                    value: String(format: "%.1f", fiber),
                    unit: "g",
                    color: .green,
                    icon: "leaf.arrow.circlepath"
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

// MARK: - Macro Card
struct MacroCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Micronutrients
struct MicronutrientsView: View {
    let vitamins: [String: Double]
    let minerals: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Micronutrients")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(vitamins.keys.prefix(4)), id: \.self) { vitamin in
                    MicronutrientRow(
                        name: vitamin,
                        value: vitamins[vitamin] ?? 0,
                        unit: "mg",
                        color: .purple
                    )
                }
                
                ForEach(Array(minerals.keys.prefix(4)), id: \.self) { mineral in
                    MicronutrientRow(
                        name: mineral,
                        value: minerals[mineral] ?? 0,
                        unit: "mg",
                        color: .orange
                    )
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

// MARK: - Micronutrient Row
struct MicronutrientRow: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recent Meals
struct RecentMealsSection: View {
    let meals: [MealItem]
    let onAddFood: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Meals")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Add Food", action: onAddFood)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(meals.prefix(3)) { meal in
                    MealRow(meal: meal)
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

// MARK: - Meal Row
struct MealRow: View {
    let meal: MealItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: meal.icon)
                .font(.title2)
                .foregroundColor(meal.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(meal.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(meal.calories) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(meal.time, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Actions
struct NutritionQuickActionsView: View {
    let onAddFood: () -> Void
    let onSetGoals: () -> Void
    let onRefresh: () -> Void
    let onBarcodeScan: () -> Void
    let onMealPlan: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Add Food",
                    icon: "plus.circle",
                    color: .green
                ) {
                    onAddFood()
                }
                
                QuickActionButton(
                    title: "Scan Barcode",
                    icon: "barcode.viewfinder",
                    color: .blue
                ) {
                    onBarcodeScan()
                }
                
                QuickActionButton(
                    title: "Meal Planner",
                    icon: "calendar",
                    color: .orange
                ) {
                    onMealPlan()
                }
                
                QuickActionButton(
                    title: "Set Goals",
                    icon: "target",
                    color: .purple
                ) {
                    onSetGoals()
                }
                
                QuickActionButton(
                    title: "Refresh Data",
                    icon: "arrow.clockwise",
                    color: .indigo
                ) {
                    onRefresh()
                }
                
                QuickActionButton(
                    title: "Nutrition History",
                    icon: "clock",
                    color: .brown
                ) {
                    // History action
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

// MARK: - Add Food View
struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Food Item")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        TextField("Food name", text: $foodName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Calories", text: $calories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        HStack(spacing: 16) {
                            TextField("Protein (g)", text: $protein)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                            
                            TextField("Carbs (g)", text: $carbs)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        
                        TextField("Fat (g)", text: $fat)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save food item
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Nutrition Goals View
struct NutritionGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @State private var calorieGoal: Double = 2000
    @State private var proteinGoal: Double = 150
    @State private var carbGoal: Double = 250
    @State private var fatGoal: Double = 65
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Set Your Nutrition Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    GoalSlider(
                        title: "Daily Calories",
                        value: $calorieGoal,
                        range: 1000...4000,
                        unit: "kcal"
                    )
                    
                    GoalSlider(
                        title: "Protein",
                        value: $proteinGoal,
                        range: 50...300,
                        unit: "g"
                    )
                    
                    GoalSlider(
                        title: "Carbohydrates",
                        value: $carbGoal,
                        range: 100...500,
                        unit: "g"
                    )
                    
                    GoalSlider(
                        title: "Fat",
                        value: $fatGoal,
                        range: 20...150,
                        unit: "g"
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userSettings.dailyCalorieGoal = Int(calorieGoal)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            calorieGoal = Double(userSettings.dailyCalorieGoal)
        }
    }
}

// MARK: - Goal Slider
struct GoalSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(value)) \(unit)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Slider(value: $value, in: range)
                .accentColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Data Models
struct NutritionData {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let vitamins: [String: Double]
    let minerals: [String: Double]
}

struct MealItem: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let time: Date
    let icon: String
    let color: Color
}

// MARK: - Meal Planner View
struct MealPlannerView: View {
    @Binding var selectedMealType: NutritionMeal.MealType
    @StateObject private var enhancedNutritionManager = EnhancedNutritionManager.shared
    @State private var mealName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Type") {
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(NutritionMeal.MealType.allCases, id: \.self) { mealType in
                            HStack {
                                Image(systemName: mealType.icon)
                                    .foregroundColor(mealType.color)
                                Text(mealType.rawValue)
                            }
                            .tag(mealType)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Meal Details") {
                    TextField("Meal Name", text: $mealName)
                    
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", text: $carbs)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Nutritional Breakdown") {
                    if !calories.isEmpty && !protein.isEmpty && !carbs.isEmpty && !fat.isEmpty {
                        let cal = Double(calories) ?? 0
                        let prot = Double(protein) ?? 0
                        let carb = Double(carbs) ?? 0
                        let fatVal = Double(fat) ?? 0
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Macronutrient Distribution")
                                .font(.headline)
                            
                            HStack {
                                Text("Protein: \(Int((prot * 4) / cal * 100))%")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("Carbs: \(Int((carb * 4) / cal * 100))%")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("Fat: \(Int((fatVal * 9) / cal * 100))%")
                                    .foregroundColor(.orange)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(mealName.isEmpty || calories.isEmpty)
                }
            }
        }
    }
    
    private func saveMeal() {
        let meal = NutritionMeal(
            name: mealName,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            cholesterol: 0,
            date: Date(),
            mealType: selectedMealType,
            barcode: nil
        )
        
        enhancedNutritionManager.addMeal(meal)
        dismiss()
    }
}

#Preview {
    NutritionView()
}
