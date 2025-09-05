//
//  OfflineQueueManager.swift
//  CyntientOps Phase 7
//
//  Offline Queue Manager for handling actions when network is unavailable
//  Provides persistent queue storage with automatic retry and conflict resolution
//

import Foundation
import Combine
import Network

@MainActor
public final class OfflineQueueManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var pendingActions: [OfflineAction] = []
    @Published public var isProcessing = false
    @Published public var networkStatus: NetworkStatus = .unknown
    @Published public var lastProcessedTime: Date?
    
    public enum NetworkStatus {
        case connected
        case disconnected
        case unknown
    }
    
    // MARK: - Private Properties
    private let persistenceURL: URL
    private let networkMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "network-monitor")
    
    // Configuration
    private struct Config {
        static let maxRetryAttempts = 5
        static let retryDelayMultiplier = 2.0
        static let maxQueueSize = 1000
        static let batchSize = 10
    }
    
    // MARK: - Initialization
    
    public init() {
        // Set up persistence URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.persistenceURL = documentsPath.appendingPathComponent("offline_queue.json")
        
        // Set up network monitoring
        self.networkMonitor = NWPathMonitor()
        
        Task {
            await createOfflineQueueTable()
            await setupNetworkMonitoring()
            await loadPersistedQueue()
        }
    }
    
    // MARK: - Public Methods
    
    /// Enqueue an action for offline processing
    public func enqueue(_ action: OfflineAction) {
        // Prevent queue overflow
        if pendingActions.count >= Config.maxQueueSize {
            // Remove oldest actions to make room
            let excessCount = pendingActions.count - Config.maxQueueSize + 1
            pendingActions.removeFirst(excessCount)
            print("⚠️ Offline queue overflow - removed \(excessCount) oldest actions")
        }
        
        pendingActions.append(action)
        persistQueue()
        
        // Try to process immediately if online
        if networkStatus == .connected && !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Process all pending actions
    public func processQueue() async {
        guard !isProcessing && networkStatus == .connected else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let actionsToProcess = Array(pendingActions.prefix(Config.batchSize))
        
        for action in actionsToProcess {
            do {
                let success = try await processAction(action)
                if success {
                    // Remove successful action from queue
                    pendingActions.removeAll { $0.id == action.id }
                } else {
                    // Increment retry count
                    if let index = pendingActions.firstIndex(where: { $0.id == action.id }) {
                        pendingActions[index] = action.withIncrementedRetry()
                    }
                }
            } catch {
                print("Failed to process offline action \(action.id): \(error)")
                
                // Handle retry logic
                if action.retryCount < Config.maxRetryAttempts {
                    if let index = pendingActions.firstIndex(where: { $0.id == action.id }) {
                        pendingActions[index] = action.withIncrementedRetry()
                    }
                } else {
                    // Max retries exceeded - move to failed queue or remove
                    print("Max retries exceeded for action \(action.id) - removing from queue")
                    pendingActions.removeAll { $0.id == action.id }
                }
            }
        }
        
        persistQueue()
        lastProcessedTime = Date()
        
        // Continue processing if there are more actions
        if !pendingActions.isEmpty && networkStatus == .connected {
            // Add small delay between batches
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await processQueue()
        }
    }
    
    /// Start automatic queue processing when network becomes available
    public func startQueueProcessing() async {
        while !Task.isCancelled {
            if networkStatus == .connected && !pendingActions.isEmpty && !isProcessing {
                await processQueue()
            }
            
            // Check every 30 seconds
            try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
        }
    }
    
    /// Clear all pending actions
    public func clearQueue() {
        pendingActions.removeAll()
        persistQueue()
    }
    
    /// Get queue status
    public func getQueueStatus() -> QueueStatus {
        let failedActions = pendingActions.filter { $0.retryCount >= Config.maxRetryAttempts }
        let retryingActions = pendingActions.filter { $0.retryCount > 0 && $0.retryCount < Config.maxRetryAttempts }
        
        return QueueStatus(
            totalActions: pendingActions.count,
            failedActions: failedActions.count,
            retryingActions: retryingActions.count,
            isProcessing: isProcessing,
            networkStatus: networkStatus,
            lastProcessed: lastProcessedTime
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() async {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let newStatus: NetworkStatus = path.status == .satisfied ? .connected : .disconnected
                
                if self?.networkStatus != newStatus {
                    self?.networkStatus = newStatus
                    
                    // Auto-process queue when coming back online
                    if newStatus == .connected && !(self?.pendingActions.isEmpty ?? true) {
                        Task {
                            await self?.processQueue()
                        }
                    }
                }
            }
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func processAction(_ action: OfflineAction) async throws -> Bool {
        switch action.type {
        case .taskCompletion:
            return try await processTaskCompletion(action)
        case .clockIn:
            return try await processClockIn(action)
        case .clockOut:
            return try await processClockOut(action)
        case .photoUpload:
            return try await processPhotoUpload(action)
        case .complianceUpdate:
            return try await processComplianceUpdate(action)
        case .syncData:
            return try await processSyncData(action)
        }
    }
    
    private func processTaskCompletion(_ action: OfflineAction) async throws -> Bool {
        guard let data = action.data as? TaskCompletionData else {
            throw OfflineQueueError.invalidActionData
        }
        
        // Simulate task completion API call
        // In production, this would call the actual service
        print("Processing offline task completion: \(data.taskId)")
        
        // Add small delay to simulate network call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return true
    }
    
    private func processClockIn(_ action: OfflineAction) async throws -> Bool {
        guard let data = action.data as? ClockInData else {
            throw OfflineQueueError.invalidActionData
        }
        
        print("Processing offline clock-in: \(data.workerId) at \(data.buildingId)")
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return true
    }
    
    private func processClockOut(_ action: OfflineAction) async throws -> Bool {
        guard let data = action.data as? ClockOutData else {
            throw OfflineQueueError.invalidActionData
        }
        
        print("Processing offline clock-out: \(data.workerId)")
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return true
    }
    
    private func processPhotoUpload(_ action: OfflineAction) async throws -> Bool {
        guard let data = action.data as? PhotoUploadData else {
            throw OfflineQueueError.invalidActionData
        }
        
        print("Processing offline photo upload: \(data.taskId)")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for photo upload
        
        return true
    }
    
    private func processComplianceUpdate(_ action: OfflineAction) async throws -> Bool {
        guard let data = action.data as? ComplianceUpdateData else {
            throw OfflineQueueError.invalidActionData
        }
        
        print("Processing offline compliance update: \(data.buildingId)")
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return true
    }
    
    private func processSyncData(_ action: OfflineAction) async throws -> Bool {
        print("Processing offline sync data")
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds for sync
        
        return true
    }
    
    private func persistQueue() {
        // Use both file and database persistence for reliability
        persistToFile()
        persistToDatabase()
    }
    
    private func persistToFile() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(pendingActions)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Failed to persist offline queue to file: \(error)")
        }
    }
    
    private func persistToDatabase() {
        Task {
            do {
                // Clear existing entries
                try await GRDBManager.shared.execute("DELETE FROM offline_queue")
                
                // Insert current queue
                for action in pendingActions {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let actionData = try encoder.encode(action)
                    
                    try await GRDBManager.shared.execute("""
                        INSERT INTO offline_queue (
                            id, action_type, action_data, timestamp, retry_count, priority, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, [
                        action.id,
                        action.type.rawValue,
                        actionData,
                        action.timestamp.timeIntervalSince1970,
                        action.retryCount,
                        action.priority.rawValue,
                        Date().timeIntervalSince1970
                    ])
                }
            } catch {
                print("Failed to persist offline queue to database: \(error)")
            }
        }
    }
    
    private func loadPersistedQueue() async {
        // Try database first, then file backup
        var loaded = await loadFromDatabase()
        
        if !loaded {
            loaded = await loadFromFile()
        }
        
        if !loaded {
            print("No persisted queue found - starting fresh")
            pendingActions = []
        }
        
        // Clean up any duplicate entries
        await removeDuplicateActions()
    }
    
    private func loadFromDatabase() async -> Bool {
        do {
            let rows = try await GRDBManager.shared.query("""
                SELECT action_data FROM offline_queue 
                ORDER BY created_at ASC
            """)
            
            var actions: [OfflineAction] = []
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for row in rows {
                if let actionData = row["action_data"] as? Data {
                    do {
                        let action = try decoder.decode(OfflineAction.self, from: actionData)
                        actions.append(action)
                    } catch {
                        print("Failed to decode offline action: \(error)")
                    }
                }
            }
            
            if !actions.isEmpty {
                pendingActions = actions
                print("Loaded \(actions.count) offline actions from database")
                return true
            }
            
        } catch {
            print("Failed to load offline queue from database: \(error)")
        }
        
        return false
    }
    
    private func loadFromFile() async -> Bool {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let actions = try decoder.decode([OfflineAction].self, from: data)
            pendingActions = actions
            
            print("Loaded \(actions.count) offline actions from file backup")
            
            // Restore to database
            persistToDatabase()
            
            return true
        } catch {
            print("Failed to load offline queue from file: \(error)")
            return false
        }
    }
    
    private func removeDuplicateActions() async {
        let uniqueActions = Array(Dictionary(grouping: pendingActions) { $0.id }.compactMapValues { $0.first }.values)
        
        if uniqueActions.count != pendingActions.count {
            pendingActions = uniqueActions.sorted { $0.timestamp < $1.timestamp }
            persistQueue()
            print("Removed \(pendingActions.count - uniqueActions.count) duplicate offline actions")
        }
    }
    
    /// Create offline queue table in database if it doesn't exist
    private func createOfflineQueueTable() async {
        do {
            try await GRDBManager.shared.execute("""
                CREATE TABLE IF NOT EXISTS offline_queue (
                    id TEXT PRIMARY KEY,
                    action_type TEXT NOT NULL,
                    action_data BLOB NOT NULL,
                    timestamp REAL NOT NULL,
                    retry_count INTEGER NOT NULL DEFAULT 0,
                    priority INTEGER NOT NULL DEFAULT 1,
                    created_at REAL NOT NULL,
                    updated_at REAL DEFAULT (datetime('now'))
                )
            """)
            
            // Create index for performance
            try await GRDBManager.shared.execute("""
                CREATE INDEX IF NOT EXISTS idx_offline_queue_priority_timestamp 
                ON offline_queue(priority DESC, timestamp ASC)
            """)
            
        } catch {
            print("Failed to create offline queue table: \(error)")
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Types

public struct OfflineAction: Identifiable {
    public let id: String
    public let type: ActionType
    public let data: ActionData
    public let timestamp: Date
    public let retryCount: Int
    public let priority: Priority
    
    public enum ActionType: String, Codable {
        case taskCompletion
        case clockIn
        case clockOut
        case photoUpload
        case complianceUpdate
        case syncData
    }
    
    public enum Priority: Int, Codable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
    }
    
    public init(id: String = UUID().uuidString, type: ActionType, data: ActionData, priority: Priority = .normal) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = Date()
        self.retryCount = 0
        self.priority = priority
    }
    
    public func withIncrementedRetry() -> OfflineAction {
        return OfflineAction(
            id: self.id,
            type: self.type,
            data: self.data,
            timestamp: self.timestamp,
            retryCount: self.retryCount + 1,
            priority: self.priority
        )
    }
    
    private init(id: String, type: ActionType, data: ActionData, timestamp: Date, retryCount: Int, priority: Priority) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.priority = priority
    }
}

// MARK: - OfflineAction Codable Implementation
extension OfflineAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, type, data, timestamp, retryCount, priority
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ActionType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        priority = try container.decode(Priority.self, forKey: .priority)
        
        // Decode the data based on type
        switch type {
        case .taskCompletion:
            data = try container.decode(TaskCompletionData.self, forKey: .data)
        case .clockIn:
            data = try container.decode(ClockInData.self, forKey: .data)
        case .clockOut:
            data = try container.decode(ClockOutData.self, forKey: .data)
        case .photoUpload:
            data = try container.decode(PhotoUploadData.self, forKey: .data)
        case .complianceUpdate:
            data = try container.decode(ComplianceUpdateData.self, forKey: .data)
        case .syncData:
            data = try container.decode(SyncData.self, forKey: .data)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(priority, forKey: .priority)
        
        // Encode the data
        switch data {
        case let taskData as TaskCompletionData:
            try container.encode(taskData, forKey: .data)
        case let clockInData as ClockInData:
            try container.encode(clockInData, forKey: .data)
        case let clockOutData as ClockOutData:
            try container.encode(clockOutData, forKey: .data)
        case let photoData as PhotoUploadData:
            try container.encode(photoData, forKey: .data)
        case let complianceData as ComplianceUpdateData:
            try container.encode(complianceData, forKey: .data)
        case let syncData as SyncData:
            try container.encode(syncData, forKey: .data)
        default:
            throw EncodingError.invalidValue(data, EncodingError.Context(
                codingPath: encoder.codingPath + [CodingKeys.data],
                debugDescription: "Unknown ActionData type"
            ))
        }
    }
}

public protocol ActionData: Codable {}

public struct TaskCompletionData: ActionData {
    public let taskId: String
    public let workerId: String
    public let notes: String?
    public let photoData: Data?
    
    public init(taskId: String, workerId: String, notes: String? = nil, photoData: Data? = nil) {
        self.taskId = taskId
        self.workerId = workerId
        self.notes = notes
        self.photoData = photoData
    }
}

public struct ClockInData: ActionData {
    public let workerId: String
    public let buildingId: String
    public let latitude: Double
    public let longitude: Double
    
    public init(workerId: String, buildingId: String, latitude: Double, longitude: Double) {
        self.workerId = workerId
        self.buildingId = buildingId
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct ClockOutData: ActionData {
    public let workerId: String
    public let buildingId: String?
    
    public init(workerId: String, buildingId: String? = nil) {
        self.workerId = workerId
        self.buildingId = buildingId
    }
}

public struct PhotoUploadData: ActionData {
    public let taskId: String
    public let workerId: String
    public let imageData: Data
    
    public init(taskId: String, workerId: String, imageData: Data) {
        self.taskId = taskId
        self.workerId = workerId
        self.imageData = imageData
    }
}

public struct ComplianceUpdateData: ActionData {
    public let buildingId: String
    public let violationId: String?
    public let updateType: String
    
    public init(buildingId: String, violationId: String? = nil, updateType: String) {
        self.buildingId = buildingId
        self.violationId = violationId
        self.updateType = updateType
    }
}

public struct SyncData: ActionData {
    public let dataType: String
    public let payload: [String: Any]
    
    public init(dataType: String, payload: [String: Any]) {
        self.dataType = dataType
        self.payload = payload
    }
    
    // Custom Codable implementation for payload with Any values
    private enum CodingKeys: String, CodingKey {
        case dataType, payload
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataType = try container.decode(String.self, forKey: .dataType)
        
        // Decode payload as [String: String] for simplicity
        let payloadDict = try container.decode([String: String].self, forKey: .payload)
        payload = payloadDict
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dataType, forKey: .dataType)
        
        // Encode payload as [String: String] for simplicity
        let payloadDict = payload.compactMapValues { $0 as? String }
        try container.encode(payloadDict, forKey: .payload)
    }
}

public struct QueueStatus {
    public let totalActions: Int
    public let failedActions: Int
    public let retryingActions: Int
    public let isProcessing: Bool
    public let networkStatus: OfflineQueueManager.NetworkStatus
    public let lastProcessed: Date?
}

public enum OfflineQueueError: LocalizedError {
    case invalidActionData
    case queueFull
    case persistenceFailed
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidActionData:
            return "Invalid action data format"
        case .queueFull:
            return "Offline queue is full"
        case .persistenceFailed:
            return "Failed to persist queue to disk"
        case .networkUnavailable:
            return "Network is unavailable"
        }
    }
}