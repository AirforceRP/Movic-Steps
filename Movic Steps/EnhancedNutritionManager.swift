//
//  EnhancedNutritionManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import Foundation
import SwiftUI
import Combine

class EnhancedNutritionManager: ObservableObject {
    static let shared = EnhancedNutritionManager()
    
    @Published var todayNutrition: DetailedNutrition
    @Published var meals: [NutritionMeal] = []
    @Published var scannedFoods: [ScannedFood] = []
    @Published var nutritionGoals: NutritionGoals
    @Published var isScanning = false
    @Published var showingBarcodeScanner = false
    
    private init() {
        self.todayNutrition = DetailedNutrition()
        self.nutritionGoals = NutritionGoals()
        loadMeals()
        loadScannedFoods()
        loadNutritionGoals()
    }
    
    // MARK: - Meal Management
    func addMeal(_ meal: NutritionMeal) {
        meals.append(meal)
        updateTodayNutrition()
        saveMeals()
    }
    
    func removeMeal(at index: Int) {
        guard index < meals.count else { return }
        meals.remove(at: index)
        updateTodayNutrition()
        saveMeals()
    }
    
    func addScannedFood(_ food: ScannedFood) {
        scannedFoods.append(food)
        saveScannedFoods()
    }
    
    // MARK: - Nutrition Calculation
    private func updateTodayNutrition() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayMeals = meals.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        todayNutrition = DetailedNutrition(
            calories: todayMeals.reduce(0) { $0 + $1.calories },
            protein: todayMeals.reduce(0) { $0 + $1.protein },
            carbs: todayMeals.reduce(0) { $0 + $1.carbs },
            fat: todayMeals.reduce(0) { $0 + $1.fat },
            fiber: todayMeals.reduce(0) { $0 + $1.fiber },
            sugar: todayMeals.reduce(0) { $0 + $1.sugar },
            sodium: todayMeals.reduce(0) { $0 + $1.sodium },
            cholesterol: todayMeals.reduce(0) { $0 + $1.cholesterol }
        )
    }
    
    // MARK: - Persistence
    private func saveMeals() {
        if let encoded = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(encoded, forKey: "savedMeals")
        }
    }
    
    private func loadMeals() {
        if let data = UserDefaults.standard.data(forKey: "savedMeals"),
           let decoded = try? JSONDecoder().decode([NutritionMeal].self, from: data) {
            meals = decoded
            updateTodayNutrition()
        }
    }
    
    private func saveScannedFoods() {
        if let encoded = try? JSONEncoder().encode(scannedFoods) {
            UserDefaults.standard.set(encoded, forKey: "scannedFoods")
        }
    }
    
    private func loadScannedFoods() {
        if let data = UserDefaults.standard.data(forKey: "scannedFoods"),
           let decoded = try? JSONDecoder().decode([ScannedFood].self, from: data) {
            scannedFoods = decoded
        }
    }
    
    // MARK: - Nutrition Goals Management
    func saveNutritionGoals() {
        if let encoded = try? JSONEncoder().encode(nutritionGoals) {
            UserDefaults.standard.set(encoded, forKey: "nutritionGoals")
        }
    }
    
    private func loadNutritionGoals() {
        if let data = UserDefaults.standard.data(forKey: "nutritionGoals"),
           let decoded = try? JSONDecoder().decode(NutritionGoals.self, from: data) {
            nutritionGoals = decoded
        }
    }
}

// MARK: - Data Models
struct DetailedNutrition: Codable {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0
    var cholesterol: Double = 0
    
    var proteinPercentage: Double {
        (protein * 4) / calories * 100
    }
    
    var carbsPercentage: Double {
        (carbs * 4) / calories * 100
    }
    
    var fatPercentage: Double {
        (fat * 9) / calories * 100
    }
}

struct NutritionMeal: Identifiable, Codable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let date: Date
    let mealType: MealType
    let barcode: String?
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        
        var icon: String {
            switch self {
            case .breakfast: return "sunrise"
            case .lunch: return "sun.max"
            case .dinner: return "sunset"
            case .snack: return "leaf"
            }
        }
        
        var color: Color {
            switch self {
            case .breakfast: return .orange
            case .lunch: return .yellow
            case .dinner: return .purple
            case .snack: return .green
            }
        }
    }
}

struct ScannedFood: Identifiable, Codable {
    let id = UUID()
    let name: String
    let barcode: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let servingSize: String
    let brand: String?
    let dateScanned: Date
}

struct NutritionGoals: Codable {
    var calories: Double = 2000
    var protein: Double = 150
    var carbs: Double = 250
    var fat: Double = 65
    var fiber: Double = 25
    var sugar: Double = 50
    var sodium: Double = 2300
    var cholesterol: Double = 300
}

// MARK: - Barcode Scanner
struct BarcodeScannerView: View {
    @Binding var isPresented: Bool
    let onBarcodeScanned: (String) -> Void
    @StateObject private var cameraManager = CameraManager()
    @State private var showingPermissionAlert = false
    @State private var scannedCode = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraManager.isAuthorized {
                    CameraView(cameraManager: cameraManager) { barcode in
                        scannedCode = barcode
                        onBarcodeScanned(barcode)
                        isPresented = false
                    }
                    .ignoresSafeArea()
                } else {
                    // Permission denied view
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Please allow camera access to scan barcodes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                
                // Top overlay
                VStack {
                    HStack {
                        Button("Cancel") {
                            cameraManager.stopSession()
                            isPresented = false
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if cameraManager.isAuthorized {
                cameraManager.setupCamera()
                cameraManager.startSession()
            } else {
                showingPermissionAlert = true
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel") {
                isPresented = false
            }
        } message: {
            Text("Please enable camera access in Settings to scan barcodes.")
        }
    }
}
