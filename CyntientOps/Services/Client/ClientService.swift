//
//  ClientService.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  ClientService.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0B.4: ClientService
//  Manages client data access and portfolio filtering
//

import Foundation
import GRDB

public actor ClientService {
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    private let buildingService = BuildingService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    // MARK: - Cache
    private var clientCache: [String: Client] = [:]
    private var buildingCache: [String: [NamedCoordinate]] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    private var lastCacheUpdate: Date?
    
    // MARK: - Data Types
    
    public struct Client {
        public let id: String
        public let name: String
        public let shortName: String
        public let contactEmail: String
        public let contactPhone: String
        public let address: String
        public let isActive: Bool
        public let buildingIds: [String]
        
        public var buildingCount: Int {
            buildingIds.count
        }
    }
    
    public struct ClientUser {
        public let userId: String
        public let clientId: String
        public let role: String
        public let canViewFinancials: Bool
        public let canEditSettings: Bool
    }
    
    public struct PortfolioSummary {
        public let clientId: String
        public let clientName: String
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completedTasks: Int
        public let pendingTasks: Int
        public let overallServiceLevel: Double
        public let complianceScore: Double
        public let monthlySpend: Double
        public let budgetUtilization: Double
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods - Client Access
    
    /// Get client for a user email
    public func getClientForUser(email: String) async throws -> Client? {
        // Check cache first
        if let cached = getCachedClient(for: email) {
            return cached
        }
        
        // Get user ID from email
        let userResult = try await grdbManager.query(
            "SELECT id FROM workers WHERE email = ?",
            [email]
        )
        
        guard let userId = userResult.first?["id"] as? String else {
            return nil
        }
        
        // Get client association
        let clientResult = try await grdbManager.query("""
            SELECT c.* 
            FROM clients c
            INNER JOIN client_users cu ON c.id = cu.client_id
            WHERE cu.user_id = ?
        """, [userId])
        
        guard let row = clientResult.first else {
            return nil
        }
        
        // Get building IDs for client
        let buildingIds = try await getBuildingIdsForClient(row["id"] as? String ?? "")
        
        let client = Client(
            id: row["id"] as? String ?? "",
            name: row["name"] as? String ?? "",
            shortName: row["short_name"] as? String ?? "",
            contactEmail: row["contact_email"] as? String ?? "",
            contactPhone: row["contact_phone"] as? String ?? "",
            address: row["address"] as? String ?? "",
            isActive: (row["is_active"] as? Int64 ?? 0) == 1,
            buildingIds: buildingIds
        )
        
        // Cache the result
        cacheClient(client, for: email)
        
        return client
    }
    
    /// Get all buildings for a client
    public func getBuildingsForClient(_ clientId: String) async throws -> [NamedCoordinate] {
        // Check cache
        if let cached = buildingCache[clientId],
           let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheExpiration {
            return cached
        }
        
        // Get building IDs
        let buildingIds = try await getBuildingIdsForClient(clientId)
        
        // Get building details
        var buildings: [NamedCoordinate] = []
        for buildingId in buildingIds {
            if let building = try? await buildingService.getBuilding(buildingId: buildingId) {
                buildings.append(building)
            }
        }
        
        // Cache results
        buildingCache[clientId] = buildings
        lastCacheUpdate = Date()
        
        return buildings
    }
    
    /// Get portfolio summary for a client
    public func getPortfolioSummary(clientId: String) async throws -> PortfolioSummary {
        // Get client info
        let clientResult = try await grdbManager.query(
            "SELECT * FROM clients WHERE id = ?",
            [clientId]
        )
        
        guard let clientRow = clientResult.first else {
            throw ClientServiceError.clientNotFound
        }
        
        // Get buildings
        let buildings = try await getBuildingsForClient(clientId)
        let buildingIds = buildings.map { $0.id }
        
        // Get active workers for these buildings
        let activeWorkersResult = try await grdbManager.query("""
            SELECT COUNT(DISTINCT wa.worker_id) as count
            FROM worker_assignments wa
            INNER JOIN time_clock_entries tce ON wa.worker_id = tce.workerId
            WHERE wa.building_id IN (\(buildingIds.map { _ in "?" }.joined(separator: ",")))
            AND wa.is_active = 1
            AND tce.clockOutTime IS NULL
        """, buildingIds)
        
        let activeWorkers: Int = Int(activeWorkersResult.first?["count"] as? Int64 ?? 0)
        
        // Get task counts
        let taskResult = try await grdbManager.query("""
            SELECT 
                COUNT(CASE WHEN isCompleted = 1 THEN 1 END) as completed,
                COUNT(CASE WHEN isCompleted = 0 THEN 1 END) as pending
            FROM routine_tasks
            WHERE building_id IN (\(buildingIds.map { _ in "?" }.joined(separator: ",")))
            AND date(createdAt) = date('now')
        """, buildingIds)
        
        let completedTasks: Int = Int(taskResult.first?["completed"] as? Int64 ?? 0)
        let pendingTasks: Int = Int(taskResult.first?["pending"] as? Int64 ?? 0)
        
        // Calculate metrics
        var totalServiceLevel = 0.0
        var totalComplianceScore = 0.0
        var validMetricsCount = 0
        
        for buildingId in buildingIds {
            if let metrics = try? await buildingMetricsService.calculateMetrics(for: buildingId) {
                totalServiceLevel += metrics.serviceLevel
                totalComplianceScore += metrics.complianceScore
                validMetricsCount += 1
            }
        }
        
        let overallServiceLevel = validMetricsCount > 0 ? totalServiceLevel / Double(validMetricsCount) : 0.0
        let complianceScore = validMetricsCount > 0 ? totalComplianceScore / Double(validMetricsCount) : 0.0
        
        // Calculate financials (simplified for now)
        let monthlySpend = Double(buildings.count) * 7500.0 // Average per building
        let monthlyBudget = Double(buildings.count) * 10000.0
        let budgetUtilization = monthlyBudget > 0 ? monthlySpend / monthlyBudget : 0.0
        
        return PortfolioSummary(
            clientId: clientId,
            clientName: clientRow["name"] as? String ?? "",
            totalBuildings: buildings.count,
            activeWorkers: Int(activeWorkers),
            completedTasks: Int(completedTasks),
            pendingTasks: Int(pendingTasks),
            overallServiceLevel: overallServiceLevel,
            complianceScore: complianceScore,
            monthlySpend: monthlySpend,
            budgetUtilization: budgetUtilization
        )
    }
    
    /// Get user's client access rights
    public func getClientUser(userId: String) async throws -> ClientUser? {
        let result = try await grdbManager.query("""
            SELECT * FROM client_users WHERE user_id = ?
        """, [userId])
        
        guard let row = result.first else {
            return nil
        }
        
        return ClientUser(
            userId: userId,
            clientId: row["client_id"] as? String ?? "",
            role: row["role"] as? String ?? "viewer",
            canViewFinancials: (row["can_view_financials"] as? Int64 ?? 0) == 1,
            canEditSettings: (row["can_edit_settings"] as? Int64 ?? 0) == 1
        )
    }
    
    /// Get all clients (admin only)
    public func getAllClients() async throws -> [Client] {
        let result = try await grdbManager.query("""
            SELECT * FROM clients WHERE is_active = 1 ORDER BY name
        """)
        
        var clients: [Client] = []
        
        for row in result {
            let clientId = row["id"] as? String ?? ""
            let buildingIds = try await getBuildingIdsForClient(clientId)
            
            let client = Client(
                id: clientId,
                name: row["name"] as? String ?? "",
                shortName: row["short_name"] as? String ?? "",
                contactEmail: row["contact_email"] as? String ?? "",
                contactPhone: row["contact_phone"] as? String ?? "",
                address: row["address"] as? String ?? "",
                isActive: true,
                buildingIds: buildingIds
            )
            
            clients.append(client)
        }
        
        return clients
    }
    
    // MARK: - Private Methods
    
    private func getBuildingIdsForClient(_ clientId: String) async throws -> [String] {
        let result = try await grdbManager.query("""
            SELECT building_id 
            FROM client_buildings 
            WHERE client_id = ?
            ORDER BY is_primary DESC, building_id
        """, [clientId])
        
        return result.compactMap { $0["building_id"] as? String }
    }
    
    private func getCachedClient(for email: String) -> Client? {
        // Simple cache lookup - in production, use proper caching
        return nil
    }
    
    private func cacheClient(_ client: Client, for email: String) {
        // Simple cache storage - in production, use proper caching
        clientCache[email] = client
    }
}

// MARK: - Errors

public enum ClientServiceError: LocalizedError {
    case clientNotFound
    case unauthorizedAccess
    case invalidClientId
    
    public var errorDescription: String? {
        switch self {
        case .clientNotFound:
            return "Client not found"
        case .unauthorizedAccess:
            return "Unauthorized access to client data"
        case .invalidClientId:
            return "Invalid client ID"
        }
    }
}