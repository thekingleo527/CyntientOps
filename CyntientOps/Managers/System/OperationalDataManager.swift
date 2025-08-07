/*
 * 🛡️ PRESERVATION NOTICE
 * This file contains the master operational playbook for Franco Management.
 * It is the authoritative source of all routine definitions.
 *
 * STATUS: PERMANENT REFERENCE - NEVER DELETE
 * Version: 1.0.0
 * Last Updated: 2024-01-31
 * Total Routines: 88
 * Total Workers: 7 (Jose Santos removed)
 * Total Buildings: 17
 *
 * CRITICAL DATA:
 * - Kevin Dutan: 38 tasks including Rubin Museum
 * - All worker assignments preserved with canonical IDs
 * - All building mappings preserved with canonical IDs
 *
 * ⚠️ MIGRATION NOTICE:
 * This data is being migrated to GRDB but must be preserved as the source of truth.
 * Any modifications MUST update the version number and checksum.
 */

import Foundation
import GRDB
import Combine
import CryptoKit  // For checksum generation

// MARK: - Canonical ID Reference

    public struct Buildings {
        static let westEighteenth12 = "1"
        static let eastTwentieth29_31 = "2"
        static let westSeventeenth135_139 = "3"
        static let franklin104 = "4"
        static let westSeventeenth138 = "5"
        static let perry68 = "6"
        static let westEighteenth112 = "7"
        static let elizabeth41 = "8"
        static let westSeventeenth117 = "9"
        static let perry131 = "10"
        static let firstAvenue123 = "11"
        static let westSeventeenth136 = "13"
        static let rubinMuseum = "14"
        static let eastFifteenth133 = "15"
        static let stuyvesantCove = "16"
        static let springStreet178 = "17"
        static let walker36 = "18"
        static let seventhAvenue115 = "19"
        static let francoSphereHQ = "20"
    }

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - Enhanced Task Structure with IDs
public struct OperationalDataTaskAssignment: Codable, Hashable {
    public let building: String
    public let taskName: String
    public let assignedWorker: String
    public let category: String
    public let skillLevel: String
    public let recurrence: String
    public let startHour: Int?
    public let endHour: Int?
    public let daysOfWeek: String?
    
    // NEW FIELDS for canonical IDs
    public let workerId: String
    public let buildingId: String
    public let requiresPhoto: Bool
    public let estimatedDuration: Int  // in minutes
    
    public init(
        building: String,
        taskName: String,
        assignedWorker: String,
        category: String,
        skillLevel: String,
        recurrence: String,
        startHour: Int? = nil,
        endHour: Int? = nil,
        daysOfWeek: String? = nil,
        workerId: String,
        buildingId: String,
        requiresPhoto: Bool = false,
        estimatedDuration: Int = 30
    ) {
        self.building = building
        self.taskName = taskName
        self.assignedWorker = assignedWorker
        self.category = category
        self.skillLevel = skillLevel
        self.recurrence = recurrence
        self.startHour = startHour
        self.endHour = endHour
        self.daysOfWeek = daysOfWeek
        self.workerId = workerId
        self.buildingId = buildingId
        self.requiresPhoto = requiresPhoto
        self.estimatedDuration = estimatedDuration
    }
}

// MARK: - Supporting Types
public struct SystemConfiguration {
    public let criticalOverdueThreshold: Int = 5
    public let minimumCompletionRate: Double = 0.7
    public let urgentTaskThreshold: Int = 10
    public let maxLiveUpdatesPerFeed: Int = 10
    public let autoSyncInterval: Double = 30.0
    
    public var isValid: Bool {
        return criticalOverdueThreshold > 0 &&
               minimumCompletionRate > 0 &&
               minimumCompletionRate <= 1.0 &&
               urgentTaskThreshold > 0 &&
               maxLiveUpdatesPerFeed > 0 &&
               autoSyncInterval > 0
    }
}

public struct OperationalEvent {
    public let id: String = UUID().uuidString
    public let timestamp: Date
    public let type: String
    public let buildingId: String?
    public let workerId: String?
    public let metadata: [String: Any]?
    
    public init(type: String, buildingId: String? = nil, workerId: String? = nil, metadata: [String: Any]? = nil) {
        self.timestamp = Date()
        self.type = type
        self.buildingId = buildingId
        self.workerId = workerId
        self.metadata = metadata
    }
}

public struct CachedBuilding {
    public let id: String
    public let name: String
    public let address: String?
    
    public init(id: String, name: String, address: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
    }
}

public struct CachedWorker {
    public let id: String
    public let name: String
    public let email: String?
    public let role: String?
    
    public init(id: String, name: String, email: String? = nil, role: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
    }
}

public struct LegacyTaskAssignment: Codable {
    public let building: String
    public let taskName: String
    public let assignedWorker: String
    public let category: String
    public let skillLevel: String
    public let recurrence: String
    public let startHour: Int?
    public let endHour: Int?
    public let daysOfWeek: String?
}

// MARK: - OperationalDataManager
@MainActor
public class OperationalDataManager: ObservableObject {
    public static let shared = OperationalDataManager()
    
    // MARK: - Version Tracking
    public static let dataVersion = "1.0.0"
    public static let lastUpdated = "2024-01-31"
    private var dataChecksum: String = ""
    private let checksumKey = "OperationalDataChecksum_v1"
    
    // MARK: - Migration Tracking
    private struct DataIntegrityInfo {
        let version: String
        let taskCount: Int
        let workerCount: Int
        let buildingCount: Int
        let checksum: String
        let timestamp: Date
    }
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    private let buildingMetrics = BuildingMetricsService.shared
    
    // MARK: - Published State
    @Published public var importProgress: Double = 0.0
    @Published public var currentStatus: String = ""
    @Published public var isInitialized = false
    
    // MARK: - Private State
    private var hasImported = false
    private var importErrors: [String] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Caching & Configuration
    private var cachedBuildings: [String: CachedBuilding] = [:]
    private var cachedWorkers: [String: CachedWorker] = [:]
    private var recentEvents: [OperationalEvent] = []
    private var syncEvents: [Date] = []
    private var errorLog: [(message: String, error: Error?, timestamp: Date)] = []
    private let systemConfig = SystemConfiguration()
    private var metricsHistory: [String: [(date: Date, value: Double)]] = [:]
    
    // MARK: - 🛡️ PRESERVED OPERATIONAL DATA
    // Every task updated with canonical IDs
    private let realWorldTasks: [OperationalDataTaskAssignment] = [
        
        // ───────────────────────────────
        //  KEVIN DUTAN (EXPANDED DUTIES)
        //  Mon-Fri 06:00-17:00
        //  38 tasks including Rubin Museum
        // ───────────────────────────────
        
        // Perry cluster (finish by 09:30)
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Sidewalk + Curb Sweep / Trash Return",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 6,
            endHour: 7,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Hallway & Stairwell Clean / Vacuum",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 7,
            endHour: 8,
            daysOfWeek: "Mon,Wed",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Hallway & Stairwell Vacuum (light)",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 7,
            endHour: 7,
            daysOfWeek: "Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Lobby + Packages Check",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 8,
            endHour: 8,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Vacuum Hallways Floor 2-6",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 8,
            endHour: 9,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Hose Down Sidewalks",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 9,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Clear Walls & Surfaces",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 10,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Check Bathroom + Trash Room",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 10,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Mop Stairs A & B",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        
        // 68 Perry Street tasks
        OperationalDataTaskAssignment(
            building: "68 Perry Street",
            taskName: "Sidewalk / Curb Sweep & Trash Return",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 8,
            endHour: 9,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry68,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "68 Perry Street",
            taskName: "Full Building Clean & Vacuum",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 8,
            endHour: 9,
            daysOfWeek: "Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry68,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "68 Perry Street",
            taskName: "Stairwell Hose-Down + Trash Area Hose",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 9,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry68,
            requiresPhoto: true,
            estimatedDuration: 30
        ),
        
        // 17th / 18th cluster
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "Trash Area + Sidewalk & Curb Clean",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "136 West 17th Street",
            taskName: "Trash Area + Sidewalk & Curb Clean",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth136,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "138 West 17th Street",
            taskName: "Trash Area + Sidewalk & Curb Clean",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 11,
            endHour: 12,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Trash Area Clean",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 11,
            endHour: 12,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "112 West 18th Street",
            taskName: "Trash Area Clean",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 11,
            endHour: 12,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        
        // ✅ CRITICAL: Kevin's Rubin Museum tasks
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "Trash Area + Sidewalk & Curb Clean",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "Museum Entrance Sweep",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 11,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "Weekly Deep Clean - Trash Area",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 12,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: true,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "DSNY: Set Out Trash",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 20,
            endHour: 21,
            daysOfWeek: "Sun,Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        
        // After-lunch satellite cleans
        OperationalDataTaskAssignment(
            building: "29-31 East 20th Street",
            taskName: "Hallway / Glass / Sidewalk Sweep & Mop",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 13,
            endHour: 14,
            daysOfWeek: "Tue",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.eastTwentieth29_31,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "123 1st Avenue",
            taskName: "Hallway & Curb Clean",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 13,
            endHour: 14,
            daysOfWeek: "Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.firstAvenue123,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "178 Spring Street",
            taskName: "Stair Hose & Garbage Return",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 14,
            endHour: 15,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.springStreet178,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        
        // DSNY put-out
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "DSNY: Set Out Trash",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 20,
            endHour: 21,
            daysOfWeek: "Sun,Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "136 West 17th Street",
            taskName: "DSNY: Set Out Trash",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 20,
            endHour: 21,
            daysOfWeek: "Sun,Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth136,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "138 West 17th Street",
            taskName: "DSNY: Set Out Trash",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 20,
            endHour: 21,
            daysOfWeek: "Sun,Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "178 Spring Street",
            taskName: "DSNY: Set Out Trash",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 20,
            endHour: 21,
            daysOfWeek: "Sun,Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.springStreet178,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        
        // Additional JM Buildings duties - KEVIN EXPANSION (10 tasks: 29-38)
        OperationalDataTaskAssignment(
            building: "136 West 17th Street",
            taskName: "Lobby + Entrance Deep Clean",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 15,
            endHour: 16,
            daysOfWeek: "Mon,Wed",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth136,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "138 West 17th Street", 
            taskName: "Stairwell Maintenance Check",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 16,
            endHour: 16,
            daysOfWeek: "Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            requiresPhoto: true,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "Gallery Entrance Surface Cleaning",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Intermediate",
            recurrence: "Daily",
            startHour: 16,
            endHour: 17,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Building Perimeter Security Check",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 15,
            endHour: 15,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "112 West 18th Street",
            taskName: "Trash Collection + Sorting",
            assignedWorker: "Kevin Dutan",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 14,
            endHour: 15,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Laundry Room Deep Clean + Maintenance",
            assignedWorker: "Kevin Dutan",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 14,
            endHour: 15,
            daysOfWeek: "Tue,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "68 Perry Street", 
            taskName: "Roof Access + Equipment Check",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Intermediate",
            recurrence: "Weekly",
            startHour: 15,
            endHour: 16,
            daysOfWeek: "Mon,Thu",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.perry68,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "Weekly HVAC Filter Inspection",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Intermediate",
            recurrence: "Weekly",
            startHour: 16,
            endHour: 17,
            daysOfWeek: "Wed",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "Building Systems Status Check",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 14,
            endHour: 14,
            daysOfWeek: "Tue,Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Emergency Equipment Verification",
            assignedWorker: "Kevin Dutan",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 15,
            endHour: 15,
            daysOfWeek: "Fri",
            workerId: CanonicalIDs.Workers.kevinDutan,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: true,
            estimatedDuration: 30
        ),
        
        // ───────────────────────────────
        //  MERCEDES INAMAGUA (06:30-11:00)
        // ───────────────────────────────
        OperationalDataTaskAssignment(
            building: "112 West 18th Street",
            taskName: "Glass & Lobby Clean",
            assignedWorker: "Mercedes Inamagua",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 6,
            endHour: 7,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Glass & Lobby Clean",
            assignedWorker: "Mercedes Inamagua",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 7,
            endHour: 8,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "Glass & Lobby Clean",
            assignedWorker: "Mercedes Inamagua",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 8,
            endHour: 9,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "136 West 17th Street",
            taskName: "Glass & Lobby Clean",
            assignedWorker: "Mercedes Inamagua",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 9,
            endHour: 10,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.westSeventeenth136,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "138 West 17th Street",
            taskName: "Glass & Lobby Clean",
            assignedWorker: "Mercedes Inamagua",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "Rubin Museum (142–148 W 17th)",
            taskName: "Roof Drain – 2F Terrace",
            assignedWorker: "Mercedes Inamagua",
            category: "Maintenance",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 10,
            daysOfWeek: "Wed",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "104 Franklin Street",
            taskName: "Office Deep Clean",
            assignedWorker: "Mercedes Inamagua",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 14,
            endHour: 16,
            daysOfWeek: "Mon,Thu",
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            buildingId: CanonicalIDs.Buildings.franklin104,
            requiresPhoto: false,
            estimatedDuration: 120
        ),
        
        // ───────────────────────────────
        //  EDWIN LEMA (06:00-15:00)
        // ───────────────────────────────
        OperationalDataTaskAssignment(
            building: "Stuyvesant Cove Park",
            taskName: "Morning Park Check",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Intermediate",
            recurrence: "Daily",
            startHour: 6,
            endHour: 7,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat,Sun",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.stuyvesantCove,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "Stuyvesant Cove Park",
            taskName: "Power Wash Walkways",
            assignedWorker: "Edwin Lema",
            category: "Cleaning",
            skillLevel: "Intermediate",
            recurrence: "Monthly",
            startHour: 7,
            endHour: 9,
            daysOfWeek: nil,
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.stuyvesantCove,
            requiresPhoto: true,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "133 East 15th Street",
            taskName: "Building Walk-Through",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Intermediate",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 10,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.eastFifteenth133,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "133 East 15th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 9,
            daysOfWeek: "Mon",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.eastFifteenth133,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "CyntientOps HQ",
            taskName: "Scheduled Repairs & Follow-ups",
            assignedWorker: "Edwin Lema",
            category: "Repair",
            skillLevel: "Intermediate",
            recurrence: "Daily",
            startHour: 13,
            endHour: 15,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.francoSphereHQ,
            requiresPhoto: true,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Water Filter Change & Roof Drain Check",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Intermediate",
            recurrence: "Bi-Monthly",
            startHour: 10,
            endHour: 11,
            daysOfWeek: nil,
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "112 West 18th Street",
            taskName: "Water Filter Change & Roof Drain Check",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Intermediate",
            recurrence: "Bi-Monthly",
            startHour: 11,
            endHour: 12,
            daysOfWeek: nil,
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "Backyard Drain Check",
            assignedWorker: "Edwin Lema",
            category: "Inspection",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 10,
            daysOfWeek: "Fri",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "131 Perry Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 8,
            endHour: 8,
            daysOfWeek: "Wed",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.perry131,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "138 West 17th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 10,
            daysOfWeek: "Thu",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 10,
            endHour: 10,
            daysOfWeek: "Tue",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Edwin Lema",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 11,
            endHour: 11,
            daysOfWeek: "Tue",
            workerId: CanonicalIDs.Workers.edwinLema,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        
        // ───────────────────────────────
        //  LUIS LOPEZ (07:00-16:00)
        // ───────────────────────────────
        OperationalDataTaskAssignment(
            building: "104 Franklin Street",
            taskName: "Sidewalk Hose",
            assignedWorker: "Luis Lopez",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 7,
            endHour: 7,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.franklin104,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "36 Walker Street",
            taskName: "Sidewalk Sweep",
            assignedWorker: "Luis Lopez",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 7,
            endHour: 8,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.walker36,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "41 Elizabeth Street",
            taskName: "Bathrooms Clean",
            assignedWorker: "Luis Lopez",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 8,
            endHour: 9,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.elizabeth41,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "41 Elizabeth Street",
            taskName: "Lobby & Sidewalk Clean",
            assignedWorker: "Luis Lopez",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 9,
            endHour: 10,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.elizabeth41,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "41 Elizabeth Street",
            taskName: "Elevator Clean",
            assignedWorker: "Luis Lopez",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.elizabeth41,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "41 Elizabeth Street",
            taskName: "Afternoon Garbage Removal",
            assignedWorker: "Luis Lopez",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 13,
            endHour: 14,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri,Sat",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.elizabeth41,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "41 Elizabeth Street",
            taskName: "Deliver Mail & Packages",
            assignedWorker: "Luis Lopez",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 14,
            endHour: 14,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.luisLopez,
            buildingId: CanonicalIDs.Buildings.elizabeth41,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        
        // ───────────────────────────────
        //  ANGEL GUIRACHOCHA (18:00-22:00)
        // ───────────────────────────────
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Evening Garbage Collection",
            assignedWorker: "Angel Guirachocha",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 18,
            endHour: 19,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "68 Perry Street",
            taskName: "DSNY: Bring In Trash Bins",
            assignedWorker: "Angel Guirachocha",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 19,
            endHour: 20,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            buildingId: CanonicalIDs.Buildings.perry68,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "123 1st Avenue",
            taskName: "DSNY: Bring In Trash Bins",
            assignedWorker: "Angel Guirachocha",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 19,
            endHour: 20,
            daysOfWeek: "Tue,Thu",
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            buildingId: CanonicalIDs.Buildings.firstAvenue123,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "104 Franklin Street",
            taskName: "DSNY: Bring In Trash Bins",
            assignedWorker: "Angel Guirachocha",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "Weekly",
            startHour: 20,
            endHour: 21,
            daysOfWeek: "Mon,Wed,Fri",
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            buildingId: CanonicalIDs.Buildings.franklin104,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "135-139 West 17th Street",
            taskName: "Evening Building Security Check",
            assignedWorker: "Angel Guirachocha",
            category: "Inspection",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 21,
            endHour: 22,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        
        // ───────────────────────────────
        //  GREG HUTSON (09:00-15:00)
        // ───────────────────────────────
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Sidewalk & Curb Clean",
            assignedWorker: "Greg Hutson",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 9,
            endHour: 10,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.gregHutson,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Lobby & Vestibule Clean",
            assignedWorker: "Greg Hutson",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 10,
            endHour: 11,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.gregHutson,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Glass & Elevator Clean",
            assignedWorker: "Greg Hutson",
            category: "Cleaning",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 11,
            endHour: 12,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.gregHutson,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: false,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Trash Area Clean",
            assignedWorker: "Greg Hutson",
            category: "Sanitation",
            skillLevel: "Basic",
            recurrence: "Daily",
            startHour: 13,
            endHour: 14,
            daysOfWeek: "Mon,Tue,Wed,Thu,Fri",
            workerId: CanonicalIDs.Workers.gregHutson,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: true,
            estimatedDuration: 60
        ),
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Greg Hutson",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 14,
            endHour: 14,
            daysOfWeek: "Fri",
            workerId: CanonicalIDs.Workers.gregHutson,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        OperationalDataTaskAssignment(
            building: "12 West 18th Street",
            taskName: "Freight Elevator Operation (On-Demand)",
            assignedWorker: "Greg Hutson",
            category: "Operations",
            skillLevel: "Basic",
            recurrence: "On-Demand",
            startHour: nil,
            endHour: nil,
            daysOfWeek: nil,
            workerId: CanonicalIDs.Workers.gregHutson,
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            requiresPhoto: false,
            estimatedDuration: 30
        ),
        
        // ───────────────────────────────
        //  SHAWN MAGLOIRE (floating specialist)
        // ───────────────────────────────
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 11,
            daysOfWeek: "Mon",
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: false,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "133 East 15th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 11,
            endHour: 13,
            daysOfWeek: "Tue",
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.eastFifteenth133,
            requiresPhoto: false,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "136 West 17th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 13,
            endHour: 15,
            daysOfWeek: "Wed",
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.westSeventeenth136,
            requiresPhoto: false,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "138 West 17th Street",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 15,
            endHour: 17,
            daysOfWeek: "Thu",
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            requiresPhoto: false,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "115 7th Avenue",
            taskName: "Boiler Blow-Down",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Weekly",
            startHour: 9,
            endHour: 11,
            daysOfWeek: "Fri",
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.seventhAvenue115,
            requiresPhoto: false,
            estimatedDuration: 120
        ),
        OperationalDataTaskAssignment(
            building: "112 West 18th Street",
            taskName: "HVAC System Check",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Monthly",
            startHour: 9,
            endHour: 12,
            daysOfWeek: nil,
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            requiresPhoto: true,
            estimatedDuration: 180
        ),
        OperationalDataTaskAssignment(
            building: "117 West 17th Street",
            taskName: "HVAC System Check",
            assignedWorker: "Shawn Magloire",
            category: "Maintenance",
            skillLevel: "Advanced",
            recurrence: "Monthly",
            startHour: 13,
            endHour: 16,
            daysOfWeek: nil,
            workerId: CanonicalIDs.Workers.shawnMagloire,
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            requiresPhoto: true,
            estimatedDuration: 180
        )
    ]
    
    // MARK: - Routine Schedules
    private let routineSchedules: [(buildingId: String, name: String, rrule: String, workerId: String, category: String)] = [
        // Kevin's Perry Street circuit
        ("10", "Daily Sidewalk Sweep", "FREQ=DAILY;BYHOUR=6", "4", "Cleaning"),
        ("10", "Weekly Hallway Deep Clean", "FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=7", "4", "Cleaning"),
        ("6", "Perry 68 Full Building Clean", "FREQ=WEEKLY;BYDAY=TU,TH;BYHOUR=8", "4", "Cleaning"),
        ("7", "17th Street Trash Area Maintenance", "FREQ=DAILY;BYHOUR=11", "4", "Cleaning"),
        ("9", "DSNY: Compliance Check", "FREQ=WEEKLY;BYDAY=SU,TU,TH;BYHOUR=20", "4", "Operations"),
        
        // Kevin's Rubin Museum routing
        ("14", "Rubin Morning Trash Circuit", "FREQ=DAILY;BYHOUR=10", "4", "Sanitation"),
        ("14", "Rubin Museum Deep Clean", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=10", "4", "Sanitation"),
        ("14", "Rubin DSNY Operations", "FREQ=WEEKLY;BYDAY=SU,TU,TH;BYHOUR=20", "4", "Operations"),
        
        // Mercedes' morning glass circuit
        ("7", "Glass & Lobby Clean", "FREQ=DAILY;BYHOUR=6", "5", "Cleaning"),
        ("9", "117 West 17th Glass & Vestibule", "FREQ=DAILY;BYHOUR=7", "5", "Cleaning"),
        ("3", "135-139 West 17th Glass Clean", "FREQ=DAILY;BYHOUR=8", "5", "Cleaning"),
        ("14", "Rubin Museum Roof Drain Check", "FREQ=WEEKLY;BYDAY=WE;BYHOUR=10", "5", "Maintenance"),
        
        // Edwin's maintenance rounds
        ("16", "Stuyvesant Park Morning Inspection", "FREQ=DAILY;BYHOUR=6", "2", "Maintenance"),
        ("15", "133 E 15th Boiler Blow-Down", "FREQ=WEEKLY;BYDAY=MO;BYHOUR=9", "2", "Maintenance"),
        ("9", "Water Filter Change", "FREQ=MONTHLY;BYHOUR=10", "2", "Maintenance"),
        
        // Luis Lopez daily circuit
        ("4", "104 Franklin Sidewalk Hose", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=7", "6", "Cleaning"),
        ("8", "41 Elizabeth Full Service", "FREQ=DAILY;BYHOUR=8", "6", "Cleaning"),
        
        // Greg Hutson building specialist
        ("1", "12 West 18th Complete Service", "FREQ=DAILY;BYHOUR=9", "1", "Cleaning"),
        
        // Angel evening operations
        ("1", "Evening Security Check", "FREQ=DAILY;BYHOUR=21", "7", "Operations"),
        
        // Shawn specialist maintenance
        ("14", "Rubin Museum HVAC Systems", "FREQ=MONTHLY;BYHOUR=9", "8", "Maintenance"),
    ]
    
    private let dsnySchedules: [(buildingIds: [String], collectionDays: String, routeId: String)] = [
        // Manhattan West 17th Street corridor (including Rubin Museum)
        (["7", "9", "3", "14"], "MON,WED,FRI", "MAN-17TH-WEST"),
        
        // Perry Street / West Village
        (["10", "6"], "MON,WED,FRI", "MAN-PERRY-VILLAGE"),
        
        // Downtown / Tribeca route
        (["4", "8"], "TUE,THU,SAT", "MAN-DOWNTOWN-TRI"),
        
        // East side route
        (["1"], "MON,WED,FRI", "MAN-18TH-EAST"),
        
        // Special collections (Rubin Museum enhanced)
        (["14"], "TUE,FRI", "MAN-MUSEUM-SPECIAL"),
    ]
    
    private init() {
        setupCachedData()
    }
    
    // MARK: - Checksum Generation
    
    /// Generate SHA256 checksum of operational data for integrity verification
    public func generateChecksum() -> String {
        var dataString = "VERSION:\(Self.dataVersion)\n"
        dataString += "TASKS:\(realWorldTasks.count)\n"
        
        // Sort tasks for consistent checksum
        let sortedTasks = realWorldTasks.sorted { t1, t2 in
            "\(t1.building)\(t1.taskName)\(t1.assignedWorker)" <
            "\(t2.building)\(t2.taskName)\(t2.assignedWorker)"
        }
        
        for task in sortedTasks {
            dataString += "TASK:\(task.building)|\(task.taskName)|\(task.assignedWorker)|\(task.category)|\(task.recurrence)\n"
        }
        
        // Generate SHA256 hash
        let data = Data(dataString.utf8)
        let hash = SHA256.hash(data: data)
        let checksum = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Store checksum
        self.dataChecksum = checksum
        UserDefaults.standard.set(checksum, forKey: checksumKey)
        
        print("📊 Generated checksum: \(checksum.prefix(16))...")
        return checksum
    }
    
    /// Verify data integrity against stored checksum
    public func verifyDataIntegrity() -> Bool {
        let currentChecksum = generateChecksum()
        let storedChecksum = UserDefaults.standard.string(forKey: checksumKey)
        
        if let stored = storedChecksum {
            let isValid = currentChecksum == stored
            print("🔐 Data integrity check: \(isValid ? "✅ VALID" : "❌ MODIFIED")")
            return isValid
        } else {
            print("🔐 No previous checksum found - storing current")
            return true
        }
    }
    
    /// Get current data integrity information
    private func getDataIntegrityInfo() -> DataIntegrityInfo {
        return DataIntegrityInfo(
            version: Self.dataVersion,
            taskCount: realWorldTasks.count,
            workerCount: getUniqueWorkerNames().count,
            buildingCount: getUniqueBuildingNames().count,
            checksum: dataChecksum.isEmpty ? generateChecksum() : dataChecksum,
            timestamp: Date()
        )
    }
    
    // MARK: - System Configuration
    
    public func getSystemConfiguration() -> SystemConfiguration {
        return systemConfig
    }
    
    // MARK: - Cached Data Access
    
    public func getCachedWorkerCount() -> Int {
        return cachedWorkers.count
    }
    
    public func getCachedBuildingCount() -> Int {
        return cachedBuildings.count
    }
    
    public func getBuilding(byId buildingId: String) -> CachedBuilding? {
        if let cached = cachedBuildings[buildingId] {
            return cached
        }
        
        Task { @MainActor in
            await refreshBuildingCache()
        }
        
        return cachedBuildings[buildingId]
    }
    
    public func getWorker(byId workerId: String) -> CachedWorker? {
        if let cached = cachedWorkers[workerId] {
            return cached
        }
        
        Task { @MainActor in
            await refreshWorkerCache()
        }
        
        return cachedWorkers[workerId]
    }
    
    public func getRandomWorker() -> CachedWorker? {
        let workers = Array(cachedWorkers.values)
        return workers.randomElement()
    }
    
    public func getRandomBuilding() -> CachedBuilding? {
        let buildings = Array(cachedBuildings.values)
        return buildings.randomElement()
    }
    
    // MARK: - Event Tracking
    
    public func recordSyncEvent(timestamp: Date) {
        syncEvents.append(timestamp)
        
        if syncEvents.count > 100 {
            syncEvents.removeFirst(syncEvents.count - 100)
        }
    }
    
    public func logError(_ message: String, error: Error? = nil) {
        errorLog.append((message: message, error: error, timestamp: Date()))
        
        if errorLog.count > 50 {
            errorLog.removeFirst(errorLog.count - 50)
        }
        
        print("❌ OperationalDataManager Error: \(message) - \(error?.localizedDescription ?? "No error details")")
    }
    
    public func getRecentEvents(limit: Int) -> [OperationalEvent] {
        return Array(recentEvents.suffix(limit))
    }
    
    private func addOperationalEvent(_ event: OperationalEvent) {
        recentEvents.append(event)
        
        if recentEvents.count > 200 {
            recentEvents.removeFirst(recentEvents.count - 200)
        }
    }
    
    // MARK: - Trend Analysis
    
    public func calculateTrend(for metricName: String, days: Int) -> CoreTypes.TrendDirection {
        guard let history = metricsHistory[metricName] else {
            return .stable
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentData = history.filter { $0.date > cutoffDate }
        
        guard recentData.count >= 2 else {
            return .stable
        }
        
        let values = recentData.map { $0.value }
        let avgFirst = values.prefix(values.count / 2).reduce(0, +) / Double(values.count / 2)
        let avgSecond = values.suffix(values.count / 2).reduce(0, +) / Double(values.count / 2)
        
        let changePercent = ((avgSecond - avgFirst) / avgFirst) * 100
        
        if changePercent > 5 {
            return .improving
        } else if changePercent < -5 {
            return .declining
        } else {
            return .stable
        }
    }
    
    public func recordMetricValue(metricName: String, value: Double) {
        if metricsHistory[metricName] == nil {
            metricsHistory[metricName] = []
        }
        
        metricsHistory[metricName]?.append((date: Date(), value: value))
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        metricsHistory[metricName] = metricsHistory[metricName]?.filter { $0.date > cutoff }
    }
    
    // MARK: - Setup Methods
    
    private func setupCachedData() {
        let activeWorkerData: [(id: String, name: String, email: String, role: String)] = [
            ("1", "Greg Hutson", "greg.hutson@francomanagement.com", "Maintenance"),
            ("2", "Edwin Lema", "edwin.lema@francomanagement.com", "Cleaning"),
            ("4", "Kevin Dutan", "kevin.dutan@francomanagement.com", "Cleaning"),
            ("5", "Mercedes Inamagua", "mercedes.inamagua@francomanagement.com", "Cleaning"),
            ("6", "Luis Lopez", "luis.lopez@francomanagement.com", "Maintenance"),
            ("7", "Angel Guirachocha", "angel.guirachocha@francomanagement.com", "Sanitation"),
            ("8", "Shawn Magloire", "shawn.magloire@francomanagement.com", "Management")
        ]
        
        for (id, name, email, role) in activeWorkerData {
            cachedWorkers[id] = CachedWorker(id: id, name: name, email: email, role: role)
        }
        
        let buildingData: [(id: String, name: String)] = [
            ("1", "12 West 18th Street"),
            ("2", "29-31 East 20th Street"),
            ("3", "135-139 West 17th Street"),
            ("4", "104 Franklin Street"),
            ("5", "138 West 17th Street"),
            ("6", "68 Perry Street"),
            ("7", "112 West 18th Street"),
            ("8", "41 Elizabeth Street"),
            ("9", "117 West 17th Street"),
            ("10", "131 Perry Street"),
            ("11", "123 1st Avenue"),
            ("13", "136 West 17th Street"),
            ("14", "Rubin Museum (142–148 W 17th)"),
            ("15", "133 East 15th Street"),
            ("16", "Stuyvesant Cove Park"),
            ("17", "178 Spring Street"),
            ("18", "36 Walker Street"),
            ("19", "115 7th Avenue"),
            ("20", "CyntientOps HQ")
        ]
        
        for (id, name) in buildingData {
            cachedBuildings[id] = CachedBuilding(id: id, name: name)
        }
    }
    
    // MARK: - Public API
    
    public func getAllRealWorldTasks() -> [OperationalDataTaskAssignment] {
        return realWorldTasks
    }
    
    public func getRealWorldTasks(for workerName: String) -> [OperationalDataTaskAssignment] {
        return realWorldTasks.filter { $0.assignedWorker == workerName }
    }
    
    public func getTasksForBuilding(_ buildingName: String) -> [OperationalDataTaskAssignment] {
        return realWorldTasks.filter { $0.building.contains(buildingName) }
    }
    
    public var realWorldTaskCount: Int {
        return realWorldTasks.count
    }
    
    public func getUniqueWorkerNames() -> Set<String> {
        return Set(realWorldTasks.map { $0.assignedWorker })
    }
    
    public func getUniqueBuildingNames() -> Set<String> {
        return Set(realWorldTasks.map { $0.building })
    }
    
    // MARK: - Backup Methods
    
    /// Create JSON backup of operational data
    public func createOperationalDataBackup() async throws {
        let backupData = try JSONEncoder().encode(realWorldTasks)
        
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let backupPath = documentsPath
            .appendingPathComponent("Backups")
            .appendingPathComponent("operational_data_\(Date().timeIntervalSince1970).json")
        
        try FileManager.default.createDirectory(
            at: backupPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        try backupData.write(to: backupPath)
        
        print("✅ Operational data backed up to: \(backupPath)")
        
        // Add backup event
        let event = OperationalEvent(
            type: "Backup Created",
            metadata: ["path": backupPath.path, "size": backupData.count]
        )
        addOperationalEvent(event)
    }
    
    // MARK: - Cache Refresh Methods
    
    private func refreshBuildingCache() async {
        do {
            let buildings = try await grdbManager.query("""
                SELECT id, name, address FROM buildings WHERE is_active = 1
            """)
            
            for building in buildings {
                guard let id = building["id"] as? String,
                      let name = building["name"] as? String else { continue }
                
                let address = building["address"] as? String
                cachedBuildings[id] = CachedBuilding(id: id, name: name, address: address)
            }
        } catch {
            logError("Failed to refresh building cache", error: error)
        }
    }
    
    private func refreshWorkerCache() async {
        do {
            let workers = try await grdbManager.query("""
                SELECT id, name, email, role FROM workers WHERE isActive = 1
            """)
            
            for worker in workers {
                guard let id = worker["id"] as? String,
                      let name = worker["name"] as? String else { continue }
                
                let email = worker["email"] as? String
                let role = worker["role"] as? String
                cachedWorkers[id] = CachedWorker(id: id, name: name, email: email, role: role)
            }
        } catch {
            logError("Failed to refresh worker cache", error: error)
        }
    }
    
    // MARK: - Real-Time Synchronization
    
    public func setupRealTimeSync() async {
        let publisher = await buildingMetrics.subscribeToMultipleMetrics(for: [])
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("⚠️ Real-time sync error: \(error)")
                }
            } receiveValue: { [weak self] metrics in
                self?.updateOperationalStatus(with: metrics)
            }
            .store(in: &cancellables)
    }
    
    private func updateOperationalStatus(with metrics: [String: BuildingMetrics]) {
        let totalBuildings = metrics.count
        let efficientBuildings = metrics.values.filter { $0.completionRate > 0.8 }.count
        
        let efficiency = totalBuildings > 0 ? Double(efficientBuildings) / Double(totalBuildings) : 1.0
        
        if efficiency > 0.9 {
            currentStatus = "Operations running smoothly"
        } else if efficiency > 0.7 {
            currentStatus = "Operations normal with minor issues"
        } else {
            currentStatus = "Operations require attention"
        }
        
        recordMetricValue(metricName: "portfolio_efficiency", value: efficiency)
        
        let event = OperationalEvent(
            type: "Metrics Updated",
            metadata: ["efficiency": efficiency, "buildingCount": totalBuildings]
        )
        addOperationalEvent(event)
    }
    
    // MARK: - Import Methods
    
    public func importRoutinesAndDSNYAsync() async throws -> (routines: Int, dsny: Int) {
        return try await importRoutinesAndDSNY()
    }
    
    public func initializeOperationalData() async throws {
        guard !hasImported else {
            print("✅ Operational data already initialized")
            await MainActor.run {
                isInitialized = true
                currentStatus = "Ready"
            }
            return
        }
        
        await MainActor.run {
            importProgress = 0.0
            currentStatus = "Initializing GRDB database..."
        }
        
        do {
            await MainActor.run {
                importProgress = 0.1
                currentStatus = "Seeding GRDB database..."
            }
            
            print("📦 Preparing to import operational data...")
            
            await MainActor.run {
                importProgress = 0.3
                currentStatus = "Importing preserved worker assignments..."
            }
            
            let (imported, errors) = try await importRealWorldTasks()
            print("✅ Imported \(imported) tasks with \(errors.count) errors")
            
            await MainActor.run {
                importProgress = 0.7
                currentStatus = "Importing routine schedules..."
            }
            
            let routineResult = try await importRoutinesAndDSNYAsync()
            let routineCount = routineResult.routines
            let dsnyCount = routineResult.dsny
            
            await MainActor.run {
                importProgress = 0.9
                currentStatus = "Validating data integrity..."
            }
            
            try await validateDataIntegrity()
            
            hasImported = true
            await MainActor.run {
                importProgress = 1.0
                currentStatus = "Ready"
                isInitialized = true
            }
            
            await refreshBuildingCache()
            await refreshWorkerCache()
            
            print("✅ GRDB operational data initialization complete - ALL original data preserved")
            
            let event = OperationalEvent(
                type: "System Initialized",
                metadata: ["taskCount": imported, "routineCount": routineCount, "dsnyCount": dsnyCount]
            )
            addOperationalEvent(event)
            
        } catch {
            await MainActor.run {
                currentStatus = "Initialization failed: \(error.localizedDescription)"
            }
            logError("Failed to initialize operational data", error: error)
            throw error
        }
    }
    
    // MARK: - Import Real World Tasks
    
    func importRealWorldTasks() async throws -> (imported: Int, errors: [String]) {
        guard !hasImported else {
            print("✅ Tasks already imported, skipping duplicate import")
            return (0, [])
        }
        
        await MainActor.run {
            importProgress = 0.0
            currentStatus = "Starting GRDB import..."
            importErrors = []
        }
        
        do {
            try await seedActiveWorkers()
            
            await MainActor.run {
                importProgress = 0.1
                currentStatus = "Workers seeded, importing tasks with GRDB..."
            }
            
            var importedCount = 0
            let calendar = Calendar.current
            let today = Date()
            
            print("📂 Starting GRDB task import with \(realWorldTasks.count) preserved tasks...")
            currentStatus = "Importing \(realWorldTasks.count) tasks for current active workers with GRDB..."
            
            try await populateWorkerBuildingAssignments(realWorldTasks)
            
            for (index, operationalTask) in realWorldTasks.enumerated() {
                do {
                    importProgress = 0.1 + (0.8 * Double(index) / Double(realWorldTasks.count))
                    currentStatus = "Importing task \(index + 1)/\(realWorldTasks.count) with GRDB"
                    
                    let externalId = generateExternalId(for: operationalTask, index: index)
                    
                    let existingTasks = try await grdbManager.query("""
                        SELECT id FROM tasks WHERE external_id = ?
                        """, [externalId])
                    
                    if !existingTasks.isEmpty {
                        print("⏭️ Skipping duplicate task: \(operationalTask.taskName)")
                        continue
                    }
                    
                    let dueDate = calculateDueDate(for: operationalTask.recurrence, from: today)
                    let buildingId = try await mapBuildingNameToId(operationalTask.building)
                    
                    let workerId: Int? = if !operationalTask.assignedWorker.isEmpty {
                        try? await mapWorkerNameToId(operationalTask.assignedWorker)
                    } else {
                        nil
                    }
                    
                    guard let validWorkerId = workerId else {
                        print("⚠️ Skipping task for inactive worker: \(operationalTask.assignedWorker)")
                        continue
                    }
                    
                    var startTime: String? = nil
                    var endTime: String? = nil
                    
                    if let startHour = operationalTask.startHour, let endHour = operationalTask.endHour {
                        if let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: dueDate),
                           let end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: dueDate) {
                            startTime = start.iso8601String
                            endTime = end.iso8601String
                        }
                    }
                    
                    let urgencyLevel = operationalTask.skillLevel == "Advanced" ? "high" :
                    operationalTask.skillLevel == "Intermediate" ? "medium" : "low"
                    
                    try await grdbManager.execute("""
                        INSERT INTO tasks (
                            name, description, buildingId, workerId, isCompleted,
                            scheduledDate, recurrence, urgencyLevel, category,
                            startTime, endTime, external_id
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, [
                            operationalTask.taskName,
                            "Imported from current active worker schedule",
                            "\(buildingId)",
                            "\(validWorkerId)",
                            "0",
                            dueDate.iso8601String,
                            operationalTask.recurrence,
                            urgencyLevel,
                            operationalTask.category,
                            startTime ?? "",
                            endTime ?? "",
                            externalId
                        ])
                    
                    importedCount += 1
                    
                    if operationalTask.assignedWorker == "Kevin Dutan" && operationalTask.building.contains("Rubin") {
                        print("✅ PRESERVED: Imported Kevin's Rubin Museum task with GRDB: \(operationalTask.taskName)")
                    } else {
                        print("✅ Imported with GRDB: \(operationalTask.taskName) for \(operationalTask.building) (\(operationalTask.assignedWorker))")
                    }
                    
                    if (index + 1) % 10 == 0 {
                        print("📈 Imported \(index + 1)/\(realWorldTasks.count) tasks with GRDB")
                    }
                    
                    let event = OperationalEvent(
                        type: "Task Imported",
                        buildingId: "\(buildingId)",
                        workerId: "\(validWorkerId)",
                        metadata: ["taskName": operationalTask.taskName, "category": operationalTask.category]
                    )
                    addOperationalEvent(event)
                    
                } catch {
                    let errorMsg = "Error processing task \(operationalTask.taskName) with GRDB: \(error.localizedDescription)"
                    importErrors.append(errorMsg)
                    print("❌ \(errorMsg)")
                }
            }
            
            hasImported = true
            
            await MainActor.run {
                importProgress = 1.0
                currentStatus = "GRDB import complete!"
            }
            
            await logImportResults(imported: importedCount, errors: importErrors)
            
            return (importedCount, importErrors)
            
        } catch {
            await MainActor.run {
                currentStatus = "GRDB import failed: \(error.localizedDescription)"
            }
            logError("Task import failed", error: error)
            throw error
        }
    }
    public func generateDSNYTasksForBuilding(
        _ building: CoreTypes.NamedCoordinate,
        workerId: String,
        date: Date = Date()
    ) async throws -> [OperationalDataTaskAssignment] {
        let dsnyTasks = try await DSNYAPIService.shared.generateDSNYTasks(
            for: building,
            workerId: workerId,
            date: date
        )
        
        return dsnyTasks.map { task in
            OperationalDataTaskAssignment(
                building: building.name,
                taskName: task.title,
                assignedWorker: "DSNY Worker",
                category: "Sanitation",
                skillLevel: "Standard",
                recurrence: "Weekly",
                workerId: workerId,
                buildingId: building.id,
                requiresPhoto: task.requiresPhoto ?? true,
                estimatedDuration: 15
            )
        }
    }
    // MARK: - Helper Methods
    
    private func generateExternalId(for task: OperationalDataTaskAssignment, index: Int) -> String {
        let components = [
            task.building,
            task.taskName,
            task.assignedWorker,
            task.recurrence,
            task.daysOfWeek ?? "all",
            String(index)
        ]
        let combined = components.joined(separator: "|")
        return "OPERATIONAL-PRESERVED-\(combined.hashValue)-\(index)"
    }
    
    private func calculateDueDate(for recurrence: String, from date: Date) -> Date {
        let calendar = Calendar.current
        
        switch recurrence {
        case "Daily":
            return date
        case "Weekly":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Bi-Weekly":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Monthly", "Bi-Monthly":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Quarterly":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Semiannual":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "Annual":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        case "On-Demand":
            let daysToAdd = calculateFixedScore(for: recurrence)
            return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
        default:
            return date
        }
    }
    
    private func calculateFixedScore(for recurrence: String) -> Int {
        switch recurrence {
        case "Daily":
            return 0
        case "Weekly":
            return 7
        case "Bi-Weekly":
            return 14
        case "Monthly":
            return 30
        case "Bi-Monthly":
            return 60
        case "Quarterly":
            return 90
        case "Semiannual":
            return 180
        case "Annual":
            return 365
        case "On-Demand":
            return 1
        default:
            return 1
        }
    }
    
    private func mapBuildingNameToId(_ buildingName: String) async throws -> Int {
        let buildings = try await BuildingService.shared.getAllBuildings()
        
        let cleanedName = buildingName
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .whitespaces)
        
        if cleanedName.lowercased().contains("rubin") {
            return 14
        }
        
        if let building = buildings.first(where: { building in
            building.name.compare(cleanedName, options: .caseInsensitive) == .orderedSame ||
            building.name.compare(buildingName, options: .caseInsensitive) == .orderedSame
        }), let id = Int(building.id) {
            return id
        }
        
        throw OperationalError.buildingNotFound(buildingName)
    }
    
    private func mapWorkerNameToId(_ workerName: String) async throws -> Int {
        if workerName.contains("Jose") || workerName.contains("Santos") {
            throw OperationalError.workerNotFound("Jose Santos is no longer with the company")
        }
        
        let workerResults = try await grdbManager.query("""
            SELECT id FROM workers WHERE name = ?
        """, [workerName])
        
        if let worker = workerResults.first {
            if let workerId = worker["id"] as? Int64 {
                return Int(workerId)
            } else if let workerId = worker["id"] as? Int {
                return workerId
            }
        }
        
        throw OperationalError.workerNotFound(workerName)
    }
    
    private func logImportResults(imported: Int, errors: [String]) async {
        await MainActor.run {
            currentStatus = "Import complete: \(imported) tasks imported"
            if !errors.isEmpty {
                print("⚠️ Import completed with \(errors.count) errors:")
                for error in errors.prefix(3) {
                    print("   • \(error)")
                }
            } else {
                print("✅ All tasks imported successfully with GRDB")
            }
        }
    }
    
    // MARK: - Worker Management
    
    private func seedActiveWorkers() async throws {
        print("🔧 Seeding active workers table with GRDB...")
        
        let activeWorkers = [
            ("1", "Greg Hutson", "greg.hutson@francomanagement.com", "Maintenance"),
            ("2", "Edwin Lema", "edwin.lema@francomanagement.com", "Cleaning"),
            ("4", "Kevin Dutan", "kevin.dutan@francomanagement.com", "Cleaning"),
            ("5", "Mercedes Inamagua", "mercedes.inamagua@francomanagement.com", "Cleaning"),
            ("6", "Luis Lopez", "luis.lopez@francomanagement.com", "Maintenance"),
            ("7", "Angel Guirachocha", "angel.guirachocha@francomanagement.com", "Sanitation"),
            ("8", "Shawn Magloire", "shawn.magloire@francomanagement.com", "Management")
        ]
        
        for (id, name, email, role) in activeWorkers {
            let existingWorker = try await grdbManager.query(
                "SELECT id FROM workers WHERE id = ? LIMIT 1",
                [id]
            )
            
            if existingWorker.isEmpty {
                try await grdbManager.execute("""
                    INSERT INTO workers (id, name, email, role, isActive, shift, hireDate) 
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, [
                        id,
                        name,
                        email,
                        role,
                        "1",
                        getWorkerShift(id),
                        "2023-01-01"
                    ])
                
                print("✅ Created worker record with GRDB: \(name) (ID: \(id))")
            } else {
                print("✓ Worker exists in GRDB: \(name) (ID: \(id))")
            }
        }
        
        let kevinCheck = try await grdbManager.query(
            "SELECT id, name FROM workers WHERE id = '4' LIMIT 1",
            []
        )
        
        if kevinCheck.isEmpty {
            print("❌ CRITICAL: Kevin still not found after GRDB seeding!")
        } else {
            print("✅ VERIFIED: Kevin Dutan (ID: 4) exists in GRDB workers table")
        }
    }
    
    private func getWorkerShift(_ workerId: String) -> String {
        switch workerId {
        case "1": return "9:00 AM - 3:00 PM"
        case "2": return "6:00 AM - 3:00 PM"
        case "4": return "6:00 AM - 5:00 PM"
        case "5": return "6:30 AM - 11:00 AM"
        case "6": return "7:00 AM - 4:00 PM"
        case "7": return "6:00 PM - 10:00 PM"
        case "8": return "Flexible"
        default: return "9:00 AM - 5:00 PM"
        }
    }
    
    // MARK: - Worker Building Assignments
    
    private func populateWorkerBuildingAssignments(_ assignments: [OperationalDataTaskAssignment]) async throws {
        let activeWorkers: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        
        print("🔗 Extracting assignments from \(assignments.count) operational tasks for ACTIVE WORKERS ONLY (GRDB)")
        
        var workerBuildingPairs: Set<String> = []
        var skippedAssignments = 0
        var kevinAssignmentCount = 0
        var kevinRubinAssignments = 0
        
        for assignment in assignments {
            guard !assignment.assignedWorker.isEmpty,
                  !assignment.building.isEmpty else {
                continue
            }
            
            guard let workerId = activeWorkers[assignment.assignedWorker] else {
                if assignment.assignedWorker.contains("Jose") || assignment.assignedWorker.contains("Santos") {
                    print("📝 Skipping Jose Santos assignment (no longer with company)")
                } else {
                    print("⚠️ Skipping unknown worker: '\(assignment.assignedWorker)'")
                }
                skippedAssignments += 1
                continue
            }
            
            if workerId == "4" {
                kevinAssignmentCount += 1
                if assignment.building.contains("Rubin") {
                    kevinRubinAssignments += 1
                }
            }
            
            do {
                let buildingId = try await mapBuildingNameToId(assignment.building)
                let pairKey = "\(workerId)-\(buildingId)"
                workerBuildingPairs.insert(pairKey)
                
            } catch {
                print("⚠️ Skipping assignment - unknown building: '\(assignment.building)' for \(assignment.assignedWorker)")
                skippedAssignments += 1
                continue
            }
        }
        
        print("🔗 Assignment Extraction Results (GRDB):")
        print("   Total pairs extracted: \(workerBuildingPairs.count)")
        print("   Assignments skipped: \(skippedAssignments)")
        print("   Kevin task assignments found: \(kevinAssignmentCount)")
        print("   ✅ PRESERVED: Kevin Rubin Museum assignments: \(kevinRubinAssignments)")
        
        var insertedCount = 0
        for pair in workerBuildingPairs {
            let components = pair.split(separator: "-")
            guard components.count == 2 else { continue }
            
            let workerId = String(components[0])
            let buildingId = String(components[1])
            
            let workerName = activeWorkers.first(where: { $0.value == workerId })?.key ?? "Unknown Worker"
            
            do {
                try await grdbManager.execute("""
                    INSERT OR IGNORE INTO worker_assignments 
                    (worker_id, building_id, worker_name, assignment_type, start_date, is_active) 
                    VALUES (?, ?, ?, 'regular', datetime('now'), 1)
                """, [workerId, buildingId, workerName])
                insertedCount += 1
                
                if workerId == "4" && buildingId == "14" {
                    print("✅ PRESERVED: Kevin assigned to Rubin Museum (building ID 14) with GRDB")
                }
            } catch {
                print("⚠️ Failed to insert assignment \(workerId)->\(buildingId) with GRDB: \(error)")
            }
        }
        
        print("✅ Real-world assignments populated with GRDB: \(insertedCount) active assignments")
        
        do {
            let kevinVerification = try await grdbManager.query("""
                SELECT building_id FROM worker_assignments 
                WHERE worker_id = '4' AND is_active = 1
            """)
            print("🎯 Kevin verification with GRDB: \(kevinVerification.count) buildings in database")
            
            let kevinRubinVerification = try await grdbManager.query("""
                SELECT building_id FROM worker_assignments 
                WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
            """)
            
            if kevinRubinVerification.count > 0 {
                print("✅ PRESERVED: Kevin's Rubin Museum assignment verified in GRDB database")
            } else {
                print("⚠️ PRESERVED: Kevin's Rubin Museum assignment NOT found in GRDB database")
            }
            
            if kevinVerification.count == 0 {
                print("🚨 EMERGENCY: Kevin still has 0 buildings after GRDB import!")
                try await validateWorkerAssignments()
            }
        } catch {
            print("❌ Could not verify Kevin assignments with GRDB: \(error)")
        }
        
        await logWorkerAssignmentSummary()
    }
    
    private func logWorkerAssignmentSummary() async {
        do {
            let results = try await grdbManager.query("""
                SELECT wa.worker_name, COUNT(wa.building_id) as building_count 
                FROM worker_assignments wa 
                WHERE wa.is_active = 1 
                GROUP BY wa.worker_id 
                ORDER BY building_count DESC
            """)
            
            print("📊 ACTIVE WORKER ASSIGNMENT SUMMARY (PRESERVED with GRDB):")
            for row in results {
                let name = row["worker_name"] as? String ?? "Unknown"
                let count = row["building_count"] as? Int64 ?? 0
                let emoji = getWorkerEmoji(name)
                let status = name.contains("Kevin") ? "✅ EXPANDED + Rubin Museum (building ID 14)" : ""
                print("   \(emoji) \(name): \(count) buildings \(status)")
            }
            
            let kevinCount = results.first(where: {
                ($0["worker_name"] as? String)?.contains("Kevin") == true
            })?["building_count"] as? Int64 ?? 0
            
            if kevinCount >= 8 {
                print("✅ Kevin's expanded duties verified with GRDB: \(kevinCount) buildings (including Rubin Museum)")
            } else {
                print("⚠️ WARNING: Kevin should have 8+ buildings, found \(kevinCount) with GRDB")
            }
            
            let rubinCheck = try await grdbManager.query("""
                SELECT COUNT(*) as count FROM worker_assignments 
                WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
            """)
            let rubinCount = rubinCheck.first?["count"] as? Int64 ?? 0
            if rubinCount > 0 {
                print("✅ PRESERVED: Kevin's Rubin Museum assignment verified with GRDB (building ID 14)")
            } else {
                print("❌ PRESERVED: Kevin's Rubin Museum assignment MISSING from GRDB")
            }
            
        } catch {
            print("⚠️ Could not generate assignment summary with GRDB: \(error)")
        }
    }
    
    private func getWorkerEmoji(_ workerName: String) -> String {
        switch workerName {
        case "Greg Hutson": return "🔧"
        case "Edwin Lema": return "🧹"
        case "Kevin Dutan": return "⚡"
        case "Mercedes Inamagua": return "✨"
        case "Luis Lopez": return "🔨"
        case "Angel Guirachocha": return "🗑️"
        case "Shawn Magloire": return "🎨"
        default: return "👷"
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateWorkerAssignments() async throws {
        do {
            let allWorkers = try await grdbManager.query("""
                SELECT id, name FROM workers WHERE isActive = 1
            """)
            
            print("🔍 Validating assignments for \(allWorkers.count) active workers with GRDB...")
            
            for worker in allWorkers {
                guard let workerId = worker["id"] as? String,
                      let workerName = worker["name"] as? String else { continue }
                
                let assignments = try await grdbManager.query("""
                    SELECT COUNT(*) as count FROM worker_assignments 
                    WHERE worker_id = ? AND is_active = 1
                """, [workerId])
                
                let count = assignments.first?["count"] as? Int64 ?? 0
                
                if count == 0 {
                    print("⚠️ Worker \(workerName) has no building assignments")
                    try await createDynamicAssignments(for: workerId, name: workerName)
                } else {
                    print("✅ Worker \(workerName) has \(count) building assignments with GRDB")
                }
            }
            
        } catch {
            print("❌ Assignment validation failed with GRDB: \(error)")
        }
    }
    
    private func createDynamicAssignments(for workerId: String, name: String) async throws {
        let workerTasks = realWorldTasks.filter { $0.assignedWorker == name }
        let buildings = Set(workerTasks.map { $0.building })
        
        print("🔧 Creating \(buildings.count) dynamic assignments for \(name) with GRDB")
        
        for building in buildings {
            let buildingResults = try await grdbManager.query("""
                SELECT id FROM buildings WHERE name LIKE ? OR name LIKE ?
            """, ["%\(building)%", "%\(building.components(separatedBy: " ").first ?? building)%"])
            
            if let buildingId = buildingResults.first?["id"] as? String {
                try await grdbManager.execute("""
                    INSERT OR REPLACE INTO worker_assignments 
                    (worker_id, building_id, worker_name, assignment_type, start_date, is_active) 
                    VALUES (?, ?, ?, 'dynamic_operational', datetime('now'), 1)
                """, [workerId, buildingId, name])
                
                print("  ✅ Assigned \(name) to building \(building) (ID: \(buildingId)) with GRDB")
            } else {
                print("  ⚠️ Could not find building ID for: \(building) in GRDB")
            }
        }
    }
    
    private func validateDataIntegrity() async throws {
        print("🔍 Validating data integrity with GRDB...")
        
        let orphanedTasks = try await grdbManager.query("""
            SELECT COUNT(*) as count FROM tasks t
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE b.id IS NULL
        """)
        
        let orphanCount = orphanedTasks.first?["count"] as? Int64 ?? 0
        if orphanCount > 0 {
            print("⚠️ Found \(orphanCount) orphaned tasks without valid buildings")
        }
        
        let inactiveAssignments = try await grdbManager.query("""
            SELECT COUNT(*) as count FROM worker_assignments wa
            LEFT JOIN workers w ON wa.worker_id = w.id
            WHERE w.isActive = 0 AND wa.is_active = 1
        """)
        
        let inactiveCount = inactiveAssignments.first?["count"] as? Int64 ?? 0
        if inactiveCount > 0 {
            print("⚠️ Found \(inactiveCount) assignments for inactive workers")
            
            try await grdbManager.execute("""
                UPDATE worker_assignments 
                SET is_active = 0, end_date = datetime('now')
                WHERE worker_id IN (SELECT id FROM workers WHERE isActive = 0)
                AND is_active = 1
            """)
            
            print("✅ Deactivated assignments for inactive workers with GRDB")
        }
        
        print("✅ Data integrity validation complete with GRDB")
    }
    
    // MARK: - Import Routines and DSNY
    
    private func importRoutinesAndDSNY() async throws -> (routines: Int, dsny: Int) {
        var routineCount = 0, dsnyCount = 0
        
        print("🔧 Creating routine scheduling tables with GRDB...")
        print("✅ PRESERVED: Including Kevin's Rubin Museum routing with building ID 14")
        
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS routine_schedules (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                rrule TEXT NOT NULL,
                worker_id TEXT NOT NULL,
                category TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 3600,
                weather_dependent INTEGER DEFAULT 0,
                priority_level TEXT DEFAULT 'medium',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)
        
        try await grdbManager.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_routine_unique 
            ON routine_schedules(building_id, worker_id, name)
        """)
        
        for routine in routineSchedules {
            let id = "routine_\(routine.buildingId)_\(routine.workerId)_\(routine.name.hashValue.magnitude)"
            let weatherDependent = routine.category == "Cleaning" ? 1 : 0
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO routine_schedules 
                (id, name, building_id, rrule, worker_id, category, weather_dependent)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [id, routine.name, routine.buildingId, routine.rrule, routine.workerId, routine.category, String(weatherDependent)])
            routineCount += 1
            
            if routine.workerId == "4" && routine.buildingId == "14" {
                print("✅ PRESERVED: Added Kevin's Rubin Museum routine with GRDB: \(routine.name) (building ID 14)")
            }
        }
        
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS dsny_schedules (
                id TEXT PRIMARY KEY,
                route_id TEXT NOT NULL,
                building_ids TEXT NOT NULL,
                collection_days TEXT NOT NULL,
                earliest_setout INTEGER DEFAULT 72000,
                latest_pickup INTEGER DEFAULT 32400,
                pickup_window_start INTEGER DEFAULT 21600,
                pickup_window_end INTEGER DEFAULT 43200,
                route_status TEXT DEFAULT 'active',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        try await grdbManager.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_dsny_unique 
            ON dsny_schedules(route_id)
        """)
        
        for dsny in dsnySchedules {
            let id = "dsny_\(dsny.routeId.hashValue.magnitude)"
            let buildingIdsJson = dsny.buildingIds.joined(separator: ",")
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO dsny_schedules 
                (id, route_id, building_ids, collection_days, earliest_setout, latest_pickup, pickup_window_start, pickup_window_end)
                VALUES (?, ?, ?, ?, 72000, 32400, 21600, 43200)
            """, [id, dsny.routeId, buildingIdsJson, dsny.collectionDays])
            dsnyCount += 1
            
            if dsny.buildingIds.contains("14") {
                print("✅ PRESERVED: Rubin Museum (building ID 14) included in DSNY route with GRDB: \(dsny.routeId)")
            }
        }
        
        print("✅ Imported with GRDB: \(routineCount) routine schedules, \(dsnyCount) DSNY routes")
        print("   🗑️ DSNY compliance: Set-out after 8:00 PM, pickup 6:00-12:00 AM")
        print("   🔄 Routine coverage: \(Set(routineSchedules.map { $0.workerId }).count) active workers")
        print("   ✅ PRESERVED: Kevin's Rubin Museum fully integrated with building ID 14 (GRDB)")
        
        return (routineCount, dsnyCount)
    }
    
    // MARK: - Validation and Summary Methods
    
    func validateOperationalData() -> [String] {
        var validationErrors: [String] = []
        
        for (index, task) in realWorldTasks.enumerated() {
            let validCategories = ["Cleaning", "Sanitation", "Maintenance", "Inspection", "Operations", "Repair"]
            if !validCategories.contains(task.category) {
                validationErrors.append("Row \(index + 1): Invalid category '\(task.category)'")
            }
            
            let validSkillLevels = ["Basic", "Intermediate", "Advanced"]
            if !validSkillLevels.contains(task.skillLevel) {
                validationErrors.append("Row \(index + 1): Invalid skill level '\(task.skillLevel)'")
            }
            
            let validRecurrences = ["Daily", "Weekly", "Bi-Weekly", "Bi-Monthly", "Monthly", "Quarterly", "Semiannual", "Annual", "On-Demand"]
            if !validRecurrences.contains(task.recurrence) {
                validationErrors.append("Row \(index + 1): Invalid recurrence '\(task.recurrence)'")
            }
            
            if let startHour = task.startHour, let endHour = task.endHour {
                if startHour < 0 || startHour > 23 {
                    validationErrors.append("Row \(index + 1): Invalid start hour \(startHour)")
                }
                if endHour < 0 || endHour > 23 {
                    validationErrors.append("Row \(index + 1): Invalid end hour \(endHour)")
                }
                if startHour >= endHour && endHour != startHour {
                    validationErrors.append("Row \(index + 1): Invalid time range \(startHour):00-\(endHour):00")
                }
            }
            
            if task.assignedWorker.contains("Jose") || task.assignedWorker.contains("Santos") {
                validationErrors.append("Row \(index + 1): Jose Santos is no longer active")
            }
        }
        
        return validationErrors
    }
    
    func getWorkerTaskSummary() -> [String: Int] {
        var summary: [String: Int] = [:]
        
        for task in realWorldTasks {
            summary[task.assignedWorker, default: 0] += 1
        }
        
        return summary
    }
    
    func getBuildingTaskSummary() -> [String: Int] {
        var summary: [String: Int] = [:]
        
        for task in realWorldTasks {
            summary[task.building, default: 0] += 1
        }
        
        return summary
    }
    
    func getTimeOfDayDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            guard let startHour = task.startHour else { continue }
            
            let timeSlot: String
            switch startHour {
            case 0..<6:
                timeSlot = "Night (12AM-6AM)"
            case 6..<12:
                timeSlot = "Morning (6AM-12PM)"
            case 12..<18:
                timeSlot = "Afternoon (12PM-6PM)"
            case 18..<24:
                timeSlot = "Evening (6PM-12AM)"
            default:
                timeSlot = "Unknown"
            }
            
            distribution[timeSlot, default: 0] += 1
        }
        
        return distribution
    }
    
    func getCategoryDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            distribution[task.category, default: 0] += 1
        }
        
        return distribution
    }
    
    func getRecurrenceDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            distribution[task.recurrence, default: 0] += 1
        }
        
        return distribution
    }
    
    func getSkillLevelDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        for task in realWorldTasks {
            distribution[task.skillLevel, default: 0] += 1
        }
        
        return distribution
    }
    
    func getBuildingCoverage() -> [String: [String]] {
        var coverage: [String: [String]] = [:]
        
        for task in realWorldTasks {
            if coverage[task.building] == nil {
                coverage[task.building] = []
            }
            if !coverage[task.building]!.contains(task.assignedWorker) {
                coverage[task.building]!.append(task.assignedWorker)
            }
        }
        
        return coverage
    }
    
    // MARK: - Legacy Support
    
    func getLegacyTaskAssignments() async -> [LegacyTaskAssignment] {
        return realWorldTasks.map { task in
            LegacyTaskAssignment(
                building: task.building,
                taskName: task.taskName,
                assignedWorker: task.assignedWorker,
                category: task.category,
                skillLevel: task.skillLevel,
                recurrence: task.recurrence,
                startHour: task.startHour,
                endHour: task.endHour,
                daysOfWeek: task.daysOfWeek
            )
        }
    }
    
    func getRealWorkerAssignments() async -> [String: [String]] {
        var assignments: [String: [String]] = [:]
        
        do {
            let workers = try await WorkerService.shared.getAllActiveWorkers()
            
            for worker in workers {
                let workerBuildings = try await BuildingService.shared.getBuildingsForWorker(worker.id)
                assignments[worker.id] = workerBuildings.map { $0.id }
            }
        } catch {
            print("⚠️ Error getting real worker assignments: \(error)")
        }
        
        return assignments
    }
    
    // MARK: - Task Retrieval for Workers
    
    func getTasksForWorker(_ workerId: String, date: Date) async -> [ContextualTask] {
        let workerTasks = realWorldTasks.filter { task in
            let workerNameToId = [
                "Greg Hutson": "1",
                "Edwin Lema": "2",
                "Kevin Dutan": "4",
                "Mercedes Inamagua": "5",
                "Luis Lopez": "6",
                "Angel Guirachocha": "7",
                "Shawn Magloire": "8"
            ]
            
            return workerNameToId[task.assignedWorker] == workerId
        }
        
        var contextualTasks: [ContextualTask] = []
        
        for operationalTask in workerTasks {
            let buildingName = operationalTask.building
            let buildingId = getBuildingIdFromName(operationalTask.building)
            
            let buildingCoordinate = NamedCoordinate(
                id: buildingId,
                name: buildingName,
                latitude: 0.0,
                longitude: 0.0
            )
            
            let workerProfile = WorkerProfile(
                id: workerId,
                name: operationalTask.assignedWorker,
                email: "",
                phoneNumber: "",
                role: .worker,
                skills: [],
                certifications: [],
                hireDate: Date(),
                isActive: true
            )
            
            let taskCategory: CoreTypes.TaskCategory?
            switch operationalTask.category.lowercased() {
            case "cleaning": taskCategory = .cleaning
            case "maintenance": taskCategory = .maintenance
            case "repair": taskCategory = .repair
            case "inspection": taskCategory = .inspection
            case "sanitation": taskCategory = .cleaning
            case "operations": taskCategory = .maintenance
            default: taskCategory = .maintenance
            }
            
            let taskUrgency: CoreTypes.TaskUrgency?
            switch operationalTask.skillLevel.lowercased() {
            case "basic": taskUrgency = .low
            case "intermediate": taskUrgency = .medium
            case "advanced": taskUrgency = .high
            default: taskUrgency = .medium
            }
            
            let task = ContextualTask(
                id: generateExternalId(for: operationalTask, index: 0),
                title: operationalTask.taskName,
                description: "Imported from current active worker schedule",
                completedAt: nil,
                dueDate: calculateDueDate(for: operationalTask.recurrence, from: date),
                category: taskCategory,
                urgency: taskUrgency,
                building: buildingCoordinate,
                worker: workerProfile,
                buildingId: buildingId,
                priority: taskUrgency
            )
            contextualTasks.append(task)
        }
        
        if workerId == "4" {
            let rubinTasks = contextualTasks.filter { task in
                if let building = task.building {
                    return building.name.contains("Rubin")
                }
                return false
            }
            print("✅ PRESERVED: Kevin has \(rubinTasks.count) Rubin Museum tasks with building ID 14 (GRDB)")
        }
        
        return contextualTasks
    }
    
    private func getBuildingIdFromName(_ buildingName: String) -> String {
        let buildingMap = [
            "131 Perry Street": "10",
            "68 Perry Street": "6",
            "135-139 West 17th Street": "3",
            "136 West 17th Street": "13",
            "138 West 17th Street": "5",
            "117 West 17th Street": "9",
            "112 West 18th Street": "7",
            "12 West 18th Street": "1",
            "Rubin Museum (142–148 W 17th)": "14",
            "29-31 East 20th Street": "2",
            "133 East 15th Street": "15",
            "178 Spring Street": "17",
            "104 Franklin Street": "4",
            "41 Elizabeth Street": "8",
            "36 Walker Street": "18",
            "Stuyvesant Cove Park": "16",
            "123 1st Avenue": "11",
            "115 7th Avenue": "19",
            "CyntientOps HQ": "20"
        ]
        
        return buildingMap[buildingName] ?? "1"
    }
    
    private func getBuildingNameFromId(_ buildingId: String) -> String {
        let reverseBuildingMap = [
            "1": "12 West 18th Street",
            "2": "29-31 East 20th Street",
            "3": "135-139 West 17th Street",
            "4": "104 Franklin Street",
            "5": "138 West 17th Street",
            "6": "68 Perry Street",
            "7": "112 West 18th Street",
            "8": "41 Elizabeth Street",
            "9": "117 West 17th Street",
            "10": "131 Perry Street",
            "11": "123 1st Avenue",
            "13": "136 West 17th Street",
            "14": "Rubin Museum (142–148 W 17th)",
            "15": "133 East 15th Street",
            "16": "Stuyvesant Cove Park",
            "17": "178 Spring Street",
            "18": "36 Walker Street",
            "19": "115 7th Avenue",
            "20": "CyntientOps HQ"
        ]
        
        return reverseBuildingMap[buildingId] ?? "Unknown Building"
    }
}

// MARK: - Error Types
enum OperationalError: LocalizedError {
    case noGRDBManager
    case buildingNotFound(String)
    case workerNotFound(String)
    case inactiveWorker(String)
    
    var errorDescription: String? {
        switch self {
        case .noGRDBManager:
            return "GRDBManager not available on OperationalDataManager"
        case .buildingNotFound(let name):
            return "Building not found: '\(name)'"
        case .workerNotFound(let name):
            return "Worker not found: '\(name)'"
        case .inactiveWorker(let name):
            return "Worker '\(name)' is no longer active"
        }
    }
}
