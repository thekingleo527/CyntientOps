//
//  NYCHistoricalDataService.swift
//  CyntientOps
//
//  Comprehensive Historical Data Loading Service
//  Loads 1 year of NYC compliance history for each building
//

import Foundation
import Combine

// MARK: - NYC Building Info Structure

public struct NYCBuildingInfo {
    public let id: String
    public let name: String
    public let address: String
    public let bbl: String
    public let bin: String
    
    public init(id: String, name: String, address: String, bbl: String, bin: String) {
        self.id = id
        self.name = name
        self.address = address
        self.bbl = bbl
        self.bin = bin
    }
}

@MainActor
public final class NYCHistoricalDataService: ObservableObject {
    
    public static let shared = NYCHistoricalDataService()
    
    // MARK: - Published State
    @Published public var isLoading = false
    @Published public var loadingProgress: Double = 0.0
    @Published public var loadedBuildingsCount: Int = 0
    @Published public var totalBuildingsCount: Int = 0
    
    // MARK: - Historical Data Storage
    @Published public var buildingHistoricalData: [String: BuildingHistoricalData] = [:]
    @Published public var lastDataLoadTime: Date?
    
    private let nycAPIService = NYCAPIService.shared
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    // MARK: - Main Loading Method
    
    /// Load historical NYC data for all buildings in the portfolio
    /// - Parameter months: number of months of history to load (default 12)
    public func loadHistoricalDataForAllBuildings(months: Int = 12) async {
        print("🏛️ Starting comprehensive historical data load for all buildings...")
        
        isLoading = true
        loadingProgress = 0.0
        loadedBuildingsCount = 0
        
        // Get all buildings from database
        let buildings = await getAllBuildingsFromDatabase()
        totalBuildingsCount = buildings.count
        
        print("📊 Loading historical data for \(totalBuildingsCount) buildings")
        
        // Load data for each building with rate limiting
        for (index, building) in buildings.enumerated() {
            await loadHistoricalDataForBuilding(building, months: months)
            
            loadedBuildingsCount = index + 1
            loadingProgress = Double(loadedBuildingsCount) / Double(totalBuildingsCount)
            
            // Rate limiting: 3.6 seconds between building loads to respect NYC OpenData limits
            if index < buildings.count - 1 {
                try? await Task.sleep(nanoseconds: 3_600_000_000) // 3.6 seconds
            }
        }
        
        lastDataLoadTime = Date()
        isLoading = false
        
        print("✅ Historical data loading complete! Loaded data for \(loadedBuildingsCount) buildings")
    }
    
    /// Load historical data for a specific building
    public func loadHistoricalDataForBuilding(_ building: NYCBuildingInfo, months: Int = 12) async {
        print("🏢 Loading historical data for: \(building.name)")
        
        let startDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        let endDate = Date()
        
        var historicalData = BuildingHistoricalData(
            buildingId: building.id,
            buildingName: building.name,
            bbl: building.bbl,
            bin: building.bin,
            loadedDate: Date(),
            dataStartDate: startDate,
            dataEndDate: endDate
        )
        
        // Load all historical data types concurrently
        await withTaskGroup(of: Void.self) { group in
            // HPD Violations History
            group.addTask {
                await self.loadHPDViolationsHistory(building: building, into: &historicalData)
            }
            
            // DSNY Violations History
            group.addTask {
                await self.loadDSNYViolationsHistory(building: building, into: &historicalData)
            }
            
            // 311 Complaints History
            group.addTask {
                await self.load311ComplaintsHistory(building: building, into: &historicalData)
            }
            
            // DOB Permits History
            group.addTask {
                await self.loadDOBPermitsHistory(building: building, into: &historicalData)
            }
            
            // FDNY Inspections History
            group.addTask {
                await self.loadFDNYInspectionsHistory(building: building, into: &historicalData)
            }
            
            // DOF Tax History
            group.addTask {
                await self.loadDOFTaxHistory(building: building, into: &historicalData)
            }
        }
        
        // Store in cache and database
        buildingHistoricalData[building.id] = historicalData
        await saveHistoricalDataToDatabase(historicalData)
        
        print("✅ Completed historical data load for: \(building.name)")
        print("   - HPD Violations: \(historicalData.hpdViolations.count)")
        print("   - DSNY Violations: \(historicalData.dsnyViolations.count)")
        print("   - 311 Complaints: \(historicalData.complaints311.count)")
        print("   - DOB Permits: \(historicalData.dobPermits.count)")
        print("   - FDNY Inspections: \(historicalData.fdnyInspections.count)")
        print("   - DOF Tax Records: \(historicalData.dofTaxRecords.count)")
    }
    
    // MARK: - Individual Data Type Loaders
    
    private func loadHPDViolationsHistory(building: NYCBuildingInfo, into data: inout BuildingHistoricalData) async {
        guard !building.bin.isEmpty else { return }
        
        do {
            let startDateString = ISO8601DateFormatter().string(from: data.dataStartDate)
            let endDateString = ISO8601DateFormatter().string(from: data.dataEndDate)
            
            // Fetch HPD violations for the past year
            let violations = try await nycAPIService.fetchHPDViolationsWithDateRange(
                bin: building.bin,
                startDate: startDateString,
                endDate: endDateString
            )
            
            data.hpdViolations = violations
            print("   📋 Loaded \(violations.count) HPD violations for \(building.name)")
        } catch {
            print("⚠️ Failed to load HPD violations for \(building.name): \(error)")
        }
    }
    
    private func loadDSNYViolationsHistory(building: NYCBuildingInfo, into data: inout BuildingHistoricalData) async {
        guard !building.bin.isEmpty else { return }
        
        do {
            let startDateString = ISO8601DateFormatter().string(from: data.dataStartDate)
            let endDateString = ISO8601DateFormatter().string(from: data.dataEndDate)
            
            let violations = try await nycAPIService.fetchDSNYViolationsWithDateRange(
                bin: building.bin,
                startDate: startDateString,
                endDate: endDateString
            )
            
            data.dsnyViolations = violations
            print("   🗑️ Loaded \(violations.count) DSNY violations for \(building.name)")
        } catch {
            print("⚠️ Failed to load DSNY violations for \(building.name): \(error)")
        }
    }
    
    private func load311ComplaintsHistory(building: NYCBuildingInfo, into data: inout BuildingHistoricalData) async {
        guard !building.bin.isEmpty else { return }
        
        do {
            let startDateString = ISO8601DateFormatter().string(from: data.dataStartDate)
            let endDateString = ISO8601DateFormatter().string(from: data.dataEndDate)
            
            let complaints = try await nycAPIService.fetchComplaints311WithDateRange(
                bin: building.bin,
                startDate: startDateString,
                endDate: endDateString
            )
            
            data.complaints311 = complaints
            print("   📞 Loaded \(complaints.count) 311 complaints for \(building.name)")
        } catch {
            print("⚠️ Failed to load 311 complaints for \(building.name): \(error)")
        }
    }
    
    private func loadDOBPermitsHistory(building: NYCBuildingInfo, into data: inout BuildingHistoricalData) async {
        guard !building.bin.isEmpty else { return }
        
        do {
            let startDateString = ISO8601DateFormatter().string(from: data.dataStartDate)
            let endDateString = ISO8601DateFormatter().string(from: data.dataEndDate)
            
            let permits = try await nycAPIService.fetchDOBPermitsWithDateRange(
                bin: building.bin,
                startDate: startDateString,
                endDate: endDateString
            )
            
            data.dobPermits = permits
            print("   🏗️ Loaded \(permits.count) DOB permits for \(building.name)")
        } catch {
            print("⚠️ Failed to load DOB permits for \(building.name): \(error)")
        }
    }
    
    private func loadFDNYInspectionsHistory(building: NYCBuildingInfo, into data: inout BuildingHistoricalData) async {
        guard !building.bin.isEmpty else { return }
        
        do {
            let startDateString = ISO8601DateFormatter().string(from: data.dataStartDate)
            let endDateString = ISO8601DateFormatter().string(from: data.dataEndDate)
            
            let inspections = try await nycAPIService.fetchFDNYInspectionsWithDateRange(
                bin: building.bin,
                startDate: startDateString,
                endDate: endDateString
            )
            
            data.fdnyInspections = inspections
            print("   🚒 Loaded \(inspections.count) FDNY inspections for \(building.name)")
        } catch {
            print("⚠️ Failed to load FDNY inspections for \(building.name): \(error)")
        }
    }
    
    private func loadDOFTaxHistory(building: NYCBuildingInfo, into data: inout BuildingHistoricalData) async {
        guard !building.bbl.isEmpty else { return }
        
        do {
            let taxBills = try await nycAPIService.fetchDOFTaxBills(bbl: building.bbl)
            let taxLiens = try await nycAPIService.fetchDOFTaxLiens(bbl: building.bbl)
            
            // Filter to past year
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            
            data.dofTaxRecords = taxBills.filter { bill in
                // Filter by paid date if available, otherwise include recent years
                if let paidDate = bill.paidDate {
                    let formatter = ISO8601DateFormatter()
                    guard let date = formatter.date(from: paidDate) else { return true }
                    return date >= oneYearAgo
                }
                // If no paid date, filter by fiscal year (include current and previous year)
                let currentYear = Calendar.current.component(.year, from: Date())
                let billYear = Int(bill.year) ?? 0
                return billYear >= currentYear - 1
            }
            
            data.dofTaxLiens = taxLiens.filter { lien in
                // Filter by sale date if available, otherwise include all liens
                if let saleDate = lien.saleDate {
                    let formatter = ISO8601DateFormatter()
                    guard let date = formatter.date(from: saleDate) else { return true }
                    return date >= oneYearAgo
                }
                return true // Include all liens without sale dates
            }
            
            print("   💰 Loaded \(data.dofTaxRecords.count) tax records and \(data.dofTaxLiens.count) liens for \(building.name)")
        } catch {
            print("⚠️ Failed to load DOF tax history for \(building.name): \(error)")
        }
    }
    
    // MARK: - Database Operations
    
    private func getAllBuildingsFromDatabase() async -> [NYCBuildingInfo] {
        do {
            let results = try await grdbManager.query(
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
    
    private func saveHistoricalDataToDatabase(_ data: BuildingHistoricalData) async {
        // Save to a historical_data table for persistence and quick access
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(data)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO building_historical_data 
                (building_id, data_json, loaded_date, data_start_date, data_end_date)
                VALUES (?, ?, ?, ?, ?)
            """, [
                data.buildingId,
                jsonString,
                data.loadedDate,
                data.dataStartDate,
                data.dataEndDate
            ])
        } catch {
            print("⚠️ Failed to save historical data for building \(data.buildingId): \(error)")
        }
    }
    
    // MARK: - Public Access Methods
    
    /// Get historical data for a specific building
    public func getHistoricalData(for buildingId: String) -> BuildingHistoricalData? {
        return buildingHistoricalData[buildingId]
    }
    
    /// Get all buildings with loaded historical data
    public func getAllBuildingsWithHistoricalData() -> [BuildingHistoricalData] {
        return Array(buildingHistoricalData.values)
    }
    
    /// Get aggregated compliance statistics across all buildings
    public func getPortfolioComplianceStatistics() -> PortfolioComplianceStatistics {
        let allData = Array(buildingHistoricalData.values)
        
        let totalHPDViolations = allData.reduce(0) { $0 + $1.hpdViolations.count }
        let totalDSNYViolations = allData.reduce(0) { $0 + $1.dsnyViolations.count }
        let total311Complaints = allData.reduce(0) { $0 + $1.complaints311.count }
        let totalDOBPermits = allData.reduce(0) { $0 + $1.dobPermits.count }
        let totalFDNYInspections = allData.reduce(0) { $0 + $1.fdnyInspections.count }
        
        return PortfolioComplianceStatistics(
            buildingsWithData: allData.count,
            totalHPDViolations: totalHPDViolations,
            totalDSNYViolations: totalDSNYViolations,
            total311Complaints: total311Complaints,
            totalDOBPermits: totalDOBPermits,
            totalFDNYInspections: totalFDNYInspections,
            averageViolationsPerBuilding: allData.isEmpty ? 0 : Double(totalHPDViolations + totalDSNYViolations) / Double(allData.count)
        )
    }
}

// MARK: - Data Models

public struct BuildingHistoricalData: Codable {
    let buildingId: String
    let buildingName: String
    let bbl: String
    let bin: String
    let loadedDate: Date
    let dataStartDate: Date
    let dataEndDate: Date
    
    var hpdViolations: [HPDViolation] = []
    var dsnyViolations: [DSNYViolation] = []
    var complaints311: [Complaint311] = []
    var dobPermits: [DOBPermit] = []
    var fdnyInspections: [FDNYInspection] = []
    var dofTaxRecords: [DOFTaxBill] = []
    var dofTaxLiens: [DOFTaxLien] = []
}

public struct PortfolioComplianceStatistics {
    let buildingsWithData: Int
    let totalHPDViolations: Int
    let totalDSNYViolations: Int
    let total311Complaints: Int
    let totalDOBPermits: Int
    let totalFDNYInspections: Int
    let averageViolationsPerBuilding: Double
}

// MARK: - NYC API Service Extensions

extension NYCAPIService {
    
    /// Fetch HPD violations with date range
    public func fetchHPDViolationsWithDateRange(bin: String, startDate: String, endDate: String) async throws -> [HPDViolation] {
        let endpoint = "\(APIConfig.hpdURL)?bin=\(bin)&$where=inspectiondate between '\(startDate)' and '\(endDate)'&$limit=5000"
        return try await fetchFromURL(endpoint)
    }
    
    /// Fetch DSNY violations with date range
    public func fetchDSNYViolationsWithDateRange(bin: String, startDate: String, endDate: String) async throws -> [DSNYViolation] {
        let endpoint = "\(APIConfig.dsnyViolationsURL)?bin=\(bin)&$where=issue_date between '\(startDate)' and '\(endDate)'&$limit=5000"
        return try await fetchFromURL(endpoint)
    }
    
    /// Fetch 311 complaints with date range
    public func fetchComplaints311WithDateRange(bin: String, startDate: String, endDate: String) async throws -> [Complaint311] {
        let endpoint = "\(APIConfig.complaints311URL)?bin=\(bin)&$where=created_date between '\(startDate)' and '\(endDate)'&$limit=5000"
        return try await fetchFromURL(endpoint)
    }
    
    /// Fetch DOB permits with date range
    public func fetchDOBPermitsWithDateRange(bin: String, startDate: String, endDate: String) async throws -> [DOBPermit] {
        let endpoint = "\(APIConfig.dobURL)?bin=\(bin)&$where=issuance_date between '\(startDate)' and '\(endDate)'&$limit=5000"
        return try await fetchFromURL(endpoint)
    }
    
    /// Fetch FDNY inspections with date range
    public func fetchFDNYInspectionsWithDateRange(bin: String, startDate: String, endDate: String) async throws -> [FDNYInspection] {
        let endpoint = "\(APIConfig.fdnyURL)?bin=\(bin)&$where=inspection_date between '\(startDate)' and '\(endDate)'&$limit=5000"
        return try await fetchFromURL(endpoint)
    }
    
    /// Generic fetch method for URL endpoints
    func fetchFromURL<T: Codable>(_ urlString: String) async throws -> [T] {
        guard let url = URL(string: urlString) else {
            throw NYCAPIError.invalidURL(urlString)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([T].self, from: data)
    }
}

// MARK: - Monthly Aggregator

public struct MonthlyAggregates {
    public let months: [String]
    public let hpdViolations: [String: Int]
    public let dsnyViolations: [String: Int]
    public let complaints311: [String: Int]
    public let dobPermits: [String: Int]
    public let fdnyInspections: [String: Int]
}

extension NYCHistoricalDataService {
    /// Compute simple monthly aggregates (YYYY-MM) for a building from loaded historical data
    public func getMonthlyAggregates(for buildingId: String) -> MonthlyAggregates? {
        guard let data = buildingHistoricalData[buildingId] else { return nil }
        var monthsSet = Set<String>()
        var hpd: [String: Int] = [:]
        var dsny: [String: Int] = [:]
        var c311: [String: Int] = [:]
        var dob: [String: Int] = [:]
        var fdny: [String: Int] = [:]

        // Helpers
        func monthKey(_ d: Date) -> String {
            let comps = Calendar.current.dateComponents([.year, .month], from: d)
            let y = comps.year ?? 0
            let m = comps.month ?? 0
            return String(format: "%04d-%02d", y, m)
        }
        func bump(_ dict: inout [String: Int], key: String) { dict[key, default: 0] += 1 }

        // HPD (inspectionDate is String)
        let iso = ISO8601DateFormatter()
        for v in data.hpdViolations {
            if let s = v.inspectionDate as String?, let d = iso.date(from: s) {
                let k = monthKey(d); monthsSet.insert(k); bump(&hpd, key: k)
            }
        }
        // DSNY violations (issueDate is String)
        for v in data.dsnyViolations {
            if let d = iso.date(from: v.issueDate) {
                let k = monthKey(d); monthsSet.insert(k); bump(&dsny, key: k)
            }
        }
        // 311 complaints (createdDate is String)
        for c in data.complaints311 {
            if let d = iso.date(from: c.createdDate) {
                let k = monthKey(d); monthsSet.insert(k); bump(&c311, key: k)
            }
        }
        // DOB permits (issuanceDate is String?)
        for p in data.dobPermits {
            if let s = p.issuanceDate, let d = iso.date(from: s) {
                let k = monthKey(d); monthsSet.insert(k); bump(&dob, key: k)
            }
        }
        // FDNY inspections (inspectionDate is String)
        for i in data.fdnyInspections {
            if let d = iso.date(from: i.inspectionDate) {
                let k = monthKey(d); monthsSet.insert(k); bump(&fdny, key: k)
            }
        }

        let months = monthsSet.sorted()
        return MonthlyAggregates(months: months, hpdViolations: hpd, dsnyViolations: dsny, complaints311: c311, dobPermits: dob, fdnyInspections: fdny)
    }
}
