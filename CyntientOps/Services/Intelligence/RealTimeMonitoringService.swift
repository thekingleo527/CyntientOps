//
//  RealTimeMonitoringService.swift
//  CyntientOps Phase 10.4
//
//  Real-time monitoring with NYC webhooks, push notifications, dashboard updates, and Nova alerts
//  Provides comprehensive real-time intelligence and immediate response capabilities
//

import Foundation
import Combine
import UserNotifications
import Network

@MainActor
public class RealTimeMonitoringService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isMonitoring = false
    @Published public var activeAlerts: [RealTimeAlert] = []
    @Published public var monitoringStats: MonitoringStats = MonitoringStats()
    @Published public var connectionStatus: ConnectionStatus = .disconnected
    @Published public var lastUpdate: Date?
    
    public enum ConnectionStatus: Equatable {
        case connected
        case connecting
        case disconnected
        case error(String)
    }
    
    // MARK: - Dependencies
    private let database: GRDBManager
    private let nycCompliance: NYCComplianceService
    private let violationPredictor: ViolationPredictor
    private let costIntelligence: CostIntelligenceService
    private let novaAI: NovaAIManager
    
    // MARK: - Private Properties
    private var webSocketTasks: [String: URLSessionWebSocketTask] = [:]
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "monitoring-queue")
    
    // Configuration
    private struct MonitoringConfig {
        static let webhookEndpoints = [
            "hpd": "wss://data.cityofnewyork.us/ws/hpd/violations",
            "dob": "wss://data.cityofnewyork.us/ws/dob/violations", 
            "ll97": "wss://data.cityofnewyork.us/ws/ll97/reports",
            "dsny": "wss://data.cityofnewyork.us/ws/dsny/schedules"
        ]
        static let monitoringInterval: TimeInterval = 30 // seconds
        static let reconnectDelay: TimeInterval = 5 // seconds
        static let maxReconnectAttempts = 10
        static let alertRetentionHours = 24
    }
    
    // MARK: - Initialization
    
    public init(
        database: GRDBManager,
        nycCompliance: NYCComplianceService,
        violationPredictor: ViolationPredictor,
        costIntelligence: CostIntelligenceService,
        novaAI: NovaAIManager = NovaAIManager.shared
    ) {
        self.database = database
        self.nycCompliance = nycCompliance
        self.violationPredictor = violationPredictor
        self.costIntelligence = costIntelligence
        self.novaAI = novaAI
        
        setupNetworkMonitoring()
        requestNotificationPermissions()
    }
    
    // MARK: - Public Methods
    
    /// Start real-time monitoring
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        
        print("🔴 Starting real-time monitoring service...")
        isMonitoring = true
        connectionStatus = .connecting
        
        // Connect to NYC API webhooks
        await connectToWebhooks()
        
        // Start periodic monitoring tasks
        startPeriodicMonitoring()
        
        // Setup alert cleanup
        startAlertCleanup()
        
        // Update Nova AI state
        novaAI.setMonitoringState(active: true)
        
        print("✅ Real-time monitoring service started")
    }
    
    /// Stop real-time monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        print("⏹️ Stopping real-time monitoring service...")
        
        isMonitoring = false
        connectionStatus = .disconnected
        
        // Disconnect webhooks
        disconnectWebhooks()
        
        // Stop timers
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        // Update Nova AI state
        novaAI.setMonitoringState(active: false)
        
        print("✅ Real-time monitoring service stopped")
    }
    
    /// Process incoming real-time data
    public func processRealTimeUpdate(_ data: [String: Any]) async {
        let updateType = data["type"] as? String ?? "unknown"
        let buildingId = data["building_id"] as? String
        let source = data["source"] as? String ?? "unknown"
        
        print("📡 Processing real-time update: \(updateType) from \(source)")
        
        // Create alert based on update type
        let alert = await createAlertFromUpdate(data)
        if let alert = alert {
            activeAlerts.append(alert)
            
            // Send push notification
            await sendPushNotification(for: alert)
            
            // Update Nova AI with urgent information
            if alert.severity >= .high {
                await novaAI.processUrgentAlert(alert.title, context: alert.description)
            }
            
            // Trigger dashboard updates
            await broadcastDashboardUpdate(alert)
        }
        
        // Update monitoring stats
        monitoringStats.totalUpdatesReceived += 1
        monitoringStats.lastUpdate = Date()
        lastUpdate = Date()
    }
    
    /// Get active alerts for building
    public func getAlertsForBuilding(_ buildingId: String) -> [RealTimeAlert] {
        return activeAlerts.filter { $0.buildingId == buildingId }
    }
    
    /// Acknowledge alert
    public func acknowledgeAlert(_ alertId: String) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].status = .acknowledged
            activeAlerts[index].acknowledgedAt = Date()
        }
    }
    
    /// Dismiss alert
    public func dismissAlert(_ alertId: String) {
        activeAlerts.removeAll { $0.id == alertId }
    }
    
    /// Get monitoring health status
    public func getHealthStatus() -> MonitoringHealthStatus {
        let activeConnections = webSocketTasks.values.filter { 
            $0.state == .running 
        }.count
        
        let isHealthy = isMonitoring && 
                       activeConnections > 0 && 
                       connectionStatus == .connected
        
        return MonitoringHealthStatus(
            isHealthy: isHealthy,
            activeConnections: activeConnections,
            totalConnections: webSocketTasks.count,
            lastUpdateAge: lastUpdate?.timeIntervalSinceNow.magnitude ?? Double.infinity,
            activeAlerts: activeAlerts.count,
            connectionStatus: connectionStatus
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied {
                    if self?.connectionStatus == .disconnected {
                        await self?.reconnectWebhooks()
                    }
                } else {
                    self?.connectionStatus = .disconnected
                    self?.disconnectWebhooks()
                }
            }
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func connectToWebhooks() async {
        connectionStatus = .connecting
        
        for (service, endpoint) in MonitoringConfig.webhookEndpoints {
            await connectWebhook(service: service, endpoint: endpoint)
        }
        
        // Check if any connections succeeded
        let activeConnections = webSocketTasks.values.filter { $0.state == .running }.count
        
        if activeConnections > 0 {
            connectionStatus = .connected
            monitoringStats.connectionAttempts += 1
            monitoringStats.lastConnected = Date()
        } else {
            connectionStatus = .error("Failed to connect to any webhooks")
        }
    }
    
    private func connectWebhook(service: String, endpoint: String) async {
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid webhook URL for \(service): \(endpoint)")
            return
        }
        
        let session = URLSession.shared
        let webSocketTask = session.webSocketTask(with: url)
        
        webSocketTasks[service] = webSocketTask
        
        // Start listening for messages
        await listenForMessages(service: service, task: webSocketTask)
        
        webSocketTask.resume()
        print("🔌 Connected to \(service) webhook")
    }
    
    private func listenForMessages(service: String, task: URLSessionWebSocketTask) async {
        do {
            let message = try await task.receive()
            
            switch message {
            case .string(let text):
                if let data = text.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var enrichedData = json
                    enrichedData["source"] = service
                    await processRealTimeUpdate(enrichedData)
                }
            case .data(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var enrichedData = json
                    enrichedData["source"] = service
                    await processRealTimeUpdate(enrichedData)
                }
            @unknown default:
                break
            }
            
            // Continue listening
            if task.state == .running {
                await listenForMessages(service: service, task: task)
            }
            
        } catch {
            print("❌ WebSocket error for \(service): \(error)")
            
            // Attempt reconnection
            await reconnectWebhook(service: service)
        }
    }
    
    private func reconnectWebhooks() async {
        guard isMonitoring else { return }
        
        print("🔄 Reconnecting webhooks...")
        await connectToWebhooks()
    }
    
    private func reconnectWebhook(service: String) async {
        guard isMonitoring else { return }
        
        // Wait before reconnecting
        try? await Task.sleep(nanoseconds: UInt64(MonitoringConfig.reconnectDelay * 1_000_000_000))
        
        if let endpoint = MonitoringConfig.webhookEndpoints[service] {
            await connectWebhook(service: service, endpoint: endpoint)
        }
    }
    
    private func disconnectWebhooks() {
        for (service, task) in webSocketTasks {
            task.cancel()
            print("🔌 Disconnected from \(service) webhook")
        }
        webSocketTasks.removeAll()
    }
    
    private func startPeriodicMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: MonitoringConfig.monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicCheck()
            }
        }
    }
    
    private func performPeriodicCheck() async {
        // Check for new violations that may not have come through webhooks
        await checkForMissedUpdates()
        
        // Update monitoring stats
        monitoringStats.periodicChecksPerformed += 1
        
        // Health check on connections
        await validateConnections()
    }
    
    private func checkForMissedUpdates() async {
        // Get recent violations from NYC APIs directly
        let cutoffTime = Date().addingTimeInterval(-MonitoringConfig.monitoringInterval * 2)
        
        do {
            let recentViolations = await nycCompliance.getRecentViolations(since: cutoffTime)
            
            for violation in recentViolations {
                // Check if we already have this violation
                let existingAlert = activeAlerts.first { $0.sourceId == violation.id }
                
                if existingAlert == nil {
                    // This is a missed update - process it
                    let updateData: [String: Any] = [
                        "type": "violation",
                        "source": violation.source,
                        "building_id": violation.buildingId,
                        "violation_id": violation.id,
                        "description": violation.description,
                        "severity": violation.severity.rawValue,
                        "timestamp": violation.reportedDate.timeIntervalSince1970
                    ]
                    
                    await processRealTimeUpdate(updateData)
                }
            }
        } catch {
            print("❌ Failed to check for missed updates: \(error)")
        }
    }
    
    private func validateConnections() async {
        var healthyConnections = 0
        
        for (service, task) in webSocketTasks {
            if task.state == .running {
                healthyConnections += 1
            } else {
                print("⚠️ Connection to \(service) is unhealthy, attempting reconnect...")
                await reconnectWebhook(service: service)
            }
        }
        
        if healthyConnections == 0 && connectionStatus == .connected {
            connectionStatus = .error("All webhook connections lost")
        }
    }
    
    private func createAlertFromUpdate(_ data: [String: Any]) async -> RealTimeAlert? {
        let updateType = data["type"] as? String ?? "unknown"
        let buildingId = data["building_id"] as? String
        let source = data["source"] as? String ?? "unknown"
        
        switch updateType {
        case "violation":
            return await createViolationAlert(data)
        case "inspection_scheduled":
            return await createInspectionAlert(data)
        case "permit_expiry":
            return await createPermitAlert(data)
        case "ll97_threshold":
            return await createLL97Alert(data)
        case "emergency":
            return await createEmergencyAlert(data)
        default:
            return createGenericAlert(data)
        }
    }
    
    private func createViolationAlert(_ data: [String: Any]) async -> RealTimeAlert? {
        guard let buildingId = data["building_id"] as? String,
              let violationId = data["violation_id"] as? String,
              let description = data["description"] as? String else {
            return nil
        }
        
        let source = data["source"] as? String ?? "unknown"
        let severityStr = data["severity"] as? String ?? "medium"
        let severity = AlertSeverity.from(string: severityStr)
        
        // Get cost prediction for this violation
        let costPrediction = await predictViolationCost(buildingId: buildingId, violationType: source)
        
        return RealTimeAlert(
            id: UUID().uuidString,
            type: .violation,
            severity: severity,
            title: "New \(source.uppercased()) Violation",
            description: description,
            buildingId: buildingId,
            sourceId: violationId,
            source: source,
            timestamp: Date(),
            estimatedCost: costPrediction,
            actionRequired: true,
            expiresAt: Date().addingTimeInterval(TimeInterval(MonitoringConfig.alertRetentionHours * 3600))
        )
    }
    
    private func createInspectionAlert(_ data: [String: Any]) async -> RealTimeAlert? {
        guard let buildingId = data["building_id"] as? String,
              let inspectionDate = data["scheduled_date"] as? String else {
            return nil
        }
        
        return RealTimeAlert(
            id: UUID().uuidString,
            type: .inspection,
            severity: .medium,
            title: "Inspection Scheduled",
            description: "Building inspection scheduled for \(inspectionDate)",
            buildingId: buildingId,
            sourceId: data["inspection_id"] as? String,
            source: "DOB",
            timestamp: Date(),
            estimatedCost: 500.0, // Default inspection cost
            actionRequired: true,
            expiresAt: Date().addingTimeInterval(TimeInterval(MonitoringConfig.alertRetentionHours * 3600))
        )
    }
    
    private func createPermitAlert(_ data: [String: Any]) async -> RealTimeAlert? {
        guard let buildingId = data["building_id"] as? String,
              let permitId = data["permit_id"] as? String else {
            return nil
        }
        
        return RealTimeAlert(
            id: UUID().uuidString,
            type: .permit,
            severity: .high,
            title: "Permit Expiring Soon",
            description: "Permit \(permitId) requires renewal",
            buildingId: buildingId,
            sourceId: permitId,
            source: "DOB",
            timestamp: Date(),
            estimatedCost: 2500, // Typical permit renewal cost
            actionRequired: true,
            expiresAt: Date().addingTimeInterval(TimeInterval(MonitoringConfig.alertRetentionHours * 3600))
        )
    }
    
    private func createLL97Alert(_ data: [String: Any]) async -> RealTimeAlert? {
        guard let buildingId = data["building_id"] as? String else {
            return nil
        }
        
        let thresholdExceeded = data["threshold_exceeded"] as? Double ?? 0
        
        return RealTimeAlert(
            id: UUID().uuidString,
            type: .compliance,
            severity: .critical,
            title: "LL97 Emissions Threshold Exceeded",
            description: "Building exceeded emissions limit by \(String(format: "%.1f", thresholdExceeded))%",
            buildingId: buildingId,
            sourceId: data["report_id"] as? String,
            source: "LL97",
            timestamp: Date(),
            estimatedCost: 50000, // Typical LL97 fine
            actionRequired: true,
            expiresAt: Date().addingTimeInterval(TimeInterval(MonitoringConfig.alertRetentionHours * 3600))
        )
    }
    
    private func createEmergencyAlert(_ data: [String: Any]) async -> RealTimeAlert? {
        guard let buildingId = data["building_id"] as? String,
              let description = data["description"] as? String else {
            return nil
        }
        
        return RealTimeAlert(
            id: UUID().uuidString,
            type: .emergency,
            severity: .critical,
            title: "Emergency Situation",
            description: description,
            buildingId: buildingId,
            sourceId: data["incident_id"] as? String,
            source: data["source"] as? String ?? "Emergency Services",
            timestamp: Date(),
            estimatedCost: nil, // Emergency costs vary widely
            actionRequired: true,
            expiresAt: Date().addingTimeInterval(4 * 3600) // 4 hours for emergency
        )
    }
    
    private func createGenericAlert(_ data: [String: Any]) -> RealTimeAlert? {
        guard let buildingId = data["building_id"] as? String else {
            return nil
        }
        
        return RealTimeAlert(
            id: UUID().uuidString,
            type: .information,
            severity: .low,
            title: "Building Update",
            description: data["description"] as? String ?? "Building information updated",
            buildingId: buildingId,
            sourceId: data["update_id"] as? String,
            source: data["source"] as? String ?? "System",
            timestamp: Date(),
            estimatedCost: nil, // Informational alerts have no cost
            actionRequired: false,
            expiresAt: Date().addingTimeInterval(TimeInterval(MonitoringConfig.alertRetentionHours * 3600))
        )
    }
    
    private func predictViolationCost(buildingId: String, violationType: String) async -> Double {
        // Use violation predictor to estimate cost
        let violationType = ViolationType(rawValue: violationType.uppercased()) ?? .hpd
        let predictions = violationPredictor.getBuildingPredictions(buildingId)
        
        let matchingPrediction = predictions.first { $0.violationType == violationType }
        return matchingPrediction?.estimatedFine ?? 1500 // Default fine estimate
    }
    
    private func sendPushNotification(for alert: RealTimeAlert) async {
        guard alert.severity >= .medium else { return }
        
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.description
        content.sound = alert.severity >= .high ? .defaultCritical : .default
        content.categoryIdentifier = "BUILDING_ALERT"
        content.userInfo = [
            "alertId": alert.id,
            "buildingId": alert.buildingId,
            "severity": alert.severity.rawValue
        ]
        
        let request = UNNotificationRequest(
            identifier: alert.id,
            content: content,
            trigger: nil // Immediate notification
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Push notification sent for alert: \(alert.title)")
        } catch {
            print("❌ Failed to send push notification: \(error)")
        }
    }
    
    private func broadcastDashboardUpdate(_ alert: RealTimeAlert) async {
        // Broadcast to dashboard subscribers
        let updateData: [String: Any] = [
            "type": "alert",
            "alert": [
                "id": alert.id,
                "title": alert.title,
                "description": alert.description,
                "buildingId": alert.buildingId,
                "severity": alert.severity.rawValue,
                "timestamp": alert.timestamp.timeIntervalSince1970
            ]
        ]
        
        // This would integrate with WebSocket or SSE for dashboard updates
        NotificationCenter.default.post(
            name: Notification.Name("RealTimeAlertCreated"),
            object: nil,
            userInfo: updateData
        )
    }
    
    private func startAlertCleanup() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.cleanupExpiredAlerts()
            }
        }
    }
    
    private func cleanupExpiredAlerts() async {
        let now = Date()
        let initialCount = activeAlerts.count
        
        activeAlerts.removeAll { $0.expiresAt < now }
        
        let removedCount = initialCount - activeAlerts.count
        if removedCount > 0 {
            print("🧹 Cleaned up \(removedCount) expired alerts")
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Push notification permissions granted")
            } else {
                print("❌ Push notification permissions denied")
            }
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Types

public struct RealTimeAlert: Identifiable {
    public let id: String
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let description: String
    public let buildingId: String
    public let sourceId: String?
    public let source: String
    public let timestamp: Date
    public let estimatedCost: Double?
    public let actionRequired: Bool
    public let expiresAt: Date
    public var status: AlertStatus = .active
    public var acknowledgedAt: Date?
    
    public enum AlertType {
        case violation
        case inspection
        case permit
        case compliance
        case emergency
        case information
    }
    
    public enum AlertStatus {
        case active
        case acknowledged
        case resolved
    }
}

public enum AlertSeverity: String, CaseIterable, Comparable {
    case low
    case medium
    case high
    case critical
    
    public static func from(string: String) -> AlertSeverity {
        return AlertSeverity(rawValue: string.lowercased()) ?? .medium
    }
    
    public static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        let order: [AlertSeverity] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

public struct MonitoringStats {
    public var totalUpdatesReceived: Int = 0
    public var alertsGenerated: Int = 0
    public var connectionAttempts: Int = 0
    public var lastConnected: Date?
    public var lastUpdate: Date?
    public var periodicChecksPerformed: Int = 0
    
    public var uptime: TimeInterval {
        return lastConnected?.timeIntervalSinceNow.magnitude ?? 0
    }
}

public struct MonitoringHealthStatus {
    public let isHealthy: Bool
    public let activeConnections: Int
    public let totalConnections: Int
    public let lastUpdateAge: TimeInterval
    public let activeAlerts: Int
    public let connectionStatus: RealTimeMonitoringService.ConnectionStatus
    
    public var healthScore: Double {
        var score: Double = 0
        
        // Connection health (40%)
        if activeConnections > 0 {
            score += 40 * (Double(activeConnections) / Double(totalConnections))
        }
        
        // Recency of updates (30%)
        if lastUpdateAge < 300 { // 5 minutes
            score += 30 * (1 - min(lastUpdateAge / 300, 1))
        }
        
        // Alert management (20%)
        if activeAlerts < 10 {
            score += 20
        } else {
            score += 20 * (1 - min(Double(activeAlerts) / 50, 1))
        }
        
        // Overall health (10%)
        if isHealthy {
            score += 10
        }
        
        return min(score, 100)
    }
}

public enum RealTimeMonitoringError: LocalizedError {
    case connectionFailed(String)
    case webhookError(String)
    case dataProcessingError(String)
    case notificationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .webhookError(let msg): return "Webhook error: \(msg)"
        case .dataProcessingError(let msg): return "Data processing error: \(msg)"
        case .notificationError(let msg): return "Notification error: \(msg)"
        }
    }
}

// MARK: - Extensions

extension NovaAIManager {
    public func setMonitoringState(active: Bool) {
        if active {
            self.novaState = .active
            print("🔴 Nova AI monitoring state: ACTIVE")
        } else {
            self.novaState = .idle
            print("⚪ Nova AI monitoring state: IDLE")
        }
    }
    
    public func processUrgentAlert(_ title: String, context: String) async {
        self.novaState = .urgent
        print("🚨 Nova AI processing urgent alert: \(title)")
        
        // Simulate AI processing
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        self.novaState = .active
    }
}

// Mock NYC Compliance Service extension for real-time data
extension NYCComplianceService {
    func getRecentViolations(since: Date) async -> [MockViolation] {
        // Mock implementation - in production this would be a real API call
        return [
            MockViolation(
                id: UUID().uuidString,
                buildingId: "14", // Rubin Museum
                source: "HPD",
                description: "Heating system maintenance required",
                severity: .medium,
                reportedDate: Date()
            )
        ]
    }
}

// Mock violation structure
struct MockViolation {
    let id: String
    let buildingId: String
    let source: String
    let description: String
    let severity: CoreTypes.ComplianceSeverity
    let reportedDate: Date
}