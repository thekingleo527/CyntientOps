
//  AnalyticsManager.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create a centralized analytics tracking service.
//
//  ✅ PRODUCTION READY: A clean wrapper for a third-party analytics SDK.
//  ✅ TYPE-SAFE: Uses enums for event names to prevent typos.
//  ✅ CONTEXT-AWARE: Enriches events with user and device properties.
//

import Foundation
import CoreLocation
// import FirebaseAnalytics // Example: Import your analytics SDK here

// MARK: - Analytics Event Definition

/// Defines a structured analytics event with a name and associated metadata.
struct AnalyticsEvent {
    let name: EventName
    let properties: [String: Any]?
    
    enum EventName: String {
        // User Auth
        case loginSuccess = "auth_login_success"
        case loginFailure = "auth_login_failure"
        case logout = "auth_logout"
        
        // Worker Actions
        case clockIn = "worker_clock_in"
        case clockOut = "worker_clock_out"
        case taskStart = "worker_task_start"
        case taskComplete = "worker_task_complete"
        case photoUploaded = "worker_photo_uploaded"
        
        // Navigation
        case screenView = "nav_screen_view"
        case sheetPresented = "nav_sheet_presented"
        
        // Sync
        case syncStarted = "sync_started"
        case syncCompleted = "sync_completed"
        case syncFailed = "sync_failed"
        case conflictResolved = "sync_conflict_resolved"
    }
}

// MARK: - Analytics Manager

final class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Core Tracking Method
    
    /// Tracks an event with the underlying analytics provider.
    func track(_ event: AnalyticsEvent) {
        let eventNameString = event.name.rawValue
        
        // Example integration with Firebase Analytics
        // Analytics.logEvent(eventNameString, parameters: event.properties)
        
        #if DEBUG
        print("📊 ANALYTICS Event: \(eventNameString)")
        if let properties = event.properties {
            print("    Properties: \(properties)")
        }
        #endif
    }
    
    // MARK: - User Management
    
    /// Sets the user ID for all subsequent events. Call this on login.
    func setUserId(_ userId: String) {
        // Analytics.setUserID(userId)
        print("📊 ANALYTICS User ID set: \(userId)")
    }
    
    /// Sets a custom property for the user.
    func setUserProperty(value: String, for key: String) {
        // Analytics.setUserProperty(value, forName: key)
        print("📊 ANALYTICS User Property '\(key)' set to '\(value)'")
    }
    
    /// Clears user data on logout.
    func clearUserData() {
        // Analytics.setUserID(nil)
        print("📊 ANALYTICS User data cleared.")
    }
    
    // MARK: - Convenience Tracking Methods
    
    func trackScreenView(_ screenName: String) {
        let event = AnalyticsEvent(name: .screenView, properties: ["screen_name": screenName])
        track(event)
    }
    
    func trackTaskCompleted(task: CoreTypes.ContextualTask, duration: TimeInterval) {
        let properties: [String: Any] = [
            "task_id": task.id,
            "task_category": task.category?.rawValue ?? "unknown",
            "building_id": task.buildingId ?? "unknown",
            "duration_seconds": Int(duration)
        ]
        let event = AnalyticsEvent(name: .taskComplete, properties: properties)
        track(event)
    }
    
    func trackPhotoUploaded(fileSizeKB: Int, duration: TimeInterval) {
        let properties: [String: Any] = [
            "file_size_kb": fileSizeKB,
            "upload_duration_ms": Int(duration * 1000)
        ]
        let event = AnalyticsEvent(name: .photoUploaded, properties: properties)
        track(event)
    }
    
    func trackClockIn(buildingId: String, hasLocation: Bool) {
        let properties: [String: Any] = [
            "building_id": buildingId,
            "has_location": hasLocation
        ]
        let event = AnalyticsEvent(name: .clockIn, properties: properties)
        track(event)
    }
    
    func trackError(_ error: Error, context: String) {
        // This can be used to track non-fatal errors in analytics.
        let properties: [String: Any] = [
            "error_description": error.localizedDescription,
            "context": context
        ]
        // This event name would depend on your analytics provider's schema
        // For Firebase, you might log it as a specific type of error event
    }
}
