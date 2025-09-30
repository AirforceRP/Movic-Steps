//
//  WatchConnectivityManager.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/23/25.
//  9/23/25 - Created WatchConnectivity manager for iPhone-Apple Watch communication
//  250+ Lines of Code
//

import Foundation
import WatchConnectivity
import SwiftUI

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchAppInstalled = false
    @Published var isWatchReachable = false
    @Published var lastSyncDate: Date?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported on this device")
            return
        }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func sendDataToWatch(steps: Int, goal: Int, distance: Double, calories: Double, activeMinutes: Int) {
        guard WCSession.default.isReachable else {
            print("Apple Watch is not reachable")
            return
        }
        
        let data: [String: Any] = [
            "steps": steps,
            "goal": goal,
            "distance": distance,
            "calories": calories,
            "activeMinutes": activeMinutes,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(data, replyHandler: { response in
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                print("Data sent to Apple Watch successfully")
            }
        }, errorHandler: { error in
            print("Error sending data to Apple Watch: \(error.localizedDescription)")
        })
    }
    
    func sendGoalUpdateToWatch(goal: Int) {
        guard WCSession.default.isReachable else { return }
        
        let data: [String: Any] = [
            "type": "goal_update",
            "goal": goal,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(data, replyHandler: { response in
            print("Goal update sent to Apple Watch successfully")
        }, errorHandler: { error in
            print("Error sending goal update to Apple Watch: \(error.localizedDescription)")
        })
    }
    
    func sendNotificationToWatch(type: String, message: String, data: [String: Any] = [:]) {
        guard WCSession.default.isReachable else { return }
        
        var notificationData: [String: Any] = [
            "type": "notification",
            "notificationType": type,
            "message": message,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        notificationData.merge(data) { _, new in new }
        
        WCSession.default.sendMessage(notificationData, replyHandler: { response in
            print("Notification sent to Apple Watch successfully")
        }, errorHandler: { error in
            print("Error sending notification to Apple Watch: \(error.localizedDescription)")
        })
    }
    
    func requestDataFromWatch() {
        guard WCSession.default.isReachable else { return }
        
        let data: [String: Any] = [
            "type": "request_data",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(data, replyHandler: { response in
            DispatchQueue.main.async {
                self.handleWatchResponse(response)
            }
        }, errorHandler: { error in
            print("Error requesting data from Apple Watch: \(error.localizedDescription)")
        })
    }
    
    private func handleWatchResponse(_ response: [String: Any]) {
        // Handle response from Apple Watch
        if let steps = response["steps"] as? Int {
            print("Received steps from Apple Watch: \(steps)")
        }
        
        if let distance = response["distance"] as? Double {
            print("Received distance from Apple Watch: \(distance)")
        }
        
        // Update last sync date
        lastSyncDate = Date()
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = (activationState == .activated)
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = false
            self.isWatchReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = false
            self.isWatchReachable = false
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
            replyHandler(["status": "received"])
        }
    }
    
    private func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "data_update":
            handleDataUpdate(message)
        case "goal_achieved":
            handleGoalAchieved(message)
        case "request_sync":
            handleSyncRequest(message)
        default:
            break
        }
    }
    
    private func handleDataUpdate(_ message: [String: Any]) {
        // Handle data update from Apple Watch
        if let steps = message["steps"] as? Int {
            print("Apple Watch reported \(steps) steps")
        }
    }
    
    private func handleGoalAchieved(_ message: [String: Any]) {
        // Handle goal achieved notification from Apple Watch
        if let steps = message["steps"] as? Int, let goal = message["goal"] as? Int {
            print("Apple Watch: Goal achieved! \(steps)/\(goal) steps")
        }
    }
    
    private func handleSyncRequest(_ message: [String: Any]) {
        // Handle sync request from Apple Watch
        // This would typically trigger sending current data to the watch
        print("Apple Watch requested data sync")
    }
}

// MARK: - Watch Status View
struct WatchStatusView: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.blue)
                Text("Apple Watch")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Circle()
                    .fill(watchManager.isWatchReachable ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(watchManager.isWatchReachable ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastSync = watchManager.lastSyncDate {
                    Text("Last sync: \(lastSync, formatter: timeFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    WatchStatusView()
}
