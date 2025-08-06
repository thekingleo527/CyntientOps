//
//  NYCComplianceService.swift
//  CyntientOps Phase 5
//
//  Service that integrates NYC API data with the main compliance system
//  Converts NYC data to CoreTypes for uniform handling
//

import Foundation
import Combine

@MainActor
public final class NYCComplianceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var complianceData: [String: NYCBuildingCompliance] = [:]
    @Published public var isLoading = false
    @Published public var lastUpdateTime: Date?
    @Published public var syncProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let nycAPI: NYCAPIService
    private let database: GRDBManager
    private var cancellables = Set<AnyCancellable>()
    
    // Background refresh timer
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    public init(database: GRDBManager) {
        self.nycAPI = NYCAPIService.shared
        self.database = database
        
        setupAutoRefresh()
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Sync compliance data for all buildings
    public func syncAllBuildingsCompliance() async {
        isLoading = true
        syncProgress = 0.0
        
        do {
            let buildings = try await getBuildingsFromDatabase()
            let totalBuildings = Double(buildings.count)
            
            for (index, building) in buildings.enumerated() {
                await syncBuildingCompliance(building: building)
                
                syncProgress = Double(index + 1) / totalBuildings
                
                // Rate limiting - respect NYC API limits
                if index < buildings.count - 1 {
                    try await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds between calls
                }
            }
            
            lastUpdateTime = Date()
            syncProgress = 1.0
            
            // Save to database
            await saveComplianceDataToDatabase()
            
        } catch {
            print("Error syncing compliance data: \(error)")
        }
        
        isLoading = false
    }
    
    /// Sync compliance data for a specific building
    public func syncBuildingCompliance(building: CoreTypes.NamedCoordinate) async {
        let bin = extractBIN(from: building)
        let bbl = extractBBL(from: building)
        
        let buildingCompliance = await nycAPI.fetchBuildingCompliance(bin: bin, bbl: bbl)
        
        // Convert to our format
        let nycCompliance = NYCBuildingCompliance(
            bin: bin,
            bbl: bbl,
            lastUpdated: Date(),
            hpdViolations: buildingCompliance.hpdViolations,
            dobPermits: buildingCompliance.dobPermits,
            fdnyInspections: buildingCompliance.fdnyInspections,
            ll97Data: buildingCompliance.ll97Emissions,
            complaints311: buildingCompliance.complaints311,
            depWaterData: []
        )
        
        complianceData[building.id] = nycCompliance
        
        // Convert to CoreTypes and update main compliance system
        await updateMainComplianceSystem(buildingId: building.id, nycData: nycCompliance)
    }
    
    /// Get compliance issues for a building
    public func getComplianceIssues(for buildingId: String) -> [CoreTypes.ComplianceIssue] {
        guard let nycData = complianceData[buildingId] else { return [] }
        
        var issues: [CoreTypes.ComplianceIssue] = []
        
        // Convert HPD Violations
        for violation in nycData.hpdViolations.filter({ $0.isActive }) {
            issues.append(CoreTypes.ComplianceIssue(
                id: violation.violationId,
                title: "HPD Violation - \(violation.currentStatus)",
                description: violation.novDescription,
                severity: violation.severity,
                buildingId: buildingId,
                buildingName: nil,
                status: .open,
                dueDate: parseDate(violation.newCorrectByDate),
                assignedTo: nil,
                createdAt: Date(),
                reportedDate: parseDate(violation.inspectionDate) ?? Date(),
                type: .regulatory
            ))
        }
        
        // Convert LL97 Issues
        for emission in nycData.ll97Data.filter({ !$0.isCompliant }) {
            issues.append(CoreTypes.ComplianceIssue(
                id: "ll97_\(emission.bbl)_\(emission.reportingYear)",
                title: "LL97 Emissions Over Limit",
                description: emission.complianceStatus,
                severity: .critical,
                buildingId: buildingId,
                buildingName: emission.propertyName,
                status: .open,
                dueDate: nil,
                assignedTo: nil,
                createdAt: Date(),
                reportedDate: Date(),
                type: .environmental
            ))
        }
        
        // Convert 311 Complaints
        for complaint in nycData.complaints311.filter({ $0.isActive }) {
            issues.append(CoreTypes.ComplianceIssue(
                id: complaint.uniqueKey,
                title: "\(complaint.complaintType) Complaint",
                description: complaint.descriptor ?? complaint.complaintType,
                severity: complaint.priority.toComplianceSeverity(),
                buildingId: buildingId,
                buildingName: nil,
                status: .open,
                dueDate: nil,
                assignedTo: nil,
                createdAt: Date(),
                reportedDate: parseDate(complaint.createdDate) ?? Date(),
                type: .operational
            ))
        }
        
        return issues.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    /// Get compliance score for a building
    public func getComplianceScore(for buildingId: String) -> Double {
        guard let nycData = complianceData[buildingId] else { return 1.0 }
        return nycData.overallComplianceScore
    }
    
    /// Get next required actions for a building
    public func getRequiredActions(for buildingId: String) -> [RequiredAction] {
        guard let nycData = complianceData[buildingId] else { return [] }
        return nycData.nextRequiredActions
    }
    
    /// Force refresh a specific building
    public func refreshBuilding(_ buildingId: String) async {
        guard let buildings = try? await getBuildingsFromDatabase(),
              let building = buildings.first(where: { $0.id == buildingId }) else {
            return
        }
        
        await syncBuildingCompliance(building: building)
    }
    
    // MARK: - Private Methods
    
    private func setupAutoRefresh() {
        // Refresh every 4 hours during business hours (9 AM - 6 PM)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 14400, repeats: true) { [weak self] _ in
            let hour = Calendar.current.component(.hour, from: Date())
            if (9...18).contains(hour) {
                Task { @MainActor in
                    await self?.syncAllBuildingsCompliance()
                }
            }
        }
    }
    
    private func setupNotifications() {
        // Listen for building updates
        NotificationCenter.default.publisher(for: .buildingDataUpdated)
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] notification in
                if let buildingId = notification.userInfo?["buildingId"] as? String {
                    Task {
                        await self?.refreshBuilding(buildingId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func getBuildingsFromDatabase() async throws -> [CoreTypes.NamedCoordinate] {
        let query = """
            SELECT id, name, address, latitude, longitude, type, bin, bbl 
            FROM buildings 
            WHERE isActive = 1
        """
        
        let rows = try await database.query(query)
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String ?? (row["id"] as? Int64).map(String.init),
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lon = row["longitude"] as? Double,
                  let typeStr = row["type"] as? String else {
                return nil
            }
            
            let buildingType = CoreTypes.BuildingType(rawValue: typeStr) ?? .residential
            
            var metadata: [String: Any] = [:]
            if let bin = row["bin"] as? String { metadata["bin"] = bin }
            if let bbl = row["bbl"] as? String { metadata["bbl"] = bbl }
            
            return CoreTypes.NamedCoordinate(
                id: id,
                name: name,
                address: address,
                latitude: lat,
                longitude: lon,
                type: buildingType
            )
        }
    }
    
    private func extractBIN(from building: CoreTypes.NamedCoordinate) -> String {
        // Use building ID as BIN placeholder since NamedCoordinate doesn't have metadata
        return building.id
    }
    
    private func extractBBL(from building: CoreTypes.NamedCoordinate) -> String {
        // Return empty string as placeholder since NamedCoordinate doesn't have metadata
        return ""
    }
    
    private func updateMainComplianceSystem(buildingId: String, nycData: NYCBuildingCompliance) async {
        // Convert NYC data to CoreTypes.ComplianceIssue and save to database
        let issues = getComplianceIssues(for: buildingId)
        
        // Save to database
        for issue in issues {
            try? await saveComplianceIssue(issue)
        }
        
        // Update building compliance score
        try? await updateBuildingComplianceScore(buildingId: buildingId, score: nycData.overallComplianceScore)
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .complianceDataUpdated,
            object: nil,
            userInfo: ["buildingId": buildingId, "score": nycData.overallComplianceScore]
        )
    }
    
    private func saveComplianceIssue(_ issue: CoreTypes.ComplianceIssue) async throws {
        let query = """
            INSERT OR REPLACE INTO compliance_issues 
            (id, building_id, building_name, type, severity, status, title, description, 
             reported_date, due_date, resolved_date, assigned_to, notes, source, external_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let params: [Any?] = [
            issue.id,
            issue.buildingId,
            issue.buildingName,
            issue.type.rawValue,
            issue.severity.rawValue,
            issue.status.rawValue,
            issue.title,
            issue.description,
            issue.reportedDate.timeIntervalSince1970,
            issue.dueDate?.timeIntervalSince1970,
            nil, // resolved_date placeholder
            issue.assignedTo,
            "", // notes placeholder
            "NYC", // source placeholder
            issue.id // external_id = id
        ]
        
        try await database.execute(query, params)
    }
    
    private func updateBuildingComplianceScore(buildingId: String, score: Double) async throws {
        let query = """
            UPDATE buildings 
            SET compliance_score = ?, last_compliance_update = ? 
            WHERE id = ?
        """
        
        try await database.execute(query, [score, Date().timeIntervalSince1970, buildingId])
    }
    
    private func saveComplianceDataToDatabase() async {
        // Cache the raw NYC data for offline access
        for (buildingId, compliance) in complianceData {
            do {
                let data = try JSONEncoder().encode(compliance)
                let query = """
                    INSERT OR REPLACE INTO nyc_compliance_cache 
                    (building_id, data, updated_at) 
                    VALUES (?, ?, ?)
                """
                try await database.execute(query, [buildingId, data, Date().timeIntervalSince1970])
            } catch {
                print("Failed to cache compliance data for building \(buildingId): \(error)")
            }
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Extensions

extension CoreTypes.TaskUrgency {
    func toComplianceSeverity() -> CoreTypes.ComplianceSeverity {
        switch self {
        case .emergency, .critical: return .critical
        case .urgent, .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .normal: return .low
        }
    }
}

extension Notification.Name {
    static let buildingDataUpdated = Notification.Name("buildingDataUpdated")
    static let complianceDataUpdated = Notification.Name("complianceDataUpdated")
}