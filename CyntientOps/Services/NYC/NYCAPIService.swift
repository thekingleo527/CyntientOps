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
    private struct APIConfig {
        static let baseURL = "https://data.cityofnewyork.us/resource/"
        static let hpdURL = "https://data.cityofnewyork.us/resource/wvxf-dwi5.json" // HPD Violations
        static let dobURL = "https://data.cityofnewyork.us/resource/ipu4-2q9a.json" // DOB Permits
        static let dsnyURL = "https://data.cityofnewyork.us/resource/ebb7-mvp5.json" // DSNY Routes
        static let ll97URL = "https://data.cityofnewyork.us/resource/8vys-2eex.json" // LL97 Emissions
        static let depURL = "https://data.cityofnewyork.us/resource/66be-66yr.json"  // DEP Water
        static let fdnyURL = "https://data.cityofnewyork.us/resource/3h2n-5cm9.json" // FDNY Inspections
        static let complaints311URL = "https://data.cityofnewyork.us/resource/erm2-nwe9.json" // 311 Complaints
        
        // Rate limiting: NYC OpenData allows 1000 calls/hour per endpoint
        static let rateLimitDelay: TimeInterval = 3.6 // seconds between calls
        static let cacheTimeout: TimeInterval = 3600 // 1 hour cache
    }
    
    // MARK: - API Endpoints
    public enum APIEndpoint: Hashable {
        case hpdViolations(bin: String)
        case dobPermits(bin: String)
        case dsnySchedule(district: String)
        case ll97Compliance(bbl: String)
        case depWaterUsage(account: String)
        case fdnyInspections(bin: String)
        case conEdisonOutages(zip: String)
        case complaints311(bin: String)
        
        var url: String {
            switch self {
            case .hpdViolations(let bin):
                return "\(APIConfig.hpdURL)?bin=\(bin)"
            case .dobPermits(let bin):
                return "\(APIConfig.dobURL)?bin=\(bin)"
            case .dsnySchedule(let district):
                return "\(APIConfig.dsnyURL)?community_district=\(district)"
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
            }
        }
        
        var cacheKey: String {
            switch self {
            case .hpdViolations(let bin): return "hpd_violations_\(bin)"
            case .dobPermits(let bin): return "dob_permits_\(bin)"
            case .dsnySchedule(let district): return "dsny_schedule_\(district)"
            case .ll97Compliance(let bbl): return "ll97_compliance_\(bbl)"
            case .depWaterUsage(let account): return "dep_water_\(account)"
            case .fdnyInspections(let bin): return "fdny_inspections_\(bin)"
            case .conEdisonOutages(let zip): return "coned_outages_\(zip)"
            case .complaints311(let bin): return "311_complaints_\(bin)"
            }
        }
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
        let endpoint = APIEndpoint.ll97Compliance(bbl: bbl)
        return try await fetch(endpoint)
    }
    
    /// Fetch DEP water usage data
    public func fetchDEPWaterUsage(account: String) async throws -> [DEPWaterUsage] {
        let endpoint = APIEndpoint.depWaterUsage(account: account)
        return try await fetch(endpoint)
    }
    
    /// Fetch FDNY inspections
    public func fetchFDNYInspections(bin: String) async throws -> [FDNYInspection] {
        let endpoint = APIEndpoint.fdnyInspections(bin: bin)
        return try await fetch(endpoint)
    }
    
    /// Fetch 311 complaints
    public func fetch311Complaints(bin: String) async throws -> [Complaint311] {
        let endpoint = APIEndpoint.complaints311(bin: bin)
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
        
        do {
            let (data, response) = try await session.data(from: url)
            
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
                await MainActor.run {
                    apiStatus[endpoint] = .error(errorMessage)
                }
                throw NYCAPIError.httpError(httpResponse.statusCode, errorMessage)
            }
            
        } catch {
            let errorMessage = error.localizedDescription
            await MainActor.run {
                apiStatus[endpoint] = .error(errorMessage)
            }
            throw error
        }
    }
    
    // MARK: - Batch Operations
    
    /// Fetch all compliance data for a building
    public func fetchBuildingCompliance(bin: String, bbl: String) async -> BuildingComplianceData {
        var complianceData = BuildingComplianceData(bin: bin, bbl: bbl)
        
        // Fetch all APIs concurrently
        async let hpdViolations = try? fetchHPDViolations(bin: bin)
        async let dobPermits = try? fetchDOBPermits(bin: bin)
        async let fdnyInspections = try? fetchFDNYInspections(bin: bin)
        async let ll97Data = try? fetchLL97Compliance(bbl: bbl)
        async let complaints = try? fetch311Complaints(bin: bin)
        
        // Wait for all results
        complianceData.hpdViolations = await hpdViolations ?? []
        complianceData.dobPermits = await dobPermits ?? []
        complianceData.fdnyInspections = await fdnyInspections ?? []
        complianceData.ll97Emissions = await ll97Data ?? []
        complianceData.complaints311 = await complaints ?? []
        
        return complianceData
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
            // Use building ID as placeholder since NamedCoordinate doesn't have metadata
            bin = building.id
            bbl = ""
            
            _ = await fetchBuildingCompliance(bin: bin, bbl: bbl)
            
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