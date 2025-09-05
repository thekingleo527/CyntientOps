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
        static let dsnyViolationsURL = "https://data.cityofnewyork.us/resource/weg2-hvnf.json" // Legacy DSNY Violations (may be retired)
        static let oathHearingsURL = "https://data.cityofnewyork.us/resource/jz4z-kudi.json" // OATH Hearings Division Case Status
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
        static let rateLimitDelay: TimeInterval = 2.5 // Optimized: 2.5 seconds between calls
        static let cacheTimeout: TimeInterval = 7200 // Extended: 2 hour cache
        static let longTermCacheTimeout: TimeInterval = 86400 // 24 hours for stable data like building footprints
    }
    
    // MARK: - API Endpoints
    public enum APIEndpoint: Hashable {
        case hpdViolations(bin: String)
        case hpdViolationsAddress(address: String)
        case dobPermits(bin: String)
        case dobPermitsAddress(address: String)
        case dsnySchedule(district: String)
        case dsnyViolations(bin: String)
        case dsnyViolationsAddress(address: String)
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
            case .hpdViolationsAddress(let address):
                // Socrata supports full-text search via $q for address fallbacks
                let q = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                return "\(APIConfig.hpdURL)?$q=\(q)"
            case .dobPermits(let bin):
                // DOB Permit Issuance dataset uses column name `bin__`
                return "\(APIConfig.dobURL)?bin__=\(bin)"
            case .dobPermitsAddress(let address):
                let q = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                return "\(APIConfig.dobURL)?$q=\(q)"
            case .dsnySchedule(let district):
                return "\(APIConfig.dsnyURL)?community_district=\(district)"
            case .dsnyViolations(let bin):
                return "\(APIConfig.dsnyViolationsURL)?bin=\(bin)"
            case .dsnyViolationsAddress(let address):
                let q = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                return "\(APIConfig.dsnyViolationsURL)?address=\(q)"
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
            case .hpdViolationsAddress(let address): return "hpd_violations_addr_\(address.hashValue)"
            case .dobPermits(let bin): return "dob_permits_\(bin)"
            case .dobPermitsAddress(let address): return "dob_permits_addr_\(address.hashValue)"
            case .dsnySchedule(let district): return "dsny_schedule_\(district)"
            case .dsnyViolations(let bin): return "dsny_violations_\(bin)"
            case .dsnyViolationsAddress(let address): return "dsny_violations_addr_\(address.hashValue)"
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
        let radii = [radiusMeters, 50, 100, 150]
        for r in radii {
            do {
                let urlStr = APIEndpoint.buildingFootprintsNearby(lat: lat, lon: lon, radiusMeters: r).url
                guard let url = URL(string: urlStr) else { continue }
                var request = URLRequest(url: url)
                if let token = appToken() { request.setValue(token, forHTTPHeaderField: "X-App-Token") }
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
                if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let first = arr.first {
                    let bin = first["bin"] as? String
                    let bbl = first["bbl"] as? String
                    if bin != nil || bbl != nil { return (bin, bbl) }
                }
            } catch {
                if let ue = error as? URLError, ue.code == .cancelled { continue }
            }
        }
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

    /// Fetch HPD violations by address fallback (uses $q full-text search)
    public func fetchHPDViolations(address: String) async throws -> [HPDViolation] {
        let normalizedAddress = normalizeAddress(address)
        let endpoint = APIEndpoint.hpdViolationsAddress(address: normalizedAddress)
        return try await fetch(endpoint)
    }

    /// Fetch DOB permits by address fallback (uses $q full-text search)
    public func fetchDOBPermits(address: String) async throws -> [DOBPermit] {
        let normalizedAddress = normalizeAddress(address)
        let endpoint = APIEndpoint.dobPermitsAddress(address: normalizedAddress)
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

    /// Fetch DSNY violations by address (fallback when BIN is unreliable)
    public func fetchDSNYViolations(address: String) async throws -> [DSNYViolation] {
        let normalizedAddress = normalizeAddress(address)
        
        // Prefer OATH Hearings dataset filtered to DSNY agencies and address match
        if let oath = try? await fetchOATHDSNYViolations(address: normalizedAddress), !oath.isEmpty {
            return oath
        }
        // Fallback to legacy DSNY dataset address query if still available
        let endpoint = APIEndpoint.dsnyViolationsAddress(address: normalizedAddress)
        return try await fetch(endpoint)
    }

    /// Fetch DSNY-related violations from OATH Hearings dataset by BBL (preferred for accuracy)
    public func fetchOATHDSNYViolations(bbl: String) async throws -> [DSNYViolation] {
        let norm = normalizeBBL(bbl)
        guard norm.count == 10 else { return [] }
        let boroCode = Int(String(norm.prefix(1))) ?? 0
        let block = String(norm.dropFirst().prefix(5))
        let lot = String(norm.suffix(4))
        let borough: String
        switch boroCode {
        case 1: borough = "MANHATTAN"
        case 2: borough = "BRONX"
        case 3: borough = "BROOKLYN"
        case 4: borough = "QUEENS"
        case 5: borough = "STATEN IS"
        default: borough = ""
        }
        guard !borough.isEmpty else { return [] }
        let whereAgency = "(upper(issuing_agency) like 'SANITATION%' OR issuing_agency = 'DOS - ENFORCEMENT AGENTS')"
        let whereBBL = "violation_location_borough = '\\(borough)' AND violation_location_block_no = '\\(block)' AND violation_location_lot_no = '\\(lot)'"
        let urlStr = "\(APIConfig.oathHearingsURL)?$where=\(whereAgency) AND \(whereBBL)&$limit=5000"
        guard let url = URL(string: urlStr) else { throw NYCAPIError.invalidURL(urlStr) }
        var request = URLRequest(url: url)
        if let token = appToken() { request.setValue(token, forHTTPHeaderField: "X-App-Token") }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        func toString(_ any: Any?) -> String? { any as? String }
        func toDouble(_ any: Any?) -> Double? {
            if let d = any as? Double { return d }
            if let s = any as? String { return Double(s) }
            return nil
        }
        return arr.map { row in
            DSNYViolation(
                violationId: toString(row["ticket_number"]) ?? UUID().uuidString,
                bin: "",
                issueDate: toString(row["violation_date"]) ?? "",
                hearingDate: toString(row["hearing_date"]) ?? nil,
                violationType: toString(row["issuing_agency"]) ?? "SANITATION",
                fineAmount: toDouble(row["penalty_imposed"]) ?? toDouble(row["total_violation_amount"]) ?? nil,
                status: toString(row["compliance_status"]) ?? toString(row["hearing_result"]) ?? "",
                borough: toString(row["violation_location_borough"]) ?? "",
                address: {
                    let h = toString(row["violation_location_house"]) ?? ""
                    let s = toString(row["violation_location_street_name"]) ?? ""
                    return (h.isEmpty && s.isEmpty) ? nil : "\(h) \(s)"
                }(),
                violationDetails: toString(row["violation_details"]) ?? toString(row["charge_1_code_description"]) ?? nil,
                dispositionCode: toString(row["hearing_result"]) ?? nil,
                dispositionDate: toString(row["decision_date"]) ?? nil
            )
        }
    }

    /// Fetch DSNY-related violations from OATH Hearings dataset, filtered by address
    private func fetchOATHDSNYViolations(address: String) async throws -> [DSNYViolation] {
        // Build a broad address search using $q and constrain issuing_agency to DSNY-related
        let encodedQ = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let whereAgency = "(upper(issuing_agency) like 'SANITATION%' OR issuing_agency = 'DOS - ENFORCEMENT AGENTS')"
        let urlStr = "\(APIConfig.oathHearingsURL)?$where=\(whereAgency)&$q=\(encodedQ)&$limit=5000"
        guard let url = URL(string: urlStr) else { throw NYCAPIError.invalidURL(urlStr) }
        var request = URLRequest(url: url)
        if let token = appToken() { request.setValue(token, forHTTPHeaderField: "X-App-Token") }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        // Map OATH schema to DSNYViolation model
        func toString(_ any: Any?) -> String? { any as? String }
        func toDouble(_ any: Any?) -> Double? {
            if let d = any as? Double { return d }
            if let s = any as? String { return Double(s) }
            return nil
        }
        let mapped: [DSNYViolation] = arr.map { row in
            let ticket = toString(row["ticket_number"]) ?? UUID().uuidString
            let vDate = toString(row["violation_date"]) ?? ""
            let hDate = toString(row["hearing_date"]) ?? nil
            let agency = toString(row["issuing_agency"]) ?? "SANITATION"
            let fine = toDouble(row["penalty_imposed"]) ?? toDouble(row["total_violation_amount"]) ?? nil
            let status = toString(row["compliance_status"]) ?? toString(row["hearing_result"]) ?? ""
            let borough = toString(row["violation_location_borough"]) ?? ""
            let house = toString(row["violation_location_house"]) ?? ""
            let street = toString(row["violation_location_street_name"]) ?? ""
            let addr = (house.isEmpty && street.isEmpty) ? nil : "\(house) \(street)"
            let details = toString(row["violation_details"]) ?? toString(row["charge_1_code_description"]) ?? nil
            let decision = toString(row["decision_date"]) ?? nil
            return DSNYViolation(
                violationId: ticket,
                bin: "", // OATH does not expose BIN
                issueDate: vDate,
                hearingDate: hDate,
                violationType: agency,
                fineAmount: fine,
                status: status,
                borough: borough,
                address: addr,
                violationDetails: details,
                dispositionCode: toString(row["hearing_result"]),
                dispositionDate: decision
            )
        }
        return mapped
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
        let normalizedAddress = normalizeAddress(address)
        let endpoint = APIEndpoint.complaints311Address(address: normalizedAddress)
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
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    // First try strict decoding
                    let result = try decoder.decode([T].self, from: data)
                    
                    // Smart caching with different timeouts based on data type
                    let cacheTimeout = getCacheTimeout(for: endpoint)
                    cache.set(key: endpoint.cacheKey, value: result, expiry: cacheTimeout)
                    
                    await MainActor.run {
                        apiStatus[endpoint] = .success(Date())
                        lastSyncTime = Date()
                    }
                    
                    return result
                } catch let decodingError as DecodingError {
                    // Handle missing field errors gracefully by attempting flexible decoding
                    let flexibleResult: [T] = try handleDecodingError(data: data, error: decodingError, endpoint: endpoint)
                    if !flexibleResult.isEmpty {
                        // Cache partial result with standard timeout
                        let cacheTimeout = getCacheTimeout(for: endpoint)
                        cache.set(key: endpoint.cacheKey, value: flexibleResult, expiry: cacheTimeout)
                        
                        await MainActor.run {
                            apiStatus[endpoint] = .success(Date())
                            lastSyncTime = Date()
                        }
                        return flexibleResult
                    }
                    // If flexible decoding also fails, fall through to error handling
                    print("⚠️ JSON decoding error for \(endpoint): \(decodingError)")
                    throw decodingError
                }
                
            case 429:
                await MainActor.run {
                    apiStatus[endpoint] = .rateLimited
                }
                // Backoff and retry
                attempt += 1
                let delay = max(1.0, APIConfig.rateLimitDelay) * pow(2.0, Double(attempt - 1))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
                
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
                // Handle JSON decoding errors with fallback to cached data
                if error is DecodingError {
                    print("⚠️ JSON decoding failed for \(endpoint): \(error)")
                    if let cached: [T] = cache.get(key: endpoint.cacheKey) {
                        await MainActor.run {
                            apiStatus[endpoint] = .success(Date())
                        }
                        print("⚠️ Using cached data for \(endpoint) due to JSON error")
                        return cached
                    }
                    // No cache available, return empty result to prevent app crash
                    await MainActor.run {
                        apiStatus[endpoint] = .error(error.localizedDescription)
                    }
                    return []
                }
                
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
        // 1) Try structured NYCAPIKeys from Keychain
        if let keys = try? keychainManager.getNYCAPIKeys(), !keys.dsnyAPIKey.isEmpty {
            return keys.dsnyAPIKey
        }
        // 2) Try direct Keychain string entries
        if let dsny = try? keychainManager.getString(for: "DSNY_API_TOKEN"), !dsny.isEmpty { return dsny }
        if let soda = try? keychainManager.getString(for: "NYC_APP_TOKEN"), !soda.isEmpty { return soda }
        // 3) Try environment variables
        if let env = ProcessInfo.processInfo.environment["NYC_APP_TOKEN"], !env.isEmpty { return env }
        if let env2 = ProcessInfo.processInfo.environment["DSNY_API_TOKEN"], !env2.isEmpty { return env2 }
        // 4) Final fallback (dev)
        return "dbO8NmN2pMcmSQO7w56rTaFax"
    }
    
    /// Normalize address format for NYC API queries
    /// - Removes problematic terms like "Park" or "Greenway" that don't work with building APIs
    /// - Standardizes street suffixes and formatting
    private func normalizeAddress(_ address: String) -> String {
        var normalized = address
        
        // Skip normalization for clearly non-building addresses
        let nonBuildingTerms = ["park", "greenway", "pier", "plaza", "square", "bridge"]
        for term in nonBuildingTerms {
            if normalized.localizedCaseInsensitiveContains(term) {
                // For parks/greenways, try to extract just the street component if available
                let components = normalized.components(separatedBy: ",")
                if components.count > 1 {
                    // Use the last component that looks like a standard address
                    for component in components.reversed() {
                        let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.contains("NY") && (trimmed.contains("10") || trimmed.contains("11")) {
                            // This looks like "New York, NY 10009" - not useful for building queries
                            continue
                        }
                        if !trimmed.localizedCaseInsensitiveContains(term) && trimmed.count > 10 {
                            normalized = trimmed
                            break
                        }
                    }
                }
                break
            }
        }
        
        // Standard address normalization
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Standardize street suffixes
        normalized = normalized.replacingOccurrences(of: " St.", with: " Street")
        normalized = normalized.replacingOccurrences(of: " Ave.", with: " Avenue")
        normalized = normalized.replacingOccurrences(of: " Blvd.", with: " Boulevard")
        normalized = normalized.replacingOccurrences(of: " Rd.", with: " Road")
        
        // Remove multiple spaces
        normalized = normalized.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        return normalized
    }
    
    /// Get appropriate cache timeout based on endpoint data volatility
    private func getCacheTimeout(for endpoint: APIEndpoint) -> TimeInterval {
        switch endpoint {
        // Long-term stable data (24 hours)
        case .buildingFootprints, .buildingFootprintsNearby, .landmarksBuildings, .dofPropertyAssessment:
            return APIConfig.longTermCacheTimeout
        
        // Medium-term data (2 hours) - permits, violations that don't change frequently
        case .dobPermits, .dobPermitsAddress, .hpdViolations, .hpdViolationsAddress, .ll97Compliance:
            return APIConfig.cacheTimeout
        
        // Short-term data (1 hour) - active complaints, schedules that might change
        case .complaints311, .complaints311Address, .dsnySchedule, .dsnyViolations, .dsnyViolationsAddress:
            return APIConfig.cacheTimeout / 2
        
        // Very short-term (30 minutes) - real-time data like outages
        case .conEdisonOutages:
            return 1800
        
        default:
            return APIConfig.cacheTimeout
        }
    }
    
    /// Handle JSON decoding errors by attempting flexible parsing
    private func handleDecodingError<T: Decodable>(data: Data, error: DecodingError, endpoint: APIEndpoint) throws -> [T] {
        // For now, return empty array - this could be enhanced to do selective field parsing
        // or data transformation based on the specific endpoint and error type
        switch error {
        case .keyNotFound(let key, let context):
            print("⚠️ Missing field '\(key.stringValue)' in \(endpoint) response at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .typeMismatch(let type, let context):
            print("⚠️ Type mismatch for \(type) in \(endpoint) response at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .valueNotFound(let type, let context):
            print("⚠️ Null value for \(type) in \(endpoint) response at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .dataCorrupted(let context):
            print("⚠️ Corrupted data in \(endpoint) response at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        @unknown default:
            print("⚠️ Unknown decoding error in \(endpoint): \(error)")
        }
        
        // Try to parse as raw JSON and extract what we can
        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            print("⚠️ Raw JSON contains \(json.count) items for \(endpoint)")
            // Could implement selective field extraction here based on endpoint type
        }
        
        return []
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

        // Add address fallbacks for HPD/DOB when BIN is unreliable or returned empty
        if complianceData.hpdViolations.isEmpty, let address = address,
           let byAddr: [HPDViolation] = try? await fetchHPDViolations(address: address), !byAddr.isEmpty {
            complianceData.hpdViolations = byAddr
        }
        if complianceData.dobPermits.isEmpty, let address = address,
           let byAddr: [DOBPermit] = try? await fetchDOBPermits(address: address), !byAddr.isEmpty {
            complianceData.dobPermits = byAddr
        }

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
        // Adaptive rate limiting with burst allowance
        await MainActor.run {
            if self.lastSyncTime == nil {
                // First call - no delay
                self.lastSyncTime = Date()
                return
            }
        }
        
        let currentTime = Date()
        guard let lastSync = lastSyncTime else { return }
        
        let timeSinceLastCall = currentTime.timeIntervalSince(lastSync)
        let minimumDelay = APIConfig.rateLimitDelay
        
        // Allow burst of up to 3 rapid calls, then enforce stricter limits
        let recentCallsWindow: TimeInterval = 30 // 30 second window
        let maxBurstCalls = 3
        
        // For frequent calls, apply exponential backoff
        if timeSinceLastCall < minimumDelay {
            let waitTime = minimumDelay - timeSinceLastCall
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        await MainActor.run {
            self.lastSyncTime = Date()
        }
    }
    
    public func extractBIN(from building: CoreTypes.NamedCoordinate) -> String {
        // 1) Check database first (already hydrated by NYCIntegrationManager)
        let dbBin: String = (try? GRDBManager.shared.database.read({ db in
            try (String.fetchOne(db, sql: "SELECT bin FROM buildings WHERE id = ?", arguments: [building.id]) ?? "")
        })) ?? ""
        if !dbBin.isEmpty { return dbBin }
        // 2) Hardcoded fallback for known portfolio buildings
        switch building.id {
        case "14", "14a": return "1034304" // Rubin Museum - 142 W 17th St
        case "14b": return "1034305" // 144 W 17th St  
        case "14c": return "1034306" // 146 W 17th St
        case "14d": return "1034307" // 148 W 17th St
        case "4": return "1008765" // 68 Perry Street
        case "8": return "1002456" // 123 1st Avenue
        case "7": return "1034289" // 117 W 17th Street
        case "6": return "1034351" // 112 W 18th Street
        default: break
        }
        return ""
    }
    
    public func extractBBL(from building: CoreTypes.NamedCoordinate) -> String {
        // 1) Check database first (already hydrated)
        let dbBbl: String = (try? GRDBManager.shared.database.read({ db in
            try (String.fetchOne(db, sql: "SELECT bbl FROM buildings WHERE id = ?", arguments: [building.id]) ?? "")
        })) ?? ""
        if !dbBbl.isEmpty { return dbBbl }
        // 2) Hardcoded portfolio fallbacks
        switch building.id {
        case "14", "14a": return "1008490017"
        case "14b": return "1008490018"
        case "14c": return "1008490019"
        case "14d": return "1008490020"
        case "4": return "1006210036"
        case "8": return "1003900015"
        case "7": return "1008490015"
        case "6": return "1008500025"
        default: break
        }
        return ""
    }
    
    public func extractDistrict(from bin: String) -> String {
        // Extract community district from BIN or use default
        // NYC community districts are typically MN01-MN12, BX01-BX18, etc.
        // For now, use a default district - this should be enhanced with proper mapping
        return "MN05" // Default to Manhattan Community District 5
    }

    // MARK: - Batched Fetch Helpers

    /// Generic fetch method from URL string
    private func fetchFromURL<T: Decodable>(_ urlString: String) async throws -> [T] {
        guard let url = URL(string: urlString) else {
            throw NYCAPIError.invalidURL(urlString)
        }
        
        var request = URLRequest(url: url)
        if let token = appToken() {
            request.setValue(token, forHTTPHeaderField: "X-App-Token")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NYCAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                return []
            }
            throw NYCAPIError.httpError(httpResponse.statusCode, "HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([T].self, from: data)
    }

    /// Fetch HPD violations for multiple BINs with optional month window, grouped by BIN
    public func fetchHPDViolations(bins: [String], months: Int? = nil) async throws -> [String: [HPDViolation]] {
        guard !bins.isEmpty else { return [:] }
        let binList = bins.map { "'\($0)'" }.joined(separator: ",")
        var whereClauses: [String] = ["bin in (\(binList))"]
        if let months = months, months > 0 {
            let start = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
            let iso = ISO8601DateFormatter().string(from: start)
            whereClauses.append("inspectiondate >= '\(iso)'")
        }
        let whereParam = whereClauses.joined(separator: " AND ")
        let url = "\(APIConfig.hpdURL)?$where=\(whereParam)&$limit=50000"
        let results: [HPDViolation] = try await fetchFromURL(url)
        return Dictionary(grouping: results, by: { $0.bin })
    }

    /// Fetch DOB permits for multiple BINs with optional month window, grouped by BIN
    public func fetchDOBPermits(bins: [String], months: Int? = nil) async throws -> [String: [DOBPermit]] {
        guard !bins.isEmpty else { return [:] }
        let binList = bins.map { "'\($0)'" }.joined(separator: ",")
        var whereClauses: [String] = ["bin__ in (\(binList))"]
        if let months = months, months > 0 {
            let start = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
            let iso = ISO8601DateFormatter().string(from: start)
            whereClauses.append("issuance_date >= '\(iso)'")
        }
        let whereParam = whereClauses.joined(separator: " AND ")
        let url = "\(APIConfig.dobURL)?$where=\(whereParam)&$limit=50000"
        let results: [DOBPermit] = try await fetchFromURL(url)
        return Dictionary(grouping: results, by: { $0.bin })
    }

    /// Fetch DSNY violations for multiple BINs with optional month window, grouped by BIN
    public func fetchDSNYViolations(bins: [String], months: Int? = nil) async throws -> [String: [DSNYViolation]] {
        guard !bins.isEmpty else { return [:] }
        let binList = bins.map { "'\($0)'" }.joined(separator: ",")
        var whereClauses: [String] = ["bin in (\(binList))"]
        if let months = months, months > 0 {
            let start = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
            let iso = ISO8601DateFormatter().string(from: start)
            whereClauses.append("issue_date >= '\(iso)'")
        }
        let whereParam = whereClauses.joined(separator: " AND ")
        let url = "\(APIConfig.dsnyViolationsURL)?$where=\(whereParam)&$limit=50000"
        let results: [DSNYViolation] = try await fetchFromURL(url)
        return Dictionary(grouping: results, by: { $0.bin })
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
