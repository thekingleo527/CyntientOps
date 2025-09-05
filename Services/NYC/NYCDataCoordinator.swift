//
//  NYCDataCoordinator.swift
//  CyntientOps
//
//  Coordinates NYC API data loading and integration across all dashboards
//

import Foundation
import Combine

@MainActor
public final class NYCDataCoordinator: ObservableObject {
    
    public static let shared = NYCDataCoordinator()
    
    // MARK: - Published State
    @Published public var isInitialized = false
    @Published public var historicalDataLoadingProgress: Double = 0.0
    @Published public var lastFullDataLoad: Date?
    
    private let historicalDataService = NYCHistoricalDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Monitor historical data loading progress
        historicalDataService.$loadingProgress
            .assign(to: &$historicalDataLoadingProgress)
        
        historicalDataService.$lastDataLoadTime
            .assign(to: &$lastFullDataLoad)
    }
    
    // MARK: - Initialization
    
    /// Initialize NYC data systems and load historical data if needed
    public func initializeNYCDataSystems() async {
        print("🏛️ Initializing NYC Data Systems...")
        
        // Check if we need to load historical data
        let needsHistoricalDataLoad = await shouldLoadHistoricalData()
        
        if needsHistoricalDataLoad {
            print("📊 Historical data load required - starting comprehensive data fetch...")
            await historicalDataService.loadHistoricalDataForAllBuildings()
        } else {
            print("✅ Historical data is up to date")
        }
        
        // Initialize real-time compliance monitoring
        await initializeComplianceMonitoring()
        
        isInitialized = true
        print("✅ NYC Data Systems initialized successfully")
    }
    
    /// Check if we need to load historical data
    private func shouldLoadHistoricalData() async -> Bool {
        // Check when historical data was last loaded
        guard let lastLoad = historicalDataService.lastDataLoadTime else {
            print("📋 No previous historical data load found")
            return true
        }
        
        // Reload if data is older than 7 days
        let daysSinceLastLoad = Calendar.current.dateComponents([.day], from: lastLoad, to: Date()).day ?? 0
        
        if daysSinceLastLoad >= 7 {
            print("📅 Historical data is \(daysSinceLastLoad) days old - reload required")
            return true
        }
        
        // Check if we have data for all buildings
        let allBuildings = await getAllBuildingsFromDatabase()
        let buildingsWithData = historicalDataService.getAllBuildingsWithHistoricalData()
        
        if allBuildings.count != buildingsWithData.count {
            print("🏢 Missing historical data for some buildings (\(allBuildings.count) total, \(buildingsWithData.count) with data)")
            return true
        }
        
        return false
    }
    
    /// Initialize real-time compliance monitoring for all buildings
    private func initializeComplianceMonitoring() async {
        // Set up periodic compliance checks
        Task {
            while !Task.isCancelled {
                // Run compliance checks every 4 hours
                try? await Task.sleep(nanoseconds: 4 * 3600 * 1_000_000_000) // 4 hours
                
                await performPeriodicComplianceChecks()
            }
        }
    }
    
    /// Run periodic compliance checks for active violations and permits
    private func performPeriodicComplianceChecks() async {
        print("🔍 Running periodic compliance checks...")
        
        let buildings = await getAllBuildingsFromDatabase()
        
        for building in buildings.prefix(5) { // Limit to 5 buildings per check to respect API limits
            await checkBuildingCompliance(building)
            
            // Rate limiting between buildings
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        }
    }
    
    /// Check compliance status for a specific building
    private func checkBuildingCompliance(_ building: NYCBuildingInfo) async {
        guard !building.bin.isEmpty || !building.bbl.isEmpty else { return }
        
        var activeViolationsCount = 0
        var expiredPermitsCount = 0
        
        // Check HPD violations
        if !building.bin.isEmpty {
            do {
                let hpdViolations = try await NYCAPIService.shared.fetchHPDViolations(bin: building.bin)
                activeViolationsCount = hpdViolations.filter { $0.currentStatusDate == nil }.count
            } catch {
                print("⚠️ Failed to check HPD violations for \(building.name): \(error)")
            }
        }
        
        // Check DOB permits
        if !building.bin.isEmpty {
            do {
                let dobPermits = try await NYCAPIService.shared.fetchDOBPermits(bin: building.bin)
                expiredPermitsCount = dobPermits.filter { $0.isExpired }.count
            } catch {
                print("⚠️ Failed to check DOB permits for \(building.name): \(error)")
            }
        }
        
        if activeViolationsCount > 0 || expiredPermitsCount > 0 {
            print("⚠️ Compliance issues found for \(building.name):")
            print("   - Active HPD violations: \(activeViolationsCount)")
            print("   - Expired DOB permits: \(expiredPermitsCount)")
            
            // Create compliance alerts
            await createComplianceAlert(building: building, hpdViolations: activeViolationsCount, expiredPermits: expiredPermitsCount)
        }
    }
    
    /// Create compliance alerts for dashboard notifications
    private func createComplianceAlert(building: NYCBuildingInfo, hpdViolations: Int, expiredPermits: Int) async {
        let alertMessage = "Compliance issues detected for \(building.name): \(hpdViolations) HPD violations, \(expiredPermits) expired permits"
        
        // Store alert in database for dashboard display
        do {
            try await GRDBManager.shared.execute("""
                INSERT OR REPLACE INTO compliance_alerts 
                (id, building_id, alert_type, message, severity, created_at, is_resolved)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [
                UUID().uuidString,
                building.id,
                "violations_permits",
                alertMessage,
                hpdViolations > 5 ? "high" : "medium",
                ISO8601DateFormatter().string(from: Date()),
                false
            ])
        } catch {
            print("⚠️ Failed to create compliance alert: \(error)")
        }
    }
    
    // MARK: - Data Access Methods
    
    /// Get comprehensive building compliance report
    public func getBuildingComplianceReport(buildingId: String) -> BuildingComplianceReport? {
        guard let historicalData = historicalDataService.getHistoricalData(for: buildingId) else {
            return nil
        }
        
        let activeHPDViolations = historicalData.hpdViolations.filter { $0.currentStatusDate == nil }
        let activeDSNYViolations = historicalData.dsnyViolations.filter { $0.status.lowercased() == "open" }
        let recent311Complaints = historicalData.complaints311.filter { complaint in
            let formatter = ISO8601DateFormatter()
            guard let createdDate = formatter.date(from: complaint.createdDate) else { return false }
            return Calendar.current.dateComponents([.month], from: createdDate, to: Date()).month ?? 0 <= 3
        }
        
        return BuildingComplianceReport(
            buildingId: buildingId,
            buildingName: historicalData.buildingName,
            dataStartDate: historicalData.dataStartDate,
            dataEndDate: historicalData.dataEndDate,
            totalHPDViolations: historicalData.hpdViolations.count,
            activeHPDViolations: activeHPDViolations.count,
            totalDSNYViolations: historicalData.dsnyViolations.count,
            activeDSNYViolations: activeDSNYViolations.count,
            total311Complaints: historicalData.complaints311.count,
            recent311Complaints: recent311Complaints.count,
            totalDOBPermits: historicalData.dobPermits.count,
            expiredDOBPermits: historicalData.dobPermits.filter { $0.isExpired }.count,
            complianceScore: calculateComplianceScore(historicalData: historicalData)
        )
    }
    
    /// Calculate overall compliance score for a building
    private func calculateComplianceScore(historicalData: BuildingHistoricalData) -> Double {
        var score = 100.0
        
        // Deduct points for active violations
        let activeHPD = historicalData.hpdViolations.filter { $0.currentStatusDate == nil }.count
        let activeDSNY = historicalData.dsnyViolations.filter { $0.status.lowercased() == "open" }.count
        let recent311 = historicalData.complaints311.filter { complaint in
            let formatter = ISO8601DateFormatter()
            guard let createdDate = formatter.date(from: complaint.createdDate) else { return false }
            return Calendar.current.dateComponents([.month], from: createdDate, to: Date()).month ?? 0 <= 3
        }.count
        
        score -= Double(activeHPD * 5) // 5 points per active HPD violation
        score -= Double(activeDSNY * 3) // 3 points per active DSNY violation
        score -= Double(recent311 * 1) // 1 point per recent 311 complaint
        
        // Deduct points for expired permits
        let expiredPermits = historicalData.dobPermits.filter { $0.isExpired }.count
        score -= Double(expiredPermits * 2) // 2 points per expired permit
        
        return max(0, min(100, score))
    }
    
    /// Get portfolio-wide compliance statistics
    public func getPortfolioComplianceStatistics() -> PortfolioComplianceStatistics {
        return historicalDataService.getPortfolioComplianceStatistics()
    }
    
    // MARK: - Database Helpers
    
    private func getAllBuildingsFromDatabase() async -> [NYCBuildingInfo] {
        do {
            let results = try await GRDBManager.shared.query(
                "SELECT id, name, address, bbl, bin FROM buildings ORDER BY name",
                []
            )
            
            return results.map { row in
                NYCBuildingInfo(
                    id: row["id"] as? String ?? "",
                    name: row["name"] as? String ?? "",
                    address: row["address"] as? String ?? "",
                    bbl: row["bbl"] as? String ?? "",
                    bin: row["bin"] as? String ?? ""
                )
            }
        } catch {
            print("⚠️ Failed to get buildings from database: \(error)")
            return []
        }
    }
}

// MARK: - Supporting Data Models

public struct BuildingComplianceReport {
    let buildingId: String
    let buildingName: String
    let dataStartDate: Date
    let dataEndDate: Date
    let totalHPDViolations: Int
    let activeHPDViolations: Int
    let totalDSNYViolations: Int
    let activeDSNYViolations: Int
    let total311Complaints: Int
    let recent311Complaints: Int
    let totalDOBPermits: Int
    let expiredDOBPermits: Int
    let complianceScore: Double
    
    var hasActiveIssues: Bool {
        return activeHPDViolations > 0 || activeDSNYViolations > 0 || expiredDOBPermits > 0
    }
    
    var riskLevel: String {
        if complianceScore >= 90 { return "Low" }
        if complianceScore >= 70 { return "Medium" }
        if complianceScore >= 50 { return "High" }
        return "Critical"
    }
}