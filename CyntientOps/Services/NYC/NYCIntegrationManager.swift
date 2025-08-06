//
//  NYCIntegrationManager.swift
//  CyntientOps Phase 5
//
//  Central manager for NYC API integrations
//  Coordinates all NYC compliance services and data synchronization
//

import Foundation
import Combine

@MainActor
public final class NYCIntegrationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var integrationStatus: IntegrationStatus = .initializing
    @Published public var lastFullSync: Date?
    @Published public var syncProgress: Double = 0.0
    @Published public var apiHealth: [String: APIHealth] = [:]
    
    // MARK: - Services
    private let nycAPI: NYCAPIService
    private let complianceService: NYCComplianceService
    private let database: GRDBManager
    
    // MARK: - Background Tasks
    private var syncTask: Task<Void, Never>?
    private var healthCheckTimer: Timer?
    
    // MARK: - Configuration
    private struct Config {
        static let fullSyncInterval: TimeInterval = 21600 // 6 hours
        static let healthCheckInterval: TimeInterval = 300 // 5 minutes
        static let maxRetryAttempts = 3
        static let backoffMultiplier = 2.0
    }
    
    public enum IntegrationStatus: Equatable {
        case initializing
        case ready
        case syncing
        case error(String)
        case disabled
    }
    
    public struct APIHealth {
        let name: String
        let isHealthy: Bool
        let lastSuccessfulCall: Date?
        let errorCount: Int
        let averageResponseTime: TimeInterval
        
        var statusDescription: String {
            if isHealthy {
                return "✅ Operational"
            } else {
                return "❌ \(errorCount) errors"
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(database: GRDBManager) {
        self.database = database
        self.nycAPI = NYCAPIService.shared
        self.complianceService = NYCComplianceService(database: database)
        
        Task {
            await initialize()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize NYC integrations
    public func initialize() async {
        integrationStatus = .initializing
        
        do {
            // Check database schema
            try await setupDatabaseSchema()
            
            // Verify API connectivity
            await checkAPIHealth()
            
            // Load cached data
            await loadCachedComplianceData()
            
            // Setup background sync
            startBackgroundSync()
            
            // Start health monitoring
            startHealthMonitoring()
            
            integrationStatus = .ready
            
            print("✅ NYC Integration Manager initialized successfully")
            
        } catch {
            integrationStatus = .error(error.localizedDescription)
            print("❌ NYC Integration Manager initialization failed: \(error)")
        }
    }
    
    /// Perform full sync of all NYC compliance data
    public func performFullSync() async {
        guard integrationStatus != .syncing else { return }
        
        integrationStatus = .syncing
        syncProgress = 0.0
        
        await complianceService.syncAllBuildingsCompliance()
        
        // Update sync progress from compliance service
        complianceService.$syncProgress
            .assign(to: &$syncProgress)
        
        lastFullSync = Date()
        integrationStatus = .ready
        
        // Post notification
        NotificationCenter.default.post(name: .nycDataSyncCompleted, object: self, userInfo: nil)
    }
    
    /// Get compliance summary for all buildings
    public func getComplianceSummary() -> ComplianceSummary {
        let allIssues = getAllComplianceIssues()
        let criticalIssues = allIssues.filter { $0.severity == .critical }
        let openIssues = allIssues.filter { $0.status == .open }
        
        let buildingScores = complianceService.complianceData.mapValues { $0.overallComplianceScore }
        let averageScore = buildingScores.values.isEmpty ? 1.0 : buildingScores.values.reduce(0, +) / Double(buildingScores.count)
        
        return ComplianceSummary(
            totalBuildings: buildingScores.count,
            averageComplianceScore: averageScore,
            totalIssues: allIssues.count,
            criticalIssues: criticalIssues.count,
            openIssues: openIssues.count,
            buildingScores: buildingScores,
            lastUpdated: lastFullSync ?? Date()
        )
    }
    
    /// Get compliance issues for specific building
    public func getComplianceIssues(for buildingId: String) -> [CoreTypes.ComplianceIssue] {
        return complianceService.getComplianceIssues(for: buildingId)
    }
    
    /// Get LL97 compliance status for all buildings
    public func getLL97Status() -> [String: String] {
        return complianceService.complianceData.mapValues { $0.ll97ComplianceStatus }
    }
    
    /// Force refresh specific building
    public func refreshBuilding(_ buildingId: String) async {
        await complianceService.refreshBuilding(buildingId)
    }
    
    /// Get API health status
    public func getAPIHealthReport() -> [APIHealth] {
        return Array(apiHealth.values)
    }
    
    /// Enable/disable NYC integrations
    public func setIntegrationEnabled(_ enabled: Bool) {
        if enabled && integrationStatus == .disabled {
            Task { await initialize() }
        } else if !enabled {
            integrationStatus = .disabled
            stopBackgroundSync()
            stopHealthMonitoring()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDatabaseSchema() async throws {
        // Create NYC compliance cache table
        let createCacheTable = """
            CREATE TABLE IF NOT EXISTS nyc_compliance_cache (
                building_id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                updated_at REAL NOT NULL
            )
        """
        
        // Create compliance issues table if it doesn't exist
        let createComplianceTable = """
            CREATE TABLE IF NOT EXISTS compliance_issues (
                id TEXT PRIMARY KEY,
                building_id TEXT NOT NULL,
                building_name TEXT,
                type TEXT NOT NULL,
                severity TEXT NOT NULL,
                status TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                reported_date REAL NOT NULL,
                due_date REAL,
                resolved_date REAL,
                assigned_to TEXT,
                notes TEXT,
                source TEXT,
                external_id TEXT,
                created_at REAL DEFAULT (datetime('now')),
                updated_at REAL DEFAULT (datetime('now'))
            )
        """
        
        // Add compliance score column to buildings if it doesn't exist
        let addComplianceScore = """
            ALTER TABLE buildings 
            ADD COLUMN compliance_score REAL DEFAULT 1.0
        """
        
        let addLastComplianceUpdate = """
            ALTER TABLE buildings 
            ADD COLUMN last_compliance_update REAL
        """
        
        // Execute schema updates
        try await database.execute(createCacheTable)
        try await database.execute(createComplianceTable)
        
        // These may fail if columns already exist - that's okay
        try? await database.execute(addComplianceScore)
        try? await database.execute(addLastComplianceUpdate)
        
        // Create indexes for performance
        let createIndexes = [
            "CREATE INDEX IF NOT EXISTS idx_compliance_building ON compliance_issues(building_id)",
            "CREATE INDEX IF NOT EXISTS idx_compliance_severity ON compliance_issues(severity)",
            "CREATE INDEX IF NOT EXISTS idx_compliance_status ON compliance_issues(status)",
            "CREATE INDEX IF NOT EXISTS idx_compliance_source ON compliance_issues(source)"
        ]
        
        for indexQuery in createIndexes {
            try? await database.execute(indexQuery)
        }
    }
    
    private func checkAPIHealth() async {
        let endpoints: [String: () async -> Bool] = [
            "HPD": { 
                do {
                    _ = try await self.nycAPI.fetchHPDViolations(bin: "1000001")
                    return true
                } catch {
                    return false
                }
            },
            "DOB": {
                do {
                    _ = try await self.nycAPI.fetchDOBPermits(bin: "1000001")
                    return true
                } catch {
                    return false
                }
            },
            "LL97": {
                do {
                    _ = try await self.nycAPI.fetchLL97Compliance(bbl: "1000010001")
                    return true
                } catch {
                    return false
                }
            },
            "311": {
                do {
                    _ = try await self.nycAPI.fetch311Complaints(bin: "1000001")
                    return true
                } catch {
                    return false
                }
            }
        ]
        
        for (name, check) in endpoints {
            let startTime = Date()
            let isHealthy = await check()
            let responseTime = Date().timeIntervalSince(startTime)
            
            apiHealth[name] = APIHealth(
                name: name,
                isHealthy: isHealthy,
                lastSuccessfulCall: isHealthy ? Date() : apiHealth[name]?.lastSuccessfulCall,
                errorCount: isHealthy ? 0 : (apiHealth[name]?.errorCount ?? 0) + 1,
                averageResponseTime: responseTime
            )
        }
    }
    
    private func loadCachedComplianceData() async {
        do {
            let query = "SELECT building_id, data FROM nyc_compliance_cache"
            let rows = try await database.query(query)
            
            for row in rows {
                if let buildingId = row["building_id"] as? String,
                   let data = row["data"] as? Data {
                    do {
                        let compliance = try JSONDecoder().decode(NYCBuildingCompliance.self, from: data)
                        complianceService.complianceData[buildingId] = compliance
                    } catch {
                        print("Failed to decode cached compliance data for \(buildingId): \(error)")
                    }
                }
            }
            
            print("✅ Loaded cached compliance data for \(complianceService.complianceData.count) buildings")
            
        } catch {
            print("⚠️ Failed to load cached compliance data: \(error)")
        }
    }
    
    private func startBackgroundSync() {
        syncTask = Task {
            while !Task.isCancelled {
                // Wait for sync interval
                try? await Task.sleep(nanoseconds: UInt64(Config.fullSyncInterval * 1_000_000_000))
                
                if !Task.isCancelled && integrationStatus == .ready {
                    await performFullSync()
                }
            }
        }
    }
    
    private func stopBackgroundSync() {
        syncTask?.cancel()
        syncTask = nil
    }
    
    private func startHealthMonitoring() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: Config.healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAPIHealth()
            }
        }
    }
    
    private func stopHealthMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func getAllComplianceIssues() -> [CoreTypes.ComplianceIssue] {
        return complianceService.complianceData.values.flatMap { compliance in
            complianceService.getComplianceIssues(for: compliance.bin)
        }
    }
    
    deinit {
        syncTask?.cancel()
        healthCheckTimer?.invalidate()
    }
}

// MARK: - Supporting Types

public struct ComplianceSummary {
    public let totalBuildings: Int
    public let averageComplianceScore: Double
    public let totalIssues: Int
    public let criticalIssues: Int
    public let openIssues: Int
    public let buildingScores: [String: Double]
    public let lastUpdated: Date
    
    public var overallGrade: String {
        switch averageComplianceScore {
        case 0.95...1.0: return "A+"
        case 0.90..<0.95: return "A"
        case 0.85..<0.90: return "B+"
        case 0.80..<0.85: return "B"
        case 0.75..<0.80: return "C+"
        case 0.70..<0.75: return "C"
        default: return "Needs Attention"
        }
    }
    
    public var riskLevel: String {
        if criticalIssues > 5 || averageComplianceScore < 0.7 {
            return "High Risk"
        } else if criticalIssues > 2 || averageComplianceScore < 0.85 {
            return "Medium Risk"
        } else {
            return "Low Risk"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let nycDataSyncCompleted = Notification.Name("nycDataSyncCompleted")
    static let nycAPIHealthChanged = Notification.Name("nycAPIHealthChanged")
    static let complianceScoreUpdated = Notification.Name("complianceScoreUpdated")
}