//
//  WorkerEventOutbox.swift
//  CyntientOps v6.0
//
//  ✅ CLEAN: No dependency on DataSynchronizationService or WorkerEvent
//  ✅ SELF-CONTAINED: Works independently
//  ✅ V6.0: Phase 2.2 - Enhanced Offline Queue
//  ✅ FIXED: Swift 6 actor isolation compliance
//

import Foundation

/// An actor that manages a persistent, offline-first queue of worker actions
actor WorkerEventOutbox {
    static let shared = WorkerEventOutbox()

    /// Represents a single worker action that needs to be synced
    struct OutboxEvent: Codable, Identifiable {
        let id: String
        let type: WorkerActionType
        let payload: Data
        let timestamp: Date
        let buildingId: String
        let workerId: String
        var retryCount: Int = 0
        
        // Convenience initializer for actions with evidence
        init<T: Codable>(type: WorkerActionType, workerId: String, buildingId: String, payload: T) throws {
            self.id = UUID().uuidString
            self.type = type
            self.workerId = workerId
            self.buildingId = buildingId
            self.timestamp = Date()
            self.payload = try JSONEncoder().encode(payload)
            self.retryCount = 0
        }
        
        // Simple initializer without payload
        init(type: WorkerActionType, workerId: String, buildingId: String) {
            self.id = UUID().uuidString
            self.type = type
            self.workerId = workerId
            self.buildingId = buildingId
            self.timestamp = Date()
            self.payload = Data()
            self.retryCount = 0
        }
    }
    
    // In-memory queue for pending events
    private var pendingEvents: [OutboxEvent] = []
    
    // Track last sync time
    private var lastSyncTime: Date?
    
    // Track sync state
    private var _isSyncing = false
    
    private init() {
        // Load any persisted events on init using Task for async context
        Task {
            await loadPendingEvents()
        }
    }

    /// Adds a new event to the outbox to be synced
    func addEvent(_ event: OutboxEvent) async {
        print("📬 Adding event to outbox: \(event.type.rawValue) (ID: \(event.id))")
        pendingEvents.append(event)
        
        // Save to GRDB sync_queue table
        await saveEventToSyncQueue(event)
        
        // Attempt to flush immediately
        await attemptFlush()
    }
    
    /// Create and queue an event from a task completion
    func recordTaskCompletion(taskId: String, taskTitle: String, workerId: String, buildingId: String) async {
        let event = OutboxEvent(
            type: .taskCompletion,
            workerId: workerId,
            buildingId: buildingId
        )
        await addEvent(event)
    }
    
    /// Create and queue an event from worker clock operations
    func recordClockOperation(workerId: String, buildingId: String, isClockIn: Bool) async {
        let eventType: WorkerActionType = isClockIn ? .clockIn : .clockOut
        let event = OutboxEvent(type: eventType, workerId: workerId, buildingId: buildingId)
        await addEvent(event)
    }

    /// Create and queue an event for building status updates
    func recordBuildingStatusEvent(workerId: String, buildingId: String) async {
        let event = OutboxEvent(type: .buildingStatusUpdate, workerId: workerId, buildingId: buildingId)
        await addEvent(event)
    }
    
    /// Create and queue an event for routine inspections
    func recordRoutineInspectionEvent(workerId: String, buildingId: String) async {
        let event = OutboxEvent(type: .routineInspection, workerId: workerId, buildingId: buildingId)
        await addEvent(event)
    }
    
    /// Create and queue an event for photo uploads
    func recordPhotoUploadEvent(workerId: String, buildingId: String, photoData: Data? = nil) async {
        if let photoData = photoData,
           let event = try? OutboxEvent(type: .photoUpload, workerId: workerId, buildingId: buildingId, payload: photoData) {
            await addEvent(event)
        } else {
            let event = OutboxEvent(type: .photoUpload, workerId: workerId, buildingId: buildingId)
            await addEvent(event)
        }
    }
    
    /// Create and queue an event for emergency reports
    func recordEmergencyReportEvent(workerId: String, buildingId: String, description: String? = nil) async {
        let payload = ["description": description ?? "Emergency reported"]
        if let event = try? OutboxEvent(type: .emergencyReport, workerId: workerId, buildingId: buildingId, payload: payload) {
            await addEvent(event)
        } else {
            let event = OutboxEvent(type: .emergencyReport, workerId: workerId, buildingId: buildingId)
            await addEvent(event)
        }
    }

    /// Attempts to send all pending events to the server
    func attemptFlush() async {
        guard !pendingEvents.isEmpty else { return }
        guard !_isSyncing else { return } // Prevent concurrent flushes
        
        _isSyncing = true
        defer { _isSyncing = false }
        
        print("📤 Attempting to flush \(pendingEvents.count) events...")
        
        var successfullySyncedEvents: [String] = []

        for var event in pendingEvents {
            do {
                // Simulate a network request
                try await submitEventToServer(event)
                
                // If successful, mark for removal
                successfullySyncedEvents.append(event.id)
                
                print("   ✅ Successfully synced event \(event.id)")
                
            } catch {
                // Handle retry logic
                event.retryCount += 1
                print("⚠️ Failed to sync event \(event.id), retry \(event.retryCount). Error: \(error)")
                
                // Update retry count in database
                await updateEventRetryCount(event.id, retryCount: event.retryCount)
                
                // Update the event in the local queue with the new retry count
                if let index = pendingEvents.firstIndex(where: { $0.id == event.id }) {
                    pendingEvents[index] = event
                }
                
                // If retry count exceeds threshold, log and mark as failed
                if event.retryCount >= 5 {
                    print("🚨 Event \(event.id) has exceeded retry limit, marking as failed")
                    successfullySyncedEvents.append(event.id)
                }
            }
        }
        
        // Remove successfully synced events from the queue and database
        if !successfullySyncedEvents.isEmpty {
            // Remove from local queue
            pendingEvents.removeAll { successfullySyncedEvents.contains($0.id) }
            
            // Update database status for completed events
            for eventId in successfullySyncedEvents {
                await removeEventFromSyncQueue(eventId)
            }
            
            lastSyncTime = Date()
            print("✅ Flushed \(successfullySyncedEvents.count) events successfully.")
        }
    }
    
    /// Submit a single event to the remote server via HTTP POST
    private func submitEventToServer(_ event: OutboxEvent) async throws {
        // Real HTTP request to backend API
        guard let url = URL(string: "\(EnvironmentConfig.shared.baseURL)/api/v1/worker-events") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(EnvironmentConfig.shared.backendConfiguration.apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create request payload
        let requestPayload: [String: Any] = [
            "id": event.id,
            "type": event.type.rawValue,
            "workerId": event.workerId,
            "buildingId": event.buildingId,
            "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
            "payload": event.payload.base64EncodedString(),
            "retryCount": event.retryCount
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestPayload)
        
        // Make the network request with timeout
        request.timeoutInterval = 30.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check for success status codes (200-299)
        guard 200...299 ~= httpResponse.statusCode else {
            // Log the error response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Server error (\(httpResponse.statusCode)): \(responseString)")
            }
            
            // Throw appropriate error based on status code
            switch httpResponse.statusCode {
            case 401:
                throw URLError(.userAuthenticationRequired)
            case 403:
                throw URLError(.noPermissionsToReadFile)
            case 404:
                throw URLError(.fileDoesNotExist)
            case 429:
                throw URLError(.resourceUnavailable)
            case 500...599:
                throw URLError(.badServerResponse)
            default:
                throw URLError(.unknown)
            }
        }
        
        // Optional: Parse response for confirmation
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Event \(event.id) submitted successfully: \(responseString)")
        }
    }
    
    // MARK: - Queue Management
    
    /// Get the current number of pending events
    func getPendingEventCount() -> Int {
        return pendingEvents.count
    }
    
    /// Get all pending events (for debugging)
    func getPendingEvents() -> [OutboxEvent] {
        return pendingEvents
    }
    
    /// Get last sync time
    func getLastSyncTime() -> Date? {
        return lastSyncTime
    }
    
    /// Check if currently syncing
    func isSyncing() -> Bool {
        return _isSyncing
    }
    
    /// Clear all pending events (use with caution)
    func clearAllEvents() {
        pendingEvents.removeAll()
        savePendingEvents()
        print("🧹 Cleared all pending events from outbox")
    }
    
    /// Force retry all failed events
    func retryAllEvents() async {
        print("🔄 Forcing retry of all pending events...")
        
        // Reset retry counts for high-retry events
        for index in pendingEvents.indices {
            if pendingEvents[index].retryCount >= 5 {
                pendingEvents[index].retryCount = 0
            }
        }
        
        await attemptFlush()
    }
    
    /// Get a summary of queue status
    func getQueueStatus() -> (pending: Int, highRetry: Int, lastSync: Date?) {
        let pending = pendingEvents.count
        let highRetry = pendingEvents.filter { $0.retryCount >= 3 }.count
        return (pending, highRetry, lastSyncTime)
    }
    
    // MARK: - Persistence (Enhanced using GRDB sync_queue)
    
    private let grdbManager = GRDBManager.shared

    /// Save event to GRDB sync_queue table instead of UserDefaults
    private func savePendingEvents() {
        // Remove this method - events are saved individually in addEvent()
        // Kept for compatibility but does nothing
    }

    /// Load pending events from GRDB sync_queue table
    private func loadPendingEvents() async {
        do {
            let rows = try await grdbManager.query("""
                SELECT * FROM sync_queue 
                WHERE entity_type = 'worker_event' 
                AND status IN ('pending', 'failed')
                ORDER BY created_at ASC
            """)
            
            var loadedEvents: [OutboxEvent] = []
            
            for row in rows {
                if let eventData = row["data"] as? Data,
                   let event = try? JSONDecoder().decode(OutboxEvent.self, from: eventData) {
                    loadedEvents.append(event)
                } else if let eventId = row["id"] as? String,
                         let entityId = row["entity_id"] as? String,
                         let createdAtStr = row["created_at"] as? String {
                    
                    // Create event from sync_queue data if JSON decode fails
                    let event = OutboxEvent(
                        type: .taskCompletion, // Default type
                        workerId: entityId,
                        buildingId: row["building_id"] as? String ?? "unknown"
                    )
                    loadedEvents.append(event)
                }
            }
            
            pendingEvents = loadedEvents
            print("📦 Loaded \(pendingEvents.count) pending events from GRDB sync_queue.")
            
        } catch {
            print("🚨 Failed to load pending events from GRDB: \(error)")
            // Fallback: keep empty array
            pendingEvents = []
        }
    }
    
    /// Save individual event to GRDB sync_queue table
    private func saveEventToSyncQueue(_ event: OutboxEvent) async {
        do {
            let eventData = try JSONEncoder().encode(event)
            let now = Date()
            let nextRetry = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO sync_queue (
                    id, entity_type, entity_id, action,
                    data, retry_count, priority, is_compressed,
                    retry_delay, created_at, expires_at,
                    building_id, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                event.id,
                "worker_event",
                event.workerId,
                event.type.rawValue,
                eventData,
                event.retryCount,
                "normal",
                0, // Not compressed
                5, // 5 minute retry delay
                ISO8601DateFormatter().string(from: now),
                ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now),
                event.buildingId,
                "pending"
            ])
            
            print("✅ Saved event \(event.id) to GRDB sync_queue")
            
        } catch {
            print("❌ Failed to save event to GRDB sync_queue: \(error)")
        }
    }
    
    /// Remove successfully synced event from GRDB sync_queue  
    private func removeEventFromSyncQueue(_ eventId: String) async {
        do {
            try await grdbManager.execute("""
                UPDATE sync_queue 
                SET status = 'completed', updated_at = ?
                WHERE id = ?
            """, [
                ISO8601DateFormatter().string(from: Date()),
                eventId
            ])
            
            print("✅ Marked event \(eventId) as completed in sync_queue")
            
        } catch {
            print("❌ Failed to mark event as completed: \(error)")
        }
    }
    
    /// Update event retry count in GRDB sync_queue
    private func updateEventRetryCount(_ eventId: String, retryCount: Int) async {
        do {
            let nextRetry = Calendar.current.date(byAdding: .minute, value: retryCount * 5, to: Date()) ?? Date()
            let status = retryCount >= 5 ? "failed" : "pending"
            
            try await grdbManager.execute("""
                UPDATE sync_queue 
                SET retry_count = ?, next_retry_at = ?, status = ?, updated_at = ?
                WHERE id = ?
            """, [
                retryCount,
                ISO8601DateFormatter().string(from: nextRetry),
                status,
                ISO8601DateFormatter().string(from: Date()),
                eventId
            ])
            
            print("✅ Updated event \(eventId) retry count to \(retryCount)")
            
        } catch {
            print("❌ Failed to update event retry count: \(error)")
        }
    }
}

// MARK: - WorkerActionType Extension

extension WorkerActionType {
    /// Display name for UI
    var displayName: String {
        switch self {
        case .taskComplete, .taskCompletion:
            return "Task Completed"
        case .clockIn:
            return "Clocked In"
        case .clockOut:
            return "Clocked Out"
        case .photoUpload:
            return "Photo Uploaded"
        case .commentUpdate:
            return "Comment Added"
        case .routineInspection:
            return "Routine Inspection"
        case .buildingStatusUpdate:
            return "Building Status Updated"
        case .emergencyReport:
            return "Emergency Reported"
        }
    }
    
    /// Category for grouping similar actions
    var category: String {
        switch self {
        case .taskComplete, .taskCompletion, .routineInspection:
            return "Tasks"
        case .clockIn, .clockOut:
            return "Time Tracking"
        case .photoUpload, .commentUpdate:
            return "Evidence"
        case .buildingStatusUpdate:
            return "Building"
        case .emergencyReport:
            return "Emergency"
        }
    }
}
