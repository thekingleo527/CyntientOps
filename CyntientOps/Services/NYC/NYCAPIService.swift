//
//  NYCAPIService.swift
//  CyntientOps Phase 5
//
//  NYC API Integration Service for real-time compliance monitoring
//  Integrates with HPD, DOB, DSNY, LL97, DEP, FDNY, ConEd, and 311 APIs
//

import Foundation
import Combine

@MainActor
public final class NYCAPIService: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = NYCAPIService()
    
    // MARK: - Published State
    @Published public var isConnected = false
    @Published public var lastSyncTime: Date?
    @Published public var apiStatus: [APIEndpoint: APIStatus] = [:]
    
    // MARK: - Private Properties
    private let session: URLSession
    private let cache: CacheManager
    private let keychainManager: KeychainManager
    private var cancellables = Set<AnyCancellable>()
    
    // API Configuration
    internal struct APIConfig {
        static let baseURL = "https://data.cityofnewyork.us/resource/"
        static let hpdURL = "https://data.cityofnewyork.us/resource/wvxf-dwi5.json" // HPD Violations
        static let dobURL = "https://data.cityofnewyork.us/resource/ipu4-2q9a.json" // DOB Permits
        static let dsnyURL = "https://data.cityofnewyork.us/resource/ebb7-mvp5.json" // DSNY Routes
        static let dsnyViolationsURL = "https://data.cityofnewyork.us/resource/weg2-hvnf.json" // DSNY Violations
        static let ll97URL = "https://data.cityofnewyork.us/resource/8vys-2eex.json" // LL97 Emissions
        static let depURL = "https://data.cityofnewyork.us/resource/66be-66yr.json"  // DEP Water
        static let fdnyURL = "https://data.cityofnewyork.us/resource/3h2n-5cm9.json" // FDNY Inspections
        static let complaints311URL = "https://data.cityofnewyork.us/resource/erm2-nwe9.json" // 311 Complaints
        static let dofURL = "https://data.cityofnewyork.us/resource/yjxr-fw9i.json" // DOF Property Assessment
        static let dofTaxBillsURL = "https://data.cityofnewyork.us/resource/wdu4-qxpx.json" // DOF Tax Bills
        static let dofTaxLiensURL = "https://data.cityofnewyork.us/resource/9rz4-mjek.json" // DOF Tax Liens
        static let energyEfficiencyURL = "https://data.cityofnewyork.us/resource/usc3-8zwd.json" // Energy Efficiency Ratings
        static let landmarksBuildingsURL = "https://data.cityofnewyork.us/resource/ju8n-zjd8.json" // LPC Landmarks
        static let buildingFootprintsURL = "https://data.cityofnewyork.us/resource/nqwf-w8eh.json" // Building Footprints
        static let activeConstructionURL = "https://data.cityofnewyork.us/resource/ic3t-wcy2.json" // Active Construction Projects
        static let businessLicensesURL = "https://data.cityofnewyork.us/resource/w7w3-xahh.json" // Business Licenses
        static let airQualityURL = "https://data.cityofnewyork.us/resource/c3uy-2p5r.json" // Air Quality Complaints
        
        // Rate limiting: NYC OpenData allows 1000 calls/hour per endpoint
        static let rateLimitDelay: TimeInterval = 3.6 // seconds between calls
        static let cacheTimeout: TimeInterval = 3600 // 1 hour cache
    }
    
    // MARK: - API Endpoints
    public enum APIEndpoint: Hashable {
        case hpdViolations(bin: String)
        case dobPermits(bin: String)
        case dsnySchedule(district: String)
        case dsnyViolations(bin: String)
        case ll97Compliance(bbl: String)
        case depWaterUsage(account: String)
        case fdnyInspections(bin: String)
        case conEdisonOutages(zip: String)
        case complaints311(bin: String)
        case complaints311Address(address: String)
        case dofPropertyAssessment(bbl: String)
        case dofTaxBills(bbl: String)
        case dofTaxLiens(bbl: String)
        case energyEfficiencyRating(bbl: String)
        case landmarksBuildings(bbl: String)
        case buildingFootprints(bin: String)
        case buildingFootprintsNearby(lat: Double, lon: Double, radiusMeters: Int)
        case activeConstruction(address: String)
        case businessLicenses(address: String)
        case airQualityComplaints(address: String)
        
        var url: String {
            switch self {
            case .hpdViolations(let bin):
                return "\(APIConfig.hpdURL)?bin=\(bin)"
            case .dobPermits(let bin):
                // DOB Permit Issuance dataset uses column name `bin__`
                return "\(APIConfig.dobURL)?bin__=\(bin)"
            case .dsnySchedule(let district):
                return "\(APIConfig.dsnyURL)?community_district=\(district)"
            case .dsnyViolations(let bin):
                return "\(APIConfig.dsnyViolationsURL)?bin=\(bin)"
            case .ll97Compliance(let bbl):
                return "\(APIConfig.ll97URL)?bbl=\(bbl)"
            case .depWaterUsage(let account):
                return "\(APIConfig.depURL)?development_name=\(account)"
            case .fdnyInspections(let bin):
                return "\(APIConfig.fdnyURL)?bin=\(bin)"
            case .conEdisonOutages(let zip):
                return "https://storm.coned.com/stormcenter_external/default.html?zip=\(zip)"
            case .complaints311(let bin):
                return "\(APIConfig.complaints311URL)?bin=\(bin)"
            case .complaints311Address(let address):
                let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                return "\(APIConfig.complaints311URL)?incident_address=\(encoded)"
            case .dofPropertyAssessment(let bbl):
                return "\(APIConfig.dofURL)?bbl=\(bbl)"
            case .dofTaxBills(let bbl):
                return "\(APIConfig.dofTaxBillsURL)?bbl=\(bbl)"
            case .dofTaxLiens(let bbl):
                return "\(APIConfig.dofTaxLiensURL)?bbl=\(bbl)"
            case .energyEfficiencyRating(let bbl):
                return "\(APIConfig.energyEfficiencyURL)?bbl=\(bbl)"
            case .landmarksBuildings(let bbl):
                return "\(APIConfig.landmarksBuildingsURL)?bbl=\(bbl)"
            case .buildingFootprints(let bin):
                return "\(APIConfig.buildingFootprintsURL)?bin=\(bin)"
            case .buildingFootprintsNearby(let lat, let lon, let r):
                let whereClause = "$where=" + "within_circle(the_geom,\(lat),\(lon),\(r))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                return "\(APIConfig.buildingFootprintsURL)?\(whereClause)&$select=bin,bbl&$limit=1"
            case .activeConstruction(let address):
                let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(APIConfig.activeConstructionURL)?address=\(encodedAddress)"
            case .businessLicenses(let address):
                let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(APIConfig.businessLicensesURL)?address=\(encodedAddress)"
            case .airQualityComplaints(let address):
                let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(APIConfig.airQualityURL)?incident_address=\(encodedAddress)"
            }
        }
        
        var cacheKey: String {
            switch self {
            case .hpdViolations(let bin): return "hpd_violations_\(bin)"
            case .dobPermits(let bin): return "dob_permits_\(bin)"
            case .dsnySchedule(let district): return "dsny_schedule_\(district)"
            case .dsnyViolations(let bin): return "dsny_violations_\(bin)"
            case .ll97Compliance(let bbl): return "ll97_compliance_\(bbl)"
            case .depWaterUsage(let account): return "dep_water_\(account)"
            case .fdnyInspections(let bin): return "fdny_inspections_\(bin)"
            case .conEdisonOutages(let zip): return "coned_outages_\(zip)"
            case .complaints311(let bin): return "311_complaints_\(bin)"
            case .complaints311Address(let address): return "311_complaints_addr_\(address.hashValue)"
            case .dofPropertyAssessment(let bbl): return "dof_property_\(bbl)"
            case .dofTaxBills(let bbl): return "dof_tax_bills_\(bbl)"
            case .dofTaxLiens(let bbl): return "dof_tax_liens_\(bbl)"
            case .energyEfficiencyRating(let bbl): return "energy_efficiency_\(bbl)"
            case .landmarksBuildings(let bbl): return "landmarks_\(bbl)"
            case .buildingFootprints(let bin): return "footprints_\(bin)"
            case .buildingFootprintsNearby(let lat, let lon, let r): return "footprints_near_\(lat)_\(lon)_\(r)"
            case .activeConstruction(let address): return "construction_\(address.hashValue)"
            case .businessLicenses(let address): return "business_licenses_\(address.hashValue)"
            case .airQualityComplaints(let address): return "air_quality_\(address.hashValue)"
            }
        }
    }

    // MARK: - Footprints Helpers
    public func resolveBinBbl(lat: Double, lon: Double, radiusMeters: Int = 25) async -> (bin: String?, bbl: String?) {
        do {
            let urlStr = APIEndpoint.buildingFootprintsNearby(lat: lat, lon: lon, radiusMeters: radiusMeters).url
            guard let url = URL(string: urlStr) else { return (nil, nil) }
            var request = URLRequest(url: url)
            request.setValue("dbO8NmN2pMcmSQO7w56rTaFax", forHTTPHeaderField: "X-App-Token")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return (nil, nil) }
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let first = arr.first {
                let bin = first["bin"] as? String
                let bbl = first["bbl"] as? String
                return (bin, bbl)
            }
        } catch { /* ignore */ }
        return (nil, nil)
    }
    
    public enum APIStatus {
        case idle
        case fetching
        case success(Date)
        case error(String)
        case rateLimited
    }
    
    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.cache = CacheManager()
        self.keychainManager = KeychainManager.shared
        
        setupConnectivityMonitoring()
    }
    
    // MARK: - Public API Methods
    
    /// Fetch HPD violations for a building
    public func fetchHPDViolations(bin: String) async throws -> [HPDViolation] {
        let endpoint = APIEndpoint.hpdViolations(bin: bin)
        return try await fetch(endpoint)
    }
    
    /// Fetch DOB permits for a building
    public func fetchDOBPermits(bin: String) async throws -> [DOBPermit] {
        let endpoint = APIEndpoint.dobPermits(bin: bin)
        return try await fetch(endpoint)
    }
    
    /// Fetch DSNY schedule for a district
    public func fetchDSNYSchedule(district: String) async throws -> [DSNYRoute] {
        let endpoint = APIEndpoint.dsnySchedule(district: district)
        return try await fetch(endpoint)
    }
    
    /// Fetch LL97 compliance data
    public func fetchLL97Compliance(bbl: String) async throws -> [LL97Emission] {
        let normBBL = normalizeBBL(bbl)
        let endpoint = APIEndpoint.ll97Compliance(bbl: normBBL)
        return try await fetch(endpoint)
    }
    
    /// Fetch DEP water usage data
    public func fetchDEPWaterUsage(account: String) async throws -> [DEPWaterUsage] {
        let endpoint = APIEndpoint.depWaterUsage(account: account)
        return try await fetch(endpoint)
    }
    
    /// Fetch DSNY violations
    public func fetchDSNYViolations(bin: String) async throws -> [DSNYViolation] {
        let endpoint = APIEndpoint.dsnyViolations(bin: bin)
        return try await fetch(endpoint)
    }
    
    /// Fetch FDNY inspections
    public func fetchFDNYInspections(bin: String) async throws -> [FDNYInspection] {
        let endpoint = APIEndpoint.fdnyInspections(bin: bin)
        return try await fetch(endpoint)
    }
    
    /// Fetch 311 complaints
    public func fetch311Complaints(bin: String) async throws -> [Complaint311] {
        // Note: 311 dataset (erm2-nwe9) does not expose BIN; this call may return broad results.
        // Prefer address-based variant when possible.
        let endpoint = APIEndpoint.complaints311(bin: bin)
        return try await fetch(endpoint)
    }

    /// Fetch 311 complaints for a specific address (preferred)
    public func fetch311Complaints(address: String) async throws -> [Complaint311] {
        let endpoint = APIEndpoint.complaints311Address(address: address)
        return try await fetch(endpoint)
    }
    
    /// Fetch DOF Property Assessment data
    public func fetchDOFPropertyAssessment(bbl: String) async throws -> [DOFPropertyAssessment] {
        let normBBL = normalizeBBL(bbl)
        let endpoint = APIEndpoint.dofPropertyAssessment(bbl: normBBL)
        return try await fetch(endpoint)
    }
    
    /// Fetch DOF Tax Bills for a property
    public func fetchDOFTaxBills(bbl: String) async throws -> [DOFTaxBill] {
        let normBBL = normalizeBBL(bbl)
        let endpoint = APIEndpoint.dofTaxBills(bbl: normBBL)
        return try await fetch(endpoint)
    }
    
    /// Fetch DOF Tax Liens for a property
    public func fetchDOFTaxLiens(bbl: String) async throws -> [DOFTaxLien] {
        let normBBL = normalizeBBL(bbl)
        let endpoint = APIEndpoint.dofTaxLiens(bbl: normBBL)
        return try await fetch(endpoint)
    }
    
    /// Fetch Energy Efficiency Rating for a building
    public func fetchEnergyEfficiencyRating(bbl: String) async throws -> [EnergyEfficiencyRating] {
        let normBBL = normalizeBBL(bbl)
        let endpoint = APIEndpoint.energyEfficiencyRating(bbl: normBBL)
        return try await fetch(endpoint)
    }
    
    /// Fetch Landmarks Buildings data
    public func fetchLandmarksBuildings(bbl: String) async throws -> [LandmarksBuilding] {
        let normBBL = normalizeBBL(bbl)
        let endpoint = APIEndpoint.landmarksBuildings(bbl: normBBL)
        return try await fetch(endpoint)
    }
    
    /// Fetch Building Footprints data
    public func fetchBuildingFootprints(bin: String) async throws -> [BuildingFootprint] {
        let endpoint = APIEndpoint.buildingFootprints(bin: bin)
        return try await fetch(endpoint)
    }
    
    /// Fetch Active Construction Projects
    public func fetchActiveConstruction(address: String) async throws -> [ActiveConstruction] {
        let endpoint = APIEndpoint.activeConstruction(address: address)
        return try await fetch(endpoint)
    }
    
    /// Fetch Business Licenses for an address
    public func fetchBusinessLicenses(address: String) async throws -> [BusinessLicense] {
        let endpoint = APIEndpoint.businessLicenses(address: address)
        return try await fetch(endpoint)
    }
    
    /// Fetch Air Quality Complaints for an address
    public func fetchAirQualityComplaints(address: String) async throws -> [AirQualityComplaint] {
        let endpoint = APIEndpoint.airQualityComplaints(address: address)
        return try await fetch(endpoint)
    }
    
    // MARK: - Generic Fetch Method
    
    public func fetch<T: Decodable & Encodable>(_ endpoint: APIEndpoint) async throws -> [T] {
        // Update status
        await MainActor.run {
            apiStatus[endpoint] = .fetching
        }
        
        // Check cache first
        if let cached: [T] = cache.get(key: endpoint.cacheKey) {
            await MainActor.run {
                apiStatus[endpoint] = .success(Date())
            }
            return cached
        }
        
        // Rate limiting check
        try await enforceRateLimit()
        
        guard let url = URL(string: endpoint.url) else {
            throw NYCAPIError.invalidURL(endpoint.url)
        }
        
        // Build request with app token from credentials when available
        var request = URLRequest(url: url)
        if let token = appToken() {
            request.setValue(token, forHTTPHeaderField: "X-App-Token")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Lightweight retry loop for transient cancellations
        var attempt = 0
        let maxAttempts = 3
        var lastError: Error?
        while attempt < maxAttempts {
            do {
                let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NYCAPIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode([T].self, from: data)
                
                // Cache result
                cache.set(key: endpoint.cacheKey, value: result, expiry: APIConfig.cacheTimeout)
                
                await MainActor.run {
                    apiStatus[endpoint] = .success(Date())
                    lastSyncTime = Date()
                }
                
                return result
                
            case 429:
                await MainActor.run {
                    apiStatus[endpoint] = .rateLimited
                }
                throw NYCAPIError.rateLimited
                
            case 404:
                // No data found is not an error for NYC APIs
                await MainActor.run {
                    apiStatus[endpoint] = .success(Date())
                }
                return []
                
            default:
                let errorMessage = "HTTP \(httpResponse.statusCode)"
                // Fallback for 400s: return cached data if available to avoid zeroing metrics
                if httpResponse.statusCode == 400 {
                    if let cached: [T] = cache.get(key: endpoint.cacheKey) {
                        await MainActor.run {
                            apiStatus[endpoint] = .success(Date())
                        }
                        print("⚠️ NYC API 400 for \(endpoint). Using cached value.")
                        return cached
                    } else {
                        // No cache: degrade gracefully with empty result
                        await MainActor.run {
                            apiStatus[endpoint] = .error(errorMessage)
                        }
                        print("⚠️ NYC API 400 for \(endpoint). No cache available.")
                        return []
                    }
                }
                await MainActor.run {
                    apiStatus[endpoint] = .error(errorMessage)
                }
                throw NYCAPIError.httpError(httpResponse.statusCode, errorMessage)
            }
            } catch {
                lastError = error
                // Retry on transient cancellations and connection loss
                if let urlError = error as? URLError, urlError.code == .cancelled || urlError.code == .networkConnectionLost {
                    attempt += 1
                    try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
                    continue
                }
                await MainActor.run { self.apiStatus[endpoint] = .error(error.localizedDescription) }
                throw error
            }
        }
        await MainActor.run { self.apiStatus[endpoint] = .error(lastError?.localizedDescription ?? "cancelled") }
        throw lastError ?? NYCAPIError.networkError("cancelled")
    }

    // Fetch app token from credentials or env
    private func appToken() -> String? {
        // Prefer Keychain via ProductionCredentialsManager
        if let kc = ProductionCredentialsManager.shared.retrieveCredential(key: "DSNY_API_TOKEN"), !kc.isEmpty {
            return kc
        }
        // Fallback to process env
        if let env = ProcessInfo.processInfo.environment["NYC_APP_TOKEN"], !env.isEmpty { return env }
        // Final fallback to compiled token if present
        return "dbO8NmN2pMcmSQO7w56rTaFax"
    }
    
    // MARK: - Batch Operations
    
    /// Fetch all compliance data for a building
    public func fetchBuildingCompliance(bin: String, bbl: String) async -> BuildingComplianceData {
        return await fetchBuildingCompliance(bin: bin, bbl: bbl, address: nil)
    }

    /// Preferred variant that allows address-based 311 lookup
    public func fetchBuildingCompliance(bin: String, bbl: String, address: String?) async -> BuildingComplianceData {
        var complianceData = BuildingComplianceData(bin: bin, bbl: bbl)

        // Fetch primary datasets concurrently
        async let hpdViolations = try? fetchHPDViolations(bin: bin)
        async let dobPermits = try? fetchDOBPermits(bin: bin)
        async let fdnyInspections = try? fetchFDNYInspections(bin: bin)
        async let ll97Data = try? fetchLL97Compliance(bbl: bbl)
        async let dsnyViolations = try? fetchDSNYViolations(bin: bin)

        // Wait for concurrent results
        complianceData.hpdViolations = await hpdViolations ?? []
        complianceData.dobPermits = await dobPermits ?? []
        complianceData.fdnyInspections = await fdnyInspections ?? []
        complianceData.ll97Emissions = await ll97Data ?? []
        // 311: prefer address-based lookup when available (sequential to avoid async closure issue)
        if let address = address, let addrComplaints = try? await fetch311Complaints(address: address) {
            complianceData.complaints311 = addrComplaints
        } else {
            let binComplaints = (try? await fetch311Complaints(bin: bin)) ?? []
            complianceData.complaints311 = binComplaints
        }
        complianceData.dsnyViolations = await dsnyViolations ?? []

        // DSNY schedule handled by DSNYAPIService (location-based) elsewhere; leave empty here
        complianceData.dsnyRoutes = []

        return complianceData
    }

    // MARK: - Utilities
    public func normalizeBBL(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 { return digits }
        let parts = raw.replacingOccurrences(of: " ", with: "").split(separator: "-")
        if parts.count == 3,
           let b = parts.first, let blk = parts.dropFirst().first, let lot = parts.last,
           let borough = Int(b), let block = Int(blk), let lotNum = Int(lot), (1...5).contains(borough) {
            return "\(borough)\(String(format: "%05d", block))\(String(format: "%04d", lotNum))"
        }
        if digits.count >= 7 {
            let bStr = String(digits.prefix(1))
            let rest = String(digits.dropFirst())
            let lotPart = String(rest.suffix(4))
            let blockPart = String(rest.dropLast(4))
            let borough = Int(bStr) ?? 0
            let block = Int(blockPart) ?? 0
            let lot = Int(lotPart) ?? 0
            if (1...5).contains(borough) {
                return "\(borough)\(String(format: "%05d", block))\(String(format: "%04d", lot))"
            }
        }
        return digits
    }
    
    /// Refresh all building data
    public func refreshAllBuildingData(buildings: [CoreTypes.NamedCoordinate]) async {
        await MainActor.run {
            isConnected = true
        }
        
        for building in buildings {
            // Extract BIN and BBL from building data
            let bin: String
            let bbl: String
            // Use proper NYC BIN/BBL mapping for portfolio buildings  
            bin = extractBIN(from: building)
            bbl = extractBBL(from: building)
            
            _ = await fetchBuildingCompliance(bin: bin, bbl: bbl, address: building.address)
            
            // Respect rate limits
            try? await Task.sleep(nanoseconds: UInt64(APIConfig.rateLimitDelay * 1_000_000_000))
        }
    }
    
    // MARK: - Private Methods
    
    private func setupConnectivityMonitoring() {
        // Monitor network connectivity
        NotificationCenter.default.publisher(for: .connectivityChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkAPIConnectivity()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAPIConnectivity() {
        // Simple connectivity check
        Task {
            do {
                let url = URL(string: APIConfig.hpdURL + "?$limit=1")!
                let (_, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    await MainActor.run {
                        isConnected = true
                    }
                }
            } catch {
                await MainActor.run {
                    isConnected = false
                }
            }
        }
    }
    
    private func enforceRateLimit() async throws {
        // Simple rate limiting - wait between calls
        if let lastSync = lastSyncTime,
           Date().timeIntervalSince(lastSync) < APIConfig.rateLimitDelay {
            let waitTime = APIConfig.rateLimitDelay - Date().timeIntervalSince(lastSync)
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }
    
    private func extractBIN(from building: CoreTypes.NamedCoordinate) -> String {
        // NYC BIN mapping for portfolio buildings
        switch building.id {
        case "14", "14a": return "1034304" // Rubin Museum - 142 W 17th St
        case "14b": return "1034305" // 144 W 17th St  
        case "14c": return "1034306" // 146 W 17th St
        case "14d": return "1034307" // 148 W 17th St
        case "4": return "1008765" // 68 Perry Street
        case "8": return "1002456" // 123 1st Avenue
        case "7": return "1034289" // 117 W 17th Street
        case "6": return "1034351" // 112 W 18th Street
        default: return building.id // Fallback to app ID
        }
    }
    
    private func extractBBL(from building: CoreTypes.NamedCoordinate) -> String {
        // NYC BBL (Borough-Block-Lot) mapping for portfolio buildings
        switch building.id {
        case "14", "14a": return "1008490017" // Manhattan Block 849, Lot 17
        case "14b": return "1008490018" // Manhattan Block 849, Lot 18
        case "14c": return "1008490019" // Manhattan Block 849, Lot 19
        case "14d": return "1008490020" // Manhattan Block 849, Lot 20
        case "4": return "1006210036" // Manhattan Block 621, Lot 36 (Perry St)
        case "8": return "1003900015" // Manhattan Block 390, Lot 15 (1st Ave)
        case "7": return "1008490015" // Manhattan Block 849, Lot 15 (W 17th)
        case "6": return "1008500025" // Manhattan Block 850, Lot 25 (W 18th)
        default: return "" // Unknown building
        }
    }
    
    private func extractDistrict(from bin: String) -> String {
        // Extract community district from BIN or use default
        // NYC community districts are typically MN01-MN12, BX01-BX18, etc.
        // For now, use a default district - this should be enhanced with proper mapping
        return "MN05" // Default to Manhattan Community District 5
    }
}

// MARK: - Error Types

public enum NYCAPIError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case rateLimited
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from NYC API"
        case .rateLimited:
            return "NYC API rate limit exceeded. Please try again later."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let connectivityChanged = Notification.Name("connectivityChanged")
    static let nycAPIDataUpdated = Notification.Name("nycAPIDataUpdated")
}

// MARK: - Data Models

public struct BuildingComplianceData {
    let bin: String
    let bbl: String
    var hpdViolations: [HPDViolation] = []
    var dobPermits: [DOBPermit] = []
    var fdnyInspections: [FDNYInspection] = []
    var ll97Emissions: [LL97Emission] = []
    var complaints311: [Complaint311] = []
    var dsnyViolations: [DSNYViolation] = []
    var dsnyRoutes: [DSNYRoute] = []
    
    var complianceScore: Double {
        let totalViolations = hpdViolations.count + complaints311.count
        let activeViolations = hpdViolations.filter { $0.currentStatusDate == nil }.count
        
        if totalViolations == 0 { return 1.0 }
        return max(0, 1.0 - (Double(activeViolations) / Double(totalViolations)))
    }
    
    var hasActiveLLviol97ations: Bool {
        return ll97Emissions.contains { $0.totalGHGEmissions > $0.emissionsLimit }
    }
}
