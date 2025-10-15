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
            print("🌍 LocalizationManager initialized with saved language: \(savedLanguage)")
        } else {
            // Get the current system language as fallback
            if let preferredLanguage = Locale.preferredLanguages.first {
                let systemLang = preferredLanguage.prefix(2).lowercased()
                // Map system language to supported languages
                if SupportedLanguage.allCases.contains(where: { $0.rawValue == systemLang }) {
                    currentLanguage = systemLang
                    // Save the detected system language
                    UserDefaults.standard.set(systemLang, forKey: "selected_language")
                } else {
                    currentLanguage = "en" // Default to English if system language not supported
                    UserDefaults.standard.set("en", forKey: "selected_language")
                }
                print("🌍 LocalizationManager initialized with system language: \(systemLang) -> \(currentLanguage)")
            } else {
                currentLanguage = "en"
                UserDefaults.standard.set("en", forKey: "selected_language")
                print("🌍 LocalizationManager initialized with default language: en")
            }
        }
        
        // Debug localization files
        debugLocalizationFiles()
        
        // Test initial translation
        let testTranslation = localizedString(for: "app_name")
        print("🌍 Initial test translation: '\(testTranslation)'")
        
        // Verify the language is properly set
        let savedLanguage = UserDefaults.standard.string(forKey: "selected_language")
        print("🌍 Final verification - saved language: \(savedLanguage ?? "nil"), current language: \(currentLanguage)")
    }
    
    func localizedString(for key: String) -> String {
        // Use the current language from the instance variable for consistency
        let selectedLanguage = currentLanguage
        
        // Debug logging
        print("🌍 Localizing '\(key)' for language: \(selectedLanguage)")
        
        // Try to load from Resources/Localizations directory
        let resourcesPath = "Resources/Localizations/\(selectedLanguage).lproj"
        print("🌍 Trying path: \(resourcesPath)")
        
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: resourcesPath) {
            print("✅ Found file at: \(path)")
            if let dictionary = NSDictionary(contentsOfFile: path) {
                let localizedString = dictionary[key] as? String ?? key
                if localizedString != key {
                    print("✅ Localized '\(key)' -> '\(localizedString)' (from Resources/Localizations)")
                    return localizedString
                } else {
                    print("⚠️ Key '\(key)' not found in dictionary for \(selectedLanguage)")
                }
            } else {
                print("❌ Could not load dictionary from: \(path)")
            }
        } else {
            print("❌ Could not find file at: \(resourcesPath)")
        }
        
        // Try alternative path structure
        print("🌍 Trying alternative path: \(selectedLanguage).lproj")
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "\(selectedLanguage).lproj") {
            print("✅ Found alternative file at: \(path)")
            if let dictionary = NSDictionary(contentsOfFile: path) {
                let localizedString = dictionary[key] as? String ?? key
                if localizedString != key {
                    print("✅ Localized '\(key)' -> '\(localizedString)' (from bundle)")
                    return localizedString
                }
            }
        } else {
            print("❌ Could not find alternative file at: \(selectedLanguage).lproj")
        }
        
        // Fallback to system localization
        let systemLocalizedString = NSLocalizedString(key, comment: "")
        if systemLocalizedString != key {
            print("✅ Localized '\(key)' -> '\(systemLocalizedString)' (from system)")
            return systemLocalizedString
        }
        
        print("⚠️ Could not find localization for '\(key)', returning key")
        return key
    }
    
    func setLanguage(_ language: String) {
        print("🔄 Setting language to: \(language)")
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selected_language")
        
        // Verify the language was saved
        let savedLanguage = UserDefaults.standard.string(forKey: "selected_language")
        print("🔄 Saved language verification: \(savedLanguage ?? "nil")")
        
        // Debug: Test a translation immediately
        let testTranslation = localizedString(for: "app_name")
        print("🔄 Language changed to \(language), test translation: '\(testTranslation)'")
        
        // Test a few more translations
        let navSteps = localizedString(for: "nav_steps")
        let dashboardTitle = localizedString(for: "dashboard_title")
        print("🔄 Additional test translations - nav_steps: '\(navSteps)', dashboard_title: '\(dashboardTitle)'")
        
        // Force UI update by posting notification
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func getCurrentLanguage() -> String {
        return currentLanguage
    }
    
    func refreshLanguageFromUserDefaults() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            if savedLanguage != currentLanguage {
                print("🔄 Refreshing language from UserDefaults: \(currentLanguage) -> \(savedLanguage)")
                currentLanguage = savedLanguage
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - Debug Methods
    func debugLocalizationFiles() {
        print("🔍 Debug: Checking available localization files...")
        
        let bundle = Bundle.main
        
        // Check all supported languages
        for language in SupportedLanguage.allCases {
            let path = "Resources/Localizations/\(language.rawValue).lproj"
            if let filePath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: path) {
                print("✅ Found \(language.rawValue) at: \(filePath)")
                
                if let dict = NSDictionary(contentsOfFile: filePath) {
                    let appName = dict["app_name"] as? String ?? "NOT FOUND"
                    print("   app_name: \(appName)")
                } else {
                    print("   ❌ Could not load dictionary")
                }
            } else {
                print("❌ Missing \(language.rawValue) at: \(path)")
            }
        }
        
        // List all .lproj directories in bundle
        if let resourcePath = bundle.resourcePath {
            let fileManager = FileManager.default
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
                let lprojDirs = contents.filter { $0.hasSuffix(".lproj") }
                print("🔍 All .lproj directories in bundle: \(lprojDirs)")
            } catch {
                print("❌ Error listing bundle contents: \(error)")
            }
        }
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
