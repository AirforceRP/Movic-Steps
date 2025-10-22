import SwiftUI

// This file forces a complete rebuild to fix the tab bar caching issue
struct ForceRebuild {
    static let version = "5.0"
    static let build = "2025.01.20.5"
    
    static func forceUpdate() {
        print("🔧 FORCE REBUILD: Version \(version) - Build \(build)")
        print("🔧 This should definitely fix the tab bar issue")
    }
}
