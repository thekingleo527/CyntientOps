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

            // Batch primary SODA datasets to reduce rate limiting
            let bins = buildings.map { extractBIN(from: $0) }.filter { !$0.isEmpty }
            let bbls = buildings.map { extractBBL(from: $0) }.filter { !$0.isEmpty }

            // Last 12 months is a reasonable window for dashboard recency while limiting payload
            let hpdByBin = (try? await nycAPI.fetchHPDViolations(bins: bins, months: 12)) ?? [:]
            let dobByBin = (try? await nycAPI.fetchDOBPermits(bins: bins, months: 12)) ?? [:]
            let dsnyByBin = (try? await nycAPI.fetchDSNYViolations(bins: bins, months: 12)) ?? [:]

            for (index, building) in buildings.enumerated() {
                if building.name.localizedCaseInsensitiveContains("Stuyvesant Cove Park") { continue }
                let bin = extractBIN(from: building)
                let bbl = extractBBL(from: building)

                var hpd = hpdByBin[bin] ?? []
                var dob = dobByBin[bin] ?? []
                var dsny = dsnyByBin[bin] ?? []

                // Address fallbacks like DSNY: apply to HPD/DOB as well
                // Skip API calls for parks and other non-building locations
                if hpd.isEmpty && !isNonBuildingLocation(building) {
                    let addr = "\(building.name), \(building.address)"
                    if let byAddr = try? await nycAPI.fetchHPDViolations(address: addr), !byAddr.isEmpty { hpd = byAddr }
                    else if let byAddr2 = try? await nycAPI.fetchHPDViolations(address: building.address), !byAddr2.isEmpty { hpd = byAddr2 }
                }
                if dob.isEmpty && !isNonBuildingLocation(building) {
                    let addr = "\(building.name), \(building.address)"
                    if let byAddr = try? await nycAPI.fetchDOBPermits(address: addr), !byAddr.isEmpty { dob = byAddr }
                    else if let byAddr2 = try? await nycAPI.fetchDOBPermits(address: building.address), !byAddr2.isEmpty { dob = byAddr2 }
                }
                if dsny.isEmpty && !isNonBuildingLocation(building) {
                    if !bbl.isEmpty, let byBBL = try? await nycAPI.fetchOATHDSNYViolations(bbl: bbl), !byBBL.isEmpty {
                        dsny = byBBL
                    } else {
                        let addr = "\(building.name), \(building.address)"
                        if let byAddr = try? await nycAPI.fetchDSNYViolations(address: addr), !byAddr.isEmpty { dsny = byAddr }
                        else if let byAddr2 = try? await nycAPI.fetchDSNYViolations(address: building.address), !byAddr2.isEmpty { dsny = byAddr2 }
                        else {
                            // Robust fallback: map relevant 311 complaints (sanitation-related) into DSNYViolation-like records
                            if let complaints = try? await nycAPI.fetch311Complaints(address: building.address) {
                                let relevant = complaints.filter { c in
                                    let t = c.complaintType.lowercased()
                                    return t.contains("sanitation") || t.contains("dirty") || t.contains("missed") || t.contains("encampment") || t.contains("illegal dumping")
                                }
                                dsny = relevant.map { c in
                                    DSNYViolation(
                                        violationId: c.uniqueKey,
                                        bin: bin,
                                        issueDate: c.createdDate,
                                        hearingDate: nil,
                                        violationType: c.complaintType,
                                        fineAmount: nil,
                                        status: c.status,
                                        borough: c.borough,
                                        address: c.incidentAddress,
                                        violationDetails: c.descriptor,
                                        dispositionCode: nil,
                                        dispositionDate: c.closedDate
                                    )
                                }
                            }
                        }
                    }
                }

                // LL97 by BBL (targeted per building to keep payloads reasonable)
                let ll97 = (try? await nycAPI.fetchLL97Compliance(bbl: bbl)) ?? []

                let nycCompliance = NYCBuildingCompliance(
                    bin: bin,
                    bbl: bbl,
                    lastUpdated: Date(),
                    hpdViolations: hpd,
                    dobPermits: dob,
                    fdnyInspections: [],
                    ll97Data: ll97,
                    complaints311: [],
                    depWaterData: [],
                    dsnySchedule: [],
                    dsnyViolations: dsny
                )

                complianceData[building.id] = nycCompliance
                await updateMainComplianceSystem(buildingId: building.id, nycData: nycCompliance)

                // Progress update
                syncProgress = Double(index + 1) / totalBuildings

                // Gentle pacing between per-building LL97 calls
                try? await Task.sleep(nanoseconds: 300_000_000)
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
        
        let buildingCompliance = await nycAPI.fetchBuildingCompliance(bin: bin, bbl: bbl, address: building.address)
        
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
            depWaterData: [],
            dsnySchedule: buildingCompliance.dsnyRoutes,
            dsnyViolations: buildingCompliance.dsnyViolations
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

    // MARK: - Convenience Accessors for Dashboards

    /// Get HPD violations for a building (raw NYC model)
    public func getHPDViolations(for buildingId: String) -> [HPDViolation] {
        complianceData[buildingId]?.hpdViolations ?? []
    }

    /// Get DOB permits for a building (raw NYC model)
    public func getDOBPermits(for buildingId: String) -> [DOBPermit] {
        complianceData[buildingId]?.dobPermits ?? []
    }

    /// Get DSNY schedule routes for a building (raw NYC model)
    public func getDSNYSchedule(for buildingId: String) -> [DSNYRoute] {
        complianceData[buildingId]?.dsnySchedule ?? []
    }

    /// Get DSNY violations for a building (raw NYC model)
    public func getDSNYViolations(for buildingId: String) -> [DSNYViolation] {
        complianceData[buildingId]?.dsnyViolations ?? []
    }

    /// Get LL97 emissions data for a building (raw NYC model)
    public func getLL97Emissions(for buildingId: String) -> [LL97Emission] {
        complianceData[buildingId]?.ll97Data ?? []
    }
    
    /// Approximate next LL97 reporting due date based on latest reporting year (due May 1 next year)
    public func getLL97NextDueDate(buildingId: String) -> Date? {
        let emissions = getLL97Emissions(for: buildingId)
        guard let latestYearString = emissions.compactMap({ Int($0.reportingYear) }).max() else { return nil }
        var comps = DateComponents()
        comps.year = latestYearString + 1
        comps.month = 5
        comps.day = 1
        return Calendar.current.date(from: comps)
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

    // MARK: - LL11 / FISP Facade Helpers
    
    /// Get facade filings (FISP/LL11) from DOB permits for a building
    public func getFacadeHistory(buildingId: String) async -> [FacadeFiling] {
        guard let building = try? await getBuildingsFromDatabase().first(where: { $0.id == buildingId }) else { return [] }
        let bin = extractBIN(from: building)
        do {
            let permits = try await nycAPI.fetchDOBPermits(bin: bin)
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            let filings = permits.filter { p in
                let t = (p.workType + " " + (p.description ?? "")).uppercased()
                return t.contains("FACADE") || t.contains("FAÇADE") || t.contains("FISP") || t.contains("LOCAL LAW 11") || t.contains("LL11")
            }.map { p in
                FacadeFiling(
                    id: p.jobNumber,
                    filingDate: df.date(from: p.filingDate),
                    issuanceDate: p.issuanceDate.flatMap { df.date(from: $0) },
                    expirationDate: p.expirationDate.flatMap { df.date(from: $0) },
                    workType: p.workType,
                    description: p.description,
                    status: p.permitStatus
                )
            }
            return filings.sorted { (a, b) in
                let da = a.issuanceDate ?? a.filingDate ?? Date.distantPast
                let db = b.issuanceDate ?? b.filingDate ?? Date.distantPast
                return da > db
            }
        } catch {
            return []
        }
    }
    
    /// Approximate next LL11 due date based on most recent facade filing (5-year cycles)
    public func getLL11NextDueDate(buildingId: String) async -> Date? {
        let history = await getFacadeHistory(buildingId: buildingId)
        guard let mostRecent = history.first else { return nil }
        let base = mostRecent.issuanceDate ?? mostRecent.filingDate
        if let baseDate = base {
            return Calendar.current.date(byAdding: .year, value: 5, to: baseDate)
        } else {
            return nil
        }
    }
    
    /// Fetch HPD violations for last year for a building using NYC API
    public func fetchHPDViolationsLastYear(buildingId: String) async -> [HPDViolation] {
        guard let building = try? await getBuildingsFromDatabase().first(where: { $0.id == buildingId }) else { return [] }
        let bin = extractBIN(from: building)
        do {
            let all = try await nycAPI.fetchHPDViolations(bin: bin)
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            let alt = DateFormatter(); alt.dateFormat = "yyyy-MM-dd"
            let cutoff = Date().addingTimeInterval(-365*86400)
            return all.filter { v in
                let issued = df.date(from: v.novIssued) ?? alt.date(from: v.novIssued) ?? Date.distantPast
                return issued >= cutoff
            }
        } catch {
            return []
        }
    }
    
    /// Fetch DSNY violations for last year for a building using NYC API
    public func fetchDSNYViolationsLastYear(buildingId: String) async -> [DSNYViolation] {
        guard let building = try? await getBuildingsFromDatabase().first(where: { $0.id == buildingId }) else { return [] }
        let bin = extractBIN(from: building)
        do {
            let all = try await nycAPI.fetchDSNYViolations(bin: bin)
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let cutoff = Date().addingTimeInterval(-365*86400)
            return all.filter { v in
                let issued = df.date(from: v.issueDate) ?? Date.distantPast
                return issued >= cutoff
            }
        } catch {
            return []
        }
    }
    
    /// Get recent violations across all buildings since a cutoff
    /// Aggregates HPD and DSNY violations updated after the given date
    public func getRecentViolations(since cutoff: Date) async -> [RecentNYCViolation] {
        var results: [RecentNYCViolation] = []
        let calendar = Calendar.current
        
        for (buildingId, data) in complianceData {
            // HPD
            for v in data.hpdViolations {
                let issued = parseDate(v.novIssued) ?? Date.distantPast
                if issued >= cutoff {
                    results.append(RecentNYCViolation(
                        id: v.violationId,
                        buildingId: buildingId,
                        source: "HPD",
                        description: v.novDescription,
                        severity: v.severity,
                        reportedDate: issued
                    ))
                }
            }
            // DSNY
            for v in data.dsnyViolations {
                let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
                let issued = formatter.date(from: v.issueDate) ?? Date.distantPast
                if issued >= cutoff {
                    results.append(RecentNYCViolation(
                        id: v.violationId,
                        buildingId: buildingId,
                        source: "DSNY",
                        description: v.violationDetails ?? v.violationType,
                        severity: .medium,
                        reportedDate: issued
                    ))
                }
            }
        }
        return results.sorted { $0.reportedDate > $1.reportedDate }
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
            SELECT id, name, address, latitude, longitude, bin_number, bbl 
            FROM buildings
        """
        
        let rows = try await database.query(query)
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String ?? (row["id"] as? Int64).map(String.init),
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lon = row["longitude"] as? Double else {
                return nil
            }
            
            // Default to residential since we don't have type column
            let buildingType = CoreTypes.BuildingType.residential
            
            var metadata: [String: Any] = [:]
            if let bin = row["bin_number"] as? String { metadata["bin"] = bin }
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
        // 1) DB first
        let binFromDB: String = (try? GRDBManager.shared.database.read({ db in
            try (String.fetchOne(db, sql: "SELECT bin FROM buildings WHERE id = ?", arguments: [building.id]) ?? "")
        })) ?? ""
        if !binFromDB.isEmpty { return binFromDB }
        // 2) API Service fallback
        return NYCAPIService.shared.extractBIN(from: building)
    }
    
    private func extractBBL(from building: CoreTypes.NamedCoordinate) -> String {
        // 1) DB first
        let bblFromDB: String = (try? GRDBManager.shared.database.read({ db in
            try (String.fetchOne(db, sql: "SELECT bbl FROM buildings WHERE id = ?", arguments: [building.id]) ?? "")
        })) ?? ""
        if !bblFromDB.isEmpty { return bblFromDB }
        // 2) API Service fallback
        return NYCAPIService.shared.extractBBL(from: building)
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
            (id, buildingId, title, description, severity, status, type, dueDate, assignedTo, 
             created_at, updated_at, source, external_id, notes, reported_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let params: [Any] = [
            issue.id,
            issue.buildingId ?? NSNull(),
            issue.title,
            issue.description,
            issue.severity.rawValue,
            issue.status.rawValue,
            issue.type.rawValue,
            issue.dueDate?.ISO8601Format() ?? "",
            issue.assignedTo ?? "",
            issue.createdAt.ISO8601Format(),
            Date().ISO8601Format(),
            "NYC", // source
            issue.id, // external_id = id
            "", // notes placeholder
            issue.reportedDate.timeIntervalSince1970 // reported_date
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
    
    /// Check if a location is a park or other non-building that shouldn't be queried for building violations
    private func isNonBuildingLocation(_ building: CoreTypes.NamedCoordinate) -> Bool {
        // Parks and other public spaces that don't have traditional building compliance data
        let nonBuildingLocations = ["16"] // Stuyvesant Cove Park
        return nonBuildingLocations.contains(building.id) ||
               building.name.localizedCaseInsensitiveContains("park") ||
               building.address.localizedCaseInsensitiveContains("greenway") ||
               building.address.localizedCaseInsensitiveContains("pier")
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Recent Violation Model
public struct RecentNYCViolation: Identifiable {
    public let id: String
    public let buildingId: String
    public let source: String // HPD, DSNY, etc.
    public let description: String
    public let severity: CoreTypes.ComplianceSeverity
    public let reportedDate: Date
}

// MARK: - Facade (LL11/FISP) Models
public struct FacadeFiling: Identifiable {
    public let id: String
    public let filingDate: Date?
    public let issuanceDate: Date?
    public let expirationDate: Date?
    public let workType: String?
    public let description: String?
    public let status: String?
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
