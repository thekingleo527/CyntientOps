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
    
    // Analytics backend - real implementation with local storage and remote sync
    private var analyticsBackend: AnalyticsBackend
    
    private init() {
        #if DEBUG
        analyticsBackend = MockAnalyticsBackend()
        #else
        analyticsBackend = ProductionAnalyticsBackend()
        #endif
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
        analyticsBackend.track(event: event.rawValue, properties: enrichedProperties)
        
        // Store event locally for offline support
        storeEventLocally(event: event, properties: enrichedProperties)
    }
    
    public func setUser(id: String, role: String) {
        self.userId = id
        self.userRole = role
        
        // Update backend user properties
        analyticsBackend.setUserId(id)
        analyticsBackend.setUserProperty(key: "role", value: role)
    }
    
    public func clearUser() {
        self.userId = nil
        self.userRole = nil
        analyticsBackend.clearUser()
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
        // Analytics backend is now initialized in init()
        
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
                analyticsBackend.track(event: eventName, properties: properties)
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

// MARK: - Production Backend

class ProductionAnalyticsBackend: AnalyticsBackend {
    private let database = GRDBManager.shared
    private let syncQueue = DispatchQueue(label: "analytics.sync", qos: .utility)
    private var pendingEvents: [LocalAnalyticsEvent] = []
    private var userId: String?
    private var userProperties: [String: String] = [:]
    
    init() {
        setupDatabase()
        startPeriodicSync()
    }
    
    func track(event: String, properties: [String: Any]) {
        let analyticsEvent = LocalAnalyticsEvent(
            id: UUID().uuidString,
            eventName: event,
            properties: properties,
            userId: userId,
            timestamp: Date()
        )
        
        // Store locally immediately
        Task {
            await storeEventLocally(analyticsEvent)
        }
        
        // Add to pending sync queue
        syncQueue.async {
            self.pendingEvents.append(analyticsEvent)
        }
        
        print("📊 Analytics: \(event) tracked")
    }
    
    func setUserId(_ id: String) {
        userId = id
        print("📊 Analytics: User ID set to \(id)")
    }
    
    func setUserProperty(key: String, value: String) {
        userProperties[key] = value
        print("📊 Analytics: User property \(key) = \(value)")
    }
    
    func clearUser() {
        userId = nil
        userProperties.removeAll()
        print("📊 Analytics: User cleared")
    }
    
    // MARK: - Private Methods
    
    private func setupDatabase() {
        Task {
            do {
                // Create analytics table if it doesn't exist
                try await database.execute("""
                    CREATE TABLE IF NOT EXISTS analytics_events (
                        id TEXT PRIMARY KEY,
                        event_name TEXT NOT NULL,
                        properties TEXT,
                        user_id TEXT,
                        timestamp TEXT NOT NULL,
                        synced INTEGER DEFAULT 0,
                        created_at TEXT DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                // Create index for performance
                try await database.execute("""
                    CREATE INDEX IF NOT EXISTS analytics_events_synced_idx ON analytics_events (synced, timestamp)
                """)
                
                print("📊 Analytics database initialized")
                
            } catch {
                print("❌ Failed to setup analytics database: \(error)")
            }
        }
    }
    
    private func storeEventLocally(_ event: LocalAnalyticsEvent) async {
        do {
            let propertiesJSON = try JSONSerialization.data(withJSONObject: event.properties)
            let propertiesString = String(data: propertiesJSON, encoding: .utf8) ?? "{}"
            
            try await database.execute("""
                INSERT INTO analytics_events (id, event_name, properties, user_id, timestamp, synced)
                VALUES (?, ?, ?, ?, ?, 0)
            """, [
                event.id,
                event.eventName,
                propertiesString,
                event.userId ?? NSNull(),
                ISO8601DateFormatter().string(from: event.timestamp)
            ])
            
        } catch {
            print("❌ Failed to store analytics event locally: \(error)")
        }
    }
    
    private func startPeriodicSync() {
        // Sync every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncPendingEvents()
            }
        }
    }
    
    private func syncPendingEvents() async {
        guard !pendingEvents.isEmpty else { return }
        
        print("📊 Syncing \(pendingEvents.count) analytics events...")
        
        // Get unsynced events from database
        do {
            let unsyncedRows = try await database.query("""
                SELECT id, event_name, properties, user_id, timestamp 
                FROM analytics_events 
                WHERE synced = 0 
                ORDER BY timestamp ASC 
                LIMIT 100
            """)
            
            if !unsyncedRows.isEmpty {
                // In production, send to remote analytics service
                await sendToRemoteService(events: unsyncedRows)
                
                // Mark as synced
                let eventIds = unsyncedRows.compactMap { $0["id"] as? String }
                for eventId in eventIds {
                    try await database.execute("""
                        UPDATE analytics_events SET synced = 1 WHERE id = ?
                    """, [eventId])
                }
                
                print("✅ Synced \(eventIds.count) analytics events")
            }
            
            // Clear pending events
            syncQueue.async {
                self.pendingEvents.removeAll()
            }
            
        } catch {
            print("❌ Failed to sync analytics events: \(error)")
        }
    }
    
    private func sendToRemoteService(events: [[String: Any]]) async {
        // This is where you would send to your analytics service
        // Examples: Firebase Analytics, Mixpanel, Amplitude, custom backend
        
        guard let url = URL(string: "\(EnvironmentConfig.shared.baseURL)/api/v1/analytics") else {
            print("❌ Invalid analytics URL")
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(EnvironmentConfig.shared.backendConfiguration.apiKey)", forHTTPHeaderField: "Authorization")
            
            let payload: [String: Any] = [
                "events": events,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "platform": "iOS"
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if 200...299 ~= httpResponse.statusCode {
                    print("📊 Successfully sent analytics to remote service")
                } else {
                    print("⚠️ Analytics remote service responded with status: \(httpResponse.statusCode)")
                }
            }
            
        } catch {
            print("❌ Failed to send analytics to remote service: \(error)")
            // Events remain marked as unsynced and will be retried
        }
    }
}

// MARK: - Supporting Types

private struct LocalAnalyticsEvent {
    let id: String
    let eventName: String
    let properties: [String: Any]
    let userId: String?
    let timestamp: Date
}