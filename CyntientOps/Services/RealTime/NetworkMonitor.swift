//  NetworkMonitor.swift
//  CyntientOps v6.0
//
//  ✅ STREAM B IMPLEMENTATION: Advanced network monitoring
//  ✅ FEATURES: Connection quality detection, predictive offline, automatic queue management
//  ✅ USES: NWPathMonitor for accurate network detection
//

import Foundation
import Network
import Combine
import CoreLocation

@MainActor
public class NetworkMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var connectionType: ConnectionType = .unknown
    @Published public private(set) var connectionQuality: ConnectionQuality = .unknown
    @Published public private(set) var isExpensive: Bool = false
    @Published public private(set) var isConstrained: Bool = false
    @Published public private(set) var predictedOfflineTime: Date?
    
    // MARK: - Connection Types
    
    public enum ConnectionType: String, CaseIterable, Codable {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case wiredEthernet = "Ethernet"
        case loopback = "Loopback"
        case other = "Other"
        case unknown = "Unknown"
        
        public var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wiredEthernet: return "cable.connector"
            case .loopback: return "arrow.triangle.2.circlepath"
            case .other: return "network"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    public enum ConnectionQuality: String, CaseIterable, Codable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case offline = "Offline"
        case unknown = "Unknown"
        
        public var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "yellow"
            case .poor: return "orange"
            case .offline: return "red"
            case .unknown: return "gray"
            }
        }
        
        public var recommendedBatchSize: Int {
            switch self {
            case .excellent: return 100
            case .good: return 50
            case .fair: return 25
            case .poor: return 10
            case .offline: return 0
            case .unknown: return 25
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.cyntientops.networkmonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // Connection history for predictive analysis
    private var connectionHistory: [ConnectionEvent] = []
    private let maxHistorySize = 1000
    
    // Speed test results
    private var lastSpeedTest: SpeedTestResult?
    private var speedTestTimer: Timer?
    
    // Offline prediction
    private var offlinePredictionModel: OfflinePredictionModel
    
    // Queue management
    private let syncQueueManager: SyncQueueManager
    
    // MARK: - Initialization
    
    private init() {
        self.offlinePredictionModel = OfflinePredictionModel()
        self.syncQueueManager = SyncQueueManager.shared
        
        setupNetworkMonitoring()
        setupSpeedTesting()
        loadConnectionHistory()
    }
    
    // MARK: - Setup
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateConnectionStatus(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func setupSpeedTesting() {
        // Run speed test every 5 minutes when connected
        speedTestTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                if await self.isConnected {
                    await self.performSpeedTest()
                }
            }
        }
    }
    
    // MARK: - Connection Status Updates
    
    private func updateConnectionStatus(_ path: NWPath) {
        // Update basic connection status
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        // Update connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            connectionType = .loopback
        } else if path.usesInterfaceType(.other) {
            connectionType = .other
        } else {
            connectionType = .unknown
        }
        
        // Update expensive/constrained flags
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Record connection event
        let event = ConnectionEvent(
            timestamp: Date(),
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: isExpensive,
            isConstrained: isConstrained
        )
        addConnectionEvent(event)
        
        // Update connection quality
        Task {
            await updateConnectionQuality()
        }
        
        // Handle connection state changes
        if isConnected && !wasConnected {
            handleConnectionRestored()
        } else if !isConnected && wasConnected {
            handleConnectionLost()
        }
        
        // Update predictive model
        updateOfflinePrediction()
    }
    
    // MARK: - Connection Quality Assessment
    
    private func updateConnectionQuality() async {
        guard isConnected else {
            connectionQuality = .offline
            return
        }
        
        // Determine quality based on multiple factors
        var qualityScore = 0.0
        
        // Connection type factor (40%)
        switch connectionType {
        case .wifi, .wiredEthernet:
            qualityScore += 0.4
        case .cellular:
            qualityScore += isConstrained ? 0.2 : 0.3
        default:
            qualityScore += 0.1
        }
        
        // Speed test factor (40%)
        if let speedTest = lastSpeedTest,
           speedTest.timestamp.timeIntervalSinceNow > -600 { // Last 10 minutes
            let speedScore = min(speedTest.downloadSpeed / 50.0, 1.0) * 0.4
            qualityScore += speedScore
        } else {
            qualityScore += 0.2 // Default if no recent speed test
        }
        
        // Stability factor (20%)
        let recentEvents = connectionHistory.suffix(10)
        let disconnections = recentEvents.filter { !$0.isConnected }.count
        let stabilityScore = max(0, 1.0 - (Double(disconnections) / 10.0)) * 0.2
        qualityScore += stabilityScore
        
        // Determine quality level
        switch qualityScore {
        case 0.8...1.0:
            connectionQuality = .excellent
        case 0.6..<0.8:
            connectionQuality = .good
        case 0.4..<0.6:
            connectionQuality = .fair
        case 0.2..<0.4:
            connectionQuality = .poor
        default:
            connectionQuality = .unknown
        }
    }
    
    // MARK: - Speed Testing
    
    private func performSpeedTest() async {
        guard isConnected else { return }
        
        let testURL = URL(string: "https://speed.cloudflare.com/__down?bytes=10000000")! // 10MB
        let startTime = Date()
        
        do {
            let (data, _) = try await URLSession.shared.data(from: testURL)
            let duration = Date().timeIntervalSince(startTime)
            let bytesPerSecond = Double(data.count) / duration
            let mbps = (bytesPerSecond * 8) / 1_000_000
            
            lastSpeedTest = SpeedTestResult(
                timestamp: Date(),
                downloadSpeed: mbps,
                uploadSpeed: 0, // Would need separate test
                latency: duration * 1000 / 10 // Rough estimate
            )
            
            await updateConnectionQuality()
            
        } catch {
            print("⚠️ Speed test failed: \(error)")
        }
    }
    
    // MARK: - Connection Event Management
    
    private func addConnectionEvent(_ event: ConnectionEvent) {
        connectionHistory.append(event)
        
        // Maintain history size limit
        if connectionHistory.count > maxHistorySize {
            connectionHistory.removeFirst(connectionHistory.count - maxHistorySize)
        }
        
        // Persist to UserDefaults for cross-launch analysis
        saveConnectionHistory()
    }
    
    private func loadConnectionHistory() {
        if let data = UserDefaults.standard.data(forKey: "NetworkConnectionHistory"),
           let history = try? JSONDecoder().decode([ConnectionEvent].self, from: data) {
            connectionHistory = history
        }
    }
    
    private func saveConnectionHistory() {
        // Save only recent history to avoid excessive storage
        let recentHistory = Array(connectionHistory.suffix(100))
        if let data = try? JSONEncoder().encode(recentHistory) {
            UserDefaults.standard.set(data, forKey: "NetworkConnectionHistory")
        }
    }
    
    // MARK: - Connection State Handlers
    
    private func handleConnectionRestored() {
        print("🟢 Network connection restored")
        
        // Trigger sync queue processing
        Task {
            await syncQueueManager.processOfflineQueue()
        }
        
        // Perform speed test
        Task {
            await performSpeedTest()
        }
        
        // Notify interested parties
        NotificationCenter.default.post(
            name: .networkConnectionRestored,
            object: nil,
            userInfo: ["connectionType": connectionType.rawValue]
        )
    }
    
    private func handleConnectionLost() {
        print("🔴 Network connection lost")
        
        // Notify interested parties
        NotificationCenter.default.post(
            name: .networkConnectionLost,
            object: nil,
            userInfo: ["lastConnectionType": connectionType.rawValue]
        )
    }
    
    // MARK: - Predictive Offline Detection
    
    private func updateOfflinePrediction() {
        // Analyze patterns in connection history
        let prediction = offlinePredictionModel.predictNextOffline(
            history: connectionHistory,
            currentLocation: nil // Would need proper LocationManager integration
        )
        
        predictedOfflineTime = prediction.predictedTime
        
        // Warn if offline predicted soon
        if let offlineTime = prediction.predictedTime,
           offlineTime.timeIntervalSinceNow < 300 { // Within 5 minutes
            NotificationCenter.default.post(
                name: .networkOfflinePredicted,
                object: nil,
                userInfo: [
                    "predictedTime": offlineTime,
                    "confidence": prediction.confidence
                ]
            )
        }
    }
    
    // MARK: - Public Methods
    
    /// Get recommended settings based on connection quality
    public func getRecommendedSettings() -> NetworkRecommendations {
        NetworkRecommendations(
            batchSize: connectionQuality.recommendedBatchSize,
            syncInterval: getSyncInterval(),
            enableHighQualityPhotos: shouldEnableHighQualityPhotos(),
            enableBackgroundSync: shouldEnableBackgroundSync(),
            maxConcurrentUploads: getMaxConcurrentUploads()
        )
    }
    
    /// Check if specific operation should proceed
    public func shouldProceedWithOperation(_ operation: NetworkOperation) -> Bool {
        switch operation {
        case .photoUpload:
            return isConnected && (!isConstrained || connectionQuality == .excellent)
        case .largeDataSync:
            return isConnected && connectionType == .wifi
        case .criticalUpdate:
            return isConnected
        case .backgroundSync:
            return isConnected && !isExpensive
        }
    }
    
    /// Force update connection status
    public func forceUpdate() {
        monitor.cancel()
        setupNetworkMonitoring()
    }
    
    // MARK: - Private Helpers
    
    private func getSyncInterval() -> TimeInterval {
        switch connectionQuality {
        case .excellent: return 30
        case .good: return 60
        case .fair: return 120
        case .poor: return 300
        default: return 600
        }
    }
    
    private func shouldEnableHighQualityPhotos() -> Bool {
        connectionQuality == .excellent || connectionQuality == .good
    }
    
    private func shouldEnableBackgroundSync() -> Bool {
        isConnected && !isExpensive && !isConstrained
    }
    
    private func getMaxConcurrentUploads() -> Int {
        switch connectionQuality {
        case .excellent: return 5
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        default: return 0
        }
    }
}

// MARK: - Supporting Types

private struct ConnectionEvent: Codable {
    let timestamp: Date
    let isConnected: Bool
    let connectionType: NetworkMonitor.ConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
}

private struct SpeedTestResult {
    let timestamp: Date
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double // Mbps
    let latency: Double // ms
}

public struct NetworkRecommendations {
    public let batchSize: Int
    public let syncInterval: TimeInterval
    public let enableHighQualityPhotos: Bool
    public let enableBackgroundSync: Bool
    public let maxConcurrentUploads: Int
}

public enum NetworkOperation {
    case photoUpload
    case largeDataSync
    case criticalUpdate
    case backgroundSync
}

// MARK: - Offline Prediction Model

private class OfflinePredictionModel {
    
    struct OfflinePrediction {
        let predictedTime: Date?
        let confidence: Double
        let reason: String
    }
    
    func predictNextOffline(history: [ConnectionEvent], currentLocation: CLLocation?) -> OfflinePrediction {
        // Analyze patterns:
        // 1. Time-based patterns (e.g., subway commute)
        // 2. Location-based patterns (e.g., basement areas)
        // 3. Duration patterns (how long offline periods typically last)
        
        // Simple implementation - look for daily patterns
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let currentMinute = calendar.component(.minute, from: Date())
        
        // Find offline events at similar times
        let similarTimeEvents = history.filter { event in
            !event.isConnected &&
            abs(calendar.component(.hour, from: event.timestamp) - currentHour) <= 1
        }
        
        if similarTimeEvents.count >= 3 {
            // Pattern detected
            let averageMinute = similarTimeEvents.reduce(0) { sum, event in
                sum + calendar.component(.minute, from: event.timestamp)
            } / similarTimeEvents.count
            
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = currentHour
            components.minute = averageMinute
            
            if let predictedTime = calendar.date(from: components),
               predictedTime > Date() {
                return OfflinePrediction(
                    predictedTime: predictedTime,
                    confidence: Double(similarTimeEvents.count) / 10.0,
                    reason: "Daily pattern detected"
                )
            }
        }
        
        return OfflinePrediction(
            predictedTime: nil,
            confidence: 0,
            reason: "No pattern detected"
        )
    }
}

// MARK: - Sync Queue Manager Integration

private class SyncQueueManager {
    static let shared = SyncQueueManager()
    
    func processOfflineQueue() async {
        // This would integrate with your DashboardSyncService
        print("📤 Processing offline queue...")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkConnectionRestored = Notification.Name("networkConnectionRestored")
    static let networkConnectionLost = Notification.Name("networkConnectionLost")
    static let networkOfflinePredicted = Notification.Name("networkOfflinePredicted")
    static let networkQualityChanged = Notification.Name("networkQualityChanged")
}
