//  DSNYAPIService.swift
//  CyntientOps
//
//  NYC Department of Sanitation API Integration Service
//  Uses SODA (Socrata Open Data API) for real-time data
//

import Foundation
import CoreLocation
import Combine

@MainActor
public class DSNYAPIService: ObservableObject {
    public static let shared = DSNYAPIService()
    
    // MARK: - Configuration
    
    private let baseURL = "https://data.cityofnewyork.us/resource"
    private let collectionScheduleEndpoint = "p7k6-2pm8.json"
    private let tonnageDataEndpoint = "ebb7-mvp5.json"
    
    // API Token (optional but recommended for higher rate limits)
    private let apiToken: String? = ProcessInfo.processInfo.environment["DSNY_API_TOKEN"]
    
    // Cache for schedules
    @Published private var scheduleCache: [String: DSNY.BuildingSchedule] = [:]
    private let cacheExpiration: TimeInterval = 86400 // 24 hours
    
    // Task generation
    @Published public var autoGenerateTasks: Bool = true
    @Published public var lastTaskGeneration: Date?
    
    // URLSession
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "X-App-Token": apiToken ?? ""
        ]
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        self.session = URLSession(configuration: config)
        
        // Load cached schedules from database
        Task {
            await loadCachedSchedules()
        }
    }
    
    // MARK: - Public API Methods
    
    /// Get collection schedule for a specific building
    public func getSchedule(for building: CoreTypes.NamedCoordinate) async throws -> DSNY.BuildingSchedule {
        // Check cache first
        if let cached = getCachedSchedule(for: building.id) {
            return cached
        }
        
        // Query API by location
        let schedule = try await fetchScheduleByLocation(
            latitude: building.latitude,
            longitude: building.longitude
        )
        
        // Convert to building schedule
        let buildingSchedule = schedule.toBuildingSchedule(
            buildingId: building.id,
            address: building.address
        )
        
        // Cache the result
        await cacheSchedule(buildingSchedule, for: building.id)
        
        return buildingSchedule
    }
    
    /// Get schedules for multiple buildings
    public func getSchedules(for buildings: [CoreTypes.NamedCoordinate]) async throws -> [String: DSNY.BuildingSchedule] {
        var schedules: [String: DSNY.BuildingSchedule] = [:]
        
        // Use TaskGroup for concurrent fetching
        try await withThrowingTaskGroup(of: (String, DSNY.BuildingSchedule).self) { group in
            for building in buildings {
                group.addTask {
                    let schedule = try await self.getSchedule(for: building)
                    return (building.id, schedule)
                }
            }
            
            for try await (buildingId, schedule) in group {
                schedules[buildingId] = schedule
            }
        }
        
        return schedules
    }
    
    /// Check compliance status for a building
    public func checkCompliance(
        for building: CoreTypes.NamedCoordinate,
        at date: Date = Date()
    ) async throws -> DSNYComplianceCheckResult {
        let schedule = try await getSchedule(for: building)
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTimeInSeconds = TimeInterval(hour * 3600 + minute * 60)
        
        var issues: [DSNYComplianceViolation] = []
        
        // Check each collection type
        for collectionType in DSNY.CollectionType.allCases {
            if schedule.isCollectionDay(for: collectionType, on: date) {
                let window = schedule.complianceWindows[collectionType] ?? DSNY.ComplianceWindow(type: collectionType)
                
                // Check if it's before set-out time (8 PM previous day)
                if currentTimeInSeconds < window.setOutAfter {
                    issues.append(DSNYComplianceViolation(
                        type: collectionType,
                        severity: .low,
                        message: "\(collectionType.displayName) cannot be set out before \(window.setOutTime)"
                    ))
                }
                
                // Check if it's after pickup time (noon)
                if currentTimeInSeconds > window.pickupBefore {
                    issues.append(DSNYComplianceViolation(
                        type: collectionType,
                        severity: .high,
                        message: "\(collectionType.displayName) should have been collected by \(window.pickupTime)"
                    ))
                }
            }
        }
        
        return DSNYComplianceCheckResult(
            buildingId: building.id,
            isCompliant: issues.isEmpty,
            violations: issues,
            lastChecked: date
        )
    }
    
    /// Generate DSNY tasks for a building
    public func generateDSNYTasks(
        for building: CoreTypes.NamedCoordinate,
        workerId: String,
        date: Date = Date()
    ) async throws -> [CoreTypes.ContextualTask] {
        let schedule = try await getSchedule(for: building)
        var tasks: [CoreTypes.ContextualTask] = []
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
        
        // Check each collection type
        for collectionType in DSNY.CollectionType.allCases {
            // Check if tomorrow is a collection day
            if schedule.isCollectionDay(for: collectionType, on: tomorrow) {
                let window = schedule.complianceWindows[collectionType] ?? DSNY.ComplianceWindow(type: collectionType)
                
                // Create set-out task for tonight at 8 PM
                let setOutTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
                
                let task = CoreTypes.ContextualTask(
                    id: UUID().uuidString,
                    title: "DSNY: Set Out \(collectionType.displayName)",
                    description: "Set out \(collectionType.displayName.lowercased()) bins for tomorrow's collection. All waste must be in bins with secure lids.",
                    status: .pending,
                    scheduledDate: setOutTime,
                    dueDate: setOutTime,
                    category: .sanitation,
                    urgency: .high,
                    building: building,
                    buildingId: building.id,
                    assignedWorkerId: workerId,
                    frequency: .weekly,
                    requiresPhoto: true
                )
                
                tasks.append(task)
            }
            
            // Check if today is a collection day
            if schedule.isCollectionDay(for: collectionType, on: date) {
                // Create bring-in task for after collection
                let bringInTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
                
                let task = CoreTypes.ContextualTask(
                    id: UUID().uuidString,
                    title: "DSNY: Bring In \(collectionType.displayName) Bins",
                    description: "Bring in empty \(collectionType.displayName.lowercased()) bins after collection.",
                    status: .pending,
                    scheduledDate: bringInTime,
                    dueDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date),
                    category: .sanitation,
                    urgency: .medium,
                    building: building,
                    buildingId: building.id,
                    assignedWorkerId: workerId,
                    frequency: .weekly,
                    requiresPhoto: false
                )
                
                tasks.append(task)
            }
        }
        
        return tasks
    }
    
    /// Report a violation
    public func reportViolation(
        building: CoreTypes.NamedCoordinate,
        type: DSNY.ViolationType,
        description: String,
        photoEvidence: [URL]? = nil
    ) async throws {
        // In production, this would submit to 311 API
        // For now, store locally
        let violation = DSNY.Violation(
            violationId: UUID().uuidString,
            buildingAddress: building.address,
            violationType: type,
            issueDate: Date(),
            fineAmount: type.severity == .high ? 100 : 50,
            status: .pending,
            description: description
        )
        
        // Store in database
        try await storeViolation(violation, buildingId: building.id)
        
        // Notify admin dashboard
        await notifyViolation(violation, buildingId: building.id)
    }
    
    // MARK: - Private API Methods
    
    private func fetchScheduleByLocation(latitude: Double, longitude: Double) async throws -> DSNY.CollectionSchedule {
        // Build SoQL query
        let query = """
            SELECT *
            WHERE within_circle(the_geom, \(latitude), \(longitude), 100)
            LIMIT 1
        """
        
        var components = URLComponents(string: "\(baseURL)/\(collectionScheduleEndpoint)")!
        components.queryItems = [
            URLQueryItem(name: "$query", value: query)
        ]
        
        if let token = apiToken {
            components.queryItems?.append(URLQueryItem(name: "$$app_token", value: token))
        }
        
        guard let url = components.url else {
            throw DSNYError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DSNYError.invalidResponse
        }
        
        let schedules = try JSONDecoder().decode([DSNY.CollectionSchedule].self, from: data)
        
        guard let schedule = schedules.first else {
            throw DSNYError.noScheduleFound
        }
        
        return schedule
    }
    
    // MARK: - Cache Management
    
    private func getCachedSchedule(for buildingId: String) -> DSNY.BuildingSchedule? {
        guard let cached = scheduleCache[buildingId] else { return nil }
        
        // Check if cache is expired
        if Date().timeIntervalSince(cached.lastUpdated) > cacheExpiration {
            scheduleCache.removeValue(forKey: buildingId)
            return nil
        }
        
        return cached
    }
    
    private func cacheSchedule(_ schedule: DSNY.BuildingSchedule, for buildingId: String) async {
        scheduleCache[buildingId] = schedule
        
        // Also store in database for persistence
        do {
            try await GRDBManager.shared.execute("""
                INSERT OR REPLACE INTO dsny_schedule_cache 
                (building_id, district_section, refuse_days, recycling_days, 
                 organics_days, bulk_days, last_updated)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [
                buildingId,
                schedule.districtSection,
                schedule.refuseDays.map { $0.rawValue }.joined(separator: ","),
                schedule.recyclingDays.map { $0.rawValue }.joined(separator: ","),
                schedule.organicsDays.map { $0.rawValue }.joined(separator: ","),
                schedule.bulkDays.map { $0.rawValue }.joined(separator: ","),
                Date()
            ])
        } catch {
            print("Failed to cache schedule: \(error)")
        }
    }
    
    private func loadCachedSchedules() async {
        do {
            let rows = try await GRDBManager.shared.query("""
                SELECT * FROM dsny_schedule_cache 
                WHERE datetime(last_updated) > datetime('now', '-1 day')
            """)
            
            for row in rows {
                if let buildingId = row["building_id"] as? String,
                   let districtSection = row["district_section"] as? String {
                    
                    let schedule = DSNY.BuildingSchedule(
                        buildingId: buildingId,
                        address: "", // Will be updated when needed
                        districtSection: districtSection,
                        refuseDays: parseDaySet(from: row["refuse_days"] as? String),
                        recyclingDays: parseDaySet(from: row["recycling_days"] as? String),
                        organicsDays: parseDaySet(from: row["organics_days"] as? String),
                        bulkDays: parseDaySet(from: row["bulk_days"] as? String),
                        lastUpdated: row["last_updated"] as? Date ?? Date()
                    )
                    
                    scheduleCache[buildingId] = schedule
                }
            }
        } catch {
            print("Failed to load cached schedules: \(error)")
        }
    }
    
    private func parseDaySet(from string: String?) -> Set<DSNY.DayOfWeek> {
        guard let string = string else { return [] }
        
        let components = string.split(separator: ",")
        return Set(components.compactMap { DSNY.DayOfWeek(rawValue: String($0)) })
    }
    
    // MARK: - Violation Management
    
    private func storeViolation(_ violation: DSNY.Violation, buildingId: String) async throws {
        try await GRDBManager.shared.execute("""
            INSERT INTO dsny_violations 
            (id, building_id, violation_type, issue_date, fine_amount, 
             status, description, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            violation.violationId,
            buildingId,
            violation.violationType.rawValue,
            violation.issueDate,
            violation.fineAmount,
            violation.status.rawValue,
            violation.description,
            Date()
        ])
    }
    
    private func notifyViolation(_ violation: DSNY.Violation, buildingId: String) async {
        let update = CoreTypes.DashboardUpdate(
            source: .system,
            type: .complianceStatusChanged,
            buildingId: buildingId,
            workerId: "",
            data: [
                "violationType": violation.violationType.rawValue,
                "severity": violation.violationType.severity.rawValue,
                "description": violation.description,
                "fineAmount": String(describing: violation.fineAmount)
            ]
        )
        
        await DashboardSyncService.shared.broadcastAdminUpdate(update)
    }
}

// MARK: - DSNY-Specific Supporting Types (Renamed to avoid conflicts)

public struct DSNYComplianceCheckResult {
    public let buildingId: String
    public let isCompliant: Bool
    public let violations: [DSNYComplianceViolation]
    public let lastChecked: Date
    
    public init(buildingId: String, isCompliant: Bool, violations: [DSNYComplianceViolation], lastChecked: Date) {
        self.buildingId = buildingId
        self.isCompliant = isCompliant
        self.violations = violations
        self.lastChecked = lastChecked
    }
}

public struct DSNYComplianceViolation {
    public let type: DSNY.CollectionType
    public let severity: DSNY.ComplianceSeverity
    public let message: String
    
    public init(type: DSNY.CollectionType, severity: DSNY.ComplianceSeverity, message: String) {
        self.type = type
        self.severity = severity
        self.message = message
    }
}

// MARK: - Errors

public enum DSNYError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noScheduleFound
    case apiTokenMissing
    case rateLimitExceeded
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from DSNY API"
        case .noScheduleFound:
            return "No collection schedule found for this location"
        case .apiTokenMissing:
            return "DSNY API token is missing"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        }
    }
}
