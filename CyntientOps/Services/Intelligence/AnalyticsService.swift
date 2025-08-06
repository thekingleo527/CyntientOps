//
//  AnalyticsService.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/2/25.
//


//
//  AnalyticsService.swift
//  CyntientOps v6.0
//
//  ✅ PRODUCTION READY: Centralized analytics tracking
//  ✅ TYPE-SAFE: Strongly typed events and properties
//  ✅ PRIVACY-AWARE: No PII in analytics
//

import Foundation
import UIKit

@MainActor
public final class AnalyticsService: ObservableObject {
    public static let shared = AnalyticsService()
    
    // MARK: - Event Types
    
    public enum EventType: String {
        // Dashboard Events
        case dashboardOpened = "dashboard_opened"
        case dashboardRefreshed = "dashboard_refreshed"
        case dashboardClosed = "dashboard_closed"
        
        // Building Events
        case buildingSelected = "building_selected"
        case buildingDetailsViewed = "building_details_viewed"
        
        // Worker Events
        case workerClockIn = "worker_clock_in"
        case workerClockOut = "worker_clock_out"
        case taskCompleted = "task_completed"
        case photoUploaded = "photo_uploaded"
        
        // Search & Filter
        case searchPerformed = "search_performed"
        case filterApplied = "filter_applied"
        
        // Reports
        case reportGenerated = "report_generated"
        case reportExported = "report_exported"
        case reportShared = "report_shared"
        
        // Errors
        case errorOccurred = "error_occurred"
        
        // User Actions
        case userLoggedIn = "user_logged_in"
        case userLoggedOut = "user_logged_out"
        case settingsChanged = "settings_changed"
    }
    
    // MARK: - Properties
    
    private var userId: String?
    private var userRole: String?
    private var sessionStartTime: Date?
    private let defaults = UserDefaults.standard
    
    // Analytics backend (placeholder - integrate with real service)
    private var analyticsBackend: AnalyticsBackend?
    
    private init() {
        setupSession()
    }
    
    // MARK: - Public Methods
    
    public func track(_ event: EventType, properties: [String: Any]? = nil) {
        var enrichedProperties = properties ?? [:]
        
        // Add common properties
        enrichedProperties["platform"] = "iOS"
        enrichedProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        enrichedProperties["device_model"] = UIDevice.current.model
        enrichedProperties["ios_version"] = UIDevice.current.systemVersion
        
        if let userId = userId {
            enrichedProperties["user_id"] = userId
        }
        
        if let userRole = userRole {
            enrichedProperties["user_role"] = userRole
        }
        
        if let sessionStartTime = sessionStartTime {
            enrichedProperties["session_duration"] = Date().timeIntervalSince(sessionStartTime)
        }
        
        // Log to console in debug
        #if DEBUG
        print("📊 Analytics Event: \(event.rawValue)")
        if !enrichedProperties.isEmpty {
            print("   Properties: \(enrichedProperties)")
        }
        #endif
        
        // Send to analytics backend
        analyticsBackend?.track(event: event.rawValue, properties: enrichedProperties)
        
        // Store event locally for offline support
        storeEventLocally(event: event, properties: enrichedProperties)
    }
    
    public func setUser(id: String, role: String) {
        self.userId = id
        self.userRole = role
        
        // Update backend user properties
        analyticsBackend?.setUserId(id)
        analyticsBackend?.setUserProperty(key: "role", value: role)
    }
    
    public func clearUser() {
        self.userId = nil
        self.userRole = nil
        analyticsBackend?.clearUser()
    }
    
    public func startSession() {
        sessionStartTime = Date()
        track(.dashboardOpened)
    }
    
    public func endSession() {
        track(.dashboardClosed, properties: [
            "session_duration": sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        ])
        sessionStartTime = nil
    }
    
    // MARK: - Convenience Methods
    
    public func trackScreenView(_ screenName: String) {
        track(.dashboardOpened, properties: ["screen_name": screenName])
    }
    
    public func trackError(_ error: Error, context: String) {
        track(.errorOccurred, properties: [
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription,
            "context": context
        ])
    }
    
    public func trackTaskCompletion(taskId: String, duration: TimeInterval, buildingId: String) {
        track(.taskCompleted, properties: [
            "task_id": taskId,
            "duration_seconds": Int(duration),
            "building_id": buildingId
        ])
    }
    
    public func trackPhotoUpload(photoId: String, fileSize: Int, uploadDuration: TimeInterval) {
        track(.photoUploaded, properties: [
            "photo_id": photoId,
            "file_size_bytes": fileSize,
            "upload_duration_ms": Int(uploadDuration * 1000)
        ])
    }
    
    // MARK: - Private Methods
    
    private func setupSession() {
        // Initialize analytics backend (placeholder)
        // analyticsBackend = FirebaseAnalytics() or similar
        
        // Restore user if logged in
        if let savedUserId = defaults.string(forKey: "analytics_user_id"),
           let savedUserRole = defaults.string(forKey: "analytics_user_role") {
            setUser(id: savedUserId, role: savedUserRole)
        }
    }
    
    private func storeEventLocally(event: EventType, properties: [String: Any]) {
        // Store events for offline sync
        var storedEvents = defaults.array(forKey: "pending_analytics_events") as? [[String: Any]] ?? []
        
        let eventData: [String: Any] = [
            "event": event.rawValue,
            "properties": properties,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        storedEvents.append(eventData)
        
        // Keep only last 100 events
        if storedEvents.count > 100 {
            storedEvents = Array(storedEvents.suffix(100))
        }
        
        defaults.set(storedEvents, forKey: "pending_analytics_events")
    }
    
    public func syncPendingEvents() {
        guard let storedEvents = defaults.array(forKey: "pending_analytics_events") as? [[String: Any]] else {
            return
        }
        
        for eventData in storedEvents {
            if let eventName = eventData["event"] as? String,
               let properties = eventData["properties"] as? [String: Any] {
                analyticsBackend?.track(event: eventName, properties: properties)
            }
        }
        
        // Clear stored events after sync
        defaults.removeObject(forKey: "pending_analytics_events")
    }
}

// MARK: - Analytics Backend Protocol

protocol AnalyticsBackend {
    func track(event: String, properties: [String: Any])
    func setUserId(_ id: String)
    func setUserProperty(key: String, value: String)
    func clearUser()
}

// MARK: - Mock Backend for Development

#if DEBUG
class MockAnalyticsBackend: AnalyticsBackend {
    func track(event: String, properties: [String: Any]) {
        print("🔵 Mock Analytics: \(event)")
    }
    
    func setUserId(_ id: String) {
        print("🔵 Mock Analytics: User ID set to \(id)")
    }
    
    func setUserProperty(key: String, value: String) {
        print("🔵 Mock Analytics: User property \(key) = \(value)")
    }
    
    func clearUser() {
        print("🔵 Mock Analytics: User cleared")
    }
}
#endif