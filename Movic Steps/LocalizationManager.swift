//
//  LocalizationManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/23/25.
//  9/23/25 - Added multi-language support for Korean, Mandarin, Spanish, French, and German
//  100+ Lines of Code
//

import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "en"
    
    private init() {
        // Load saved language from UserDefaults first
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            currentLanguage = savedLanguage
        } else {
            // Get the current system language as fallback
            if let preferredLanguage = Locale.preferredLanguages.first {
                currentLanguage = preferredLanguage.prefix(2).lowercased()
            }
        }
    }
    
    func localizedString(for key: String) -> String {
        // Get the current language from UserDefaults
        let selectedLanguage = UserDefaults.standard.string(forKey: "selected_language") ?? "en"
        
        // Debug logging
        print("🌍 Localizing '\(key)' for language: \(selectedLanguage)")
        
        // Get the path to the localized strings file for the current language
        guard let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "\(selectedLanguage).lproj"),
              let dictionary = NSDictionary(contentsOfFile: path) else {
            print("⚠️ Could not find localization file for \(selectedLanguage), falling back to system")
            // Fallback to system language if custom language not found
            return NSLocalizedString(key, comment: "")
        }
        
        // Return the localized string for the key
        let localizedString = dictionary[key] as? String ?? key
        print("✅ Localized '\(key)' -> '\(localizedString)'")
        return localizedString
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selected_language")
        
        // Force UI update by posting notification
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func getCurrentLanguage() -> String {
        return currentLanguage
    }
}

// MARK: - String Extension for Easy Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}

// MARK: - SwiftUI View Extension for Localization
extension View {
    func localized(_ key: String) -> some View {
        Text(key.localized)
    }
}

// MARK: - Language Support
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case korean = "ko"
    case mandarin = "zh-Hans"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .mandarin: return "中文 (简体)"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .korean: return "🇰🇷"
        case .mandarin: return "🇨🇳"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        }
    }
}
