//
//  AppVersion.swift
//  Movic Steps
//
//  Created to force rebuild
//

import Foundation

struct AppVersion {
    static let version = "2.1"
    static let build = "2025.01.20.2"
    
    static func logVersion() {
        print("🔧 App Version: \(version) - Build: \(build)")
        print("🔧 This should force a complete rebuild")
    }
}
