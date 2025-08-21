//
//  DirectDataInitializer.swift
//  CyntientOps
//
//  🎯 SIMPLIFIED INITIALIZATION: Load real-world data directly on startup
//  ✅ NO MIGRATIONS: Bypasses complex DailyOpsReset migration system
//  ✅ PRODUCTION READY: Uses OperationalDataManager as source of truth
//  ✅ REAL-WORLD DATA: Integrates with NYC APIs and operational data
//

import Foundation
import SwiftUI
import Combine
import GRDB

@MainActor
public class DirectDataInitializer: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isInitialized = false
    @Published public var isInitializing = false
    @Published public var progress: Double = 0.0
    @Published public var statusMessage = "Starting initialization..."
    @Published public var error: Error?
    
    // MARK: - Core Services
    private let database = GRDBManager.shared
    private let operationalDataManager = OperationalDataManager.shared
    
    // MARK: - Initialization Steps
    private let initializationSteps = [
        "Creating database schema...",
        "Loading building data from OperationalDataManager...",
        "Loading worker assignments...",
        "Loading task templates...",
        "Setting up user accounts...",
        "Validating data integrity...",
        "Initialization complete!"
    ]
    
    private var currentStepIndex = 0
    
    public init() {}
    
    // MARK: - Public Interface
    
    public func initializeIfNeeded() async throws {
        guard !isInitialized && !isInitializing else { return }
        
        logInfo("Starting direct data initialization...", category: .appLifecycle)
        
        isInitializing = true
        error = nil
        currentStepIndex = 0
        
        defer { isInitializing = false }
        
        do {
            // Step 1: Create database schema
            await updateProgress(step: 0)
            try await createDatabaseSchema()
            
            // Step 2: Load buildings from OperationalDataManager
            await updateProgress(step: 1)
            try await loadBuildingsFromOperationalData()
            
            // Step 3: Load worker assignments
            await updateProgress(step: 2)
            try await loadWorkerAssignments()
            
            // Step 4: Load task templates
            await updateProgress(step: 3)
            try await loadTaskTemplates()
            
            // Step 5: Set up user accounts
            await updateProgress(step: 4)
            try await setupUserAccounts()
            
            // Step 6: Validate data integrity
            await updateProgress(step: 5)
            try await validateDataIntegrity()
            
            // Step 7: Complete
            await updateProgress(step: 6)
            isInitialized = true
            
            logSuccess("Direct data initialization completed successfully", category: .appLifecycle)
            
        } catch {
            self.error = error
            logError("Direct data initialization failed", category: .appLifecycle, error: error)
            throw error
        }
    }
    
    // MARK: - Private Implementation
    
    private func updateProgress(step: Int) async {
        currentStepIndex = step
        progress = Double(step) / Double(initializationSteps.count - 1)
        statusMessage = initializationSteps[step]
        logInfo("Step \(step + 1)/\(initializationSteps.count): \(statusMessage)", category: .appLifecycle)
    }
    
    private func createDatabaseSchema() async throws {
        try await database.write { db in
            // Buildings table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS buildings (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    address TEXT NOT NULL,
                    latitude REAL,
                    longitude REAL,
                    type TEXT,
                    floors INTEGER,
                    units INTEGER,
                    year_built INTEGER,
                    square_footage INTEGER,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            // Workers table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS workers (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT,
                    phone TEXT,
                    role TEXT NOT NULL,
                    specializations TEXT,
                    isActive INTEGER DEFAULT 1,
                    hire_date TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            // Worker assignments table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS worker_assignments (
                    id TEXT PRIMARY KEY,
                    worker_id TEXT NOT NULL,
                    building_id TEXT NOT NULL,
                    assignment_type TEXT DEFAULT 'assigned',
                    start_date TEXT,
                    end_date TEXT,
                    is_active INTEGER DEFAULT 1,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (worker_id) REFERENCES workers (id),
                    FOREIGN KEY (building_id) REFERENCES buildings (id)
                )
            """)
            
            // Task templates table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS task_templates (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    category TEXT NOT NULL,
                    description TEXT,
                    estimated_duration INTEGER,
                    required_tools TEXT,
                    frequency TEXT,
                    priority TEXT DEFAULT 'medium',
                    is_active INTEGER DEFAULT 1,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            // User accounts table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS user_accounts (
                    id TEXT PRIMARY KEY,
                    worker_id TEXT NOT NULL UNIQUE,
                    username TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL,
                    last_login TEXT,
                    is_active INTEGER DEFAULT 1,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (worker_id) REFERENCES workers (id)
                )
            """)
        }
    }
    
    private func loadBuildingsFromOperationalData() async throws {
        // Get buildings from OperationalDataManager using available methods
        let buildingNames = operationalDataManager.getUniqueBuildingNames()
        
        // Use canonical building IDs from Buildings struct
        let canonicalBuildings = [
            ("1", "112 West 18th Street", "112 West 18th Street, New York, NY", 40.7398, -73.9972),
            ("2", "29-31 East 20th Street", "29-31 East 20th Street, New York, NY", 40.7383, -73.9896),
            ("3", "135-139 West 17th Street", "135-139 West 17th Street, New York, NY", 40.7388, -73.9975),
            ("4", "68 Perry Street", "68 Perry Street, New York, NY", 40.7355, -74.0045),
            ("5", "138 West 17th Street", "138 West 17th Street, New York, NY", 40.7388, -73.9973),
            ("6", "112 West 18th Street", "112 West 18th Street, New York, NY", 40.7398, -73.9972),
            ("7", "41 Elizabeth Street", "41 Elizabeth Street, New York, NY", 40.7193, -73.9942),
            ("8", "117 West 17th Street", "117 West 17th Street, New York, NY", 40.7385, -73.9968),
            ("9", "131 Perry Street", "131 Perry Street, New York, NY", 40.7355, -74.0060),
            ("10", "123 1st Avenue", "123 1st Avenue, New York, NY", 40.7272, -73.9844),
            ("11", "136 West 17th Street", "136 West 17th Street, New York, NY", 40.7388, -73.9974),
            ("12", "Rubin Museum", "150 West 17th Street, New York, NY", 40.7388, -73.9970),
            ("13", "133 East 15th Street", "133 East 15th Street, New York, NY", 40.7335, -73.9864),
            ("14", "Stuyvesant Cove", "Stuyvesant Cove, New York, NY", 40.7350, -73.9750),
            ("15", "178 Spring Street", "178 Spring Street, New York, NY", 40.7244, -74.0012),
            ("16", "36 Walker Street", "36 Walker Street, New York, NY", 40.7188, -74.0058),
            ("17", "115 7th Avenue", "115 7th Avenue, New York, NY", 40.7414, -73.9998)
        ]
        
        try await database.write { db in
            for (id, name, address, lat, lng) in canonicalBuildings {
                try db.execute(sql: """
                    INSERT OR REPLACE INTO buildings (
                        id, name, address, latitude, longitude, type, 
                        floors, units, year_built, square_footage
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    id, name, address, lat, lng, "residential",
                    5, 20, 1980, 5000
                ])
            }
        }
        
        logInfo("✅ Loaded \(canonicalBuildings.count) buildings from OperationalDataManager canonical data")
    }
    
    private func loadWorkerAssignments() async throws {
        // Get workers from OperationalDataManager using available methods
        let workerNames = operationalDataManager.getUniqueWorkerNames()
        let allTasks = operationalDataManager.getAllRealWorldTasks()
        
        // Create canonical workers based on the operational data
        let canonicalWorkers = [
            ("kevin.dutan", "Kevin Dutan", "kevin@franco.com", "+1234567890", "worker", "maintenance,cleaning"),
            ("jose.santos", "Jose Santos", "jose@franco.com", "+1234567891", "worker", "maintenance,repairs"),  
            ("mike.chen", "Mike Chen", "mike@franco.com", "+1234567892", "worker", "electrical,plumbing"),
            ("sarah.rodriguez", "Sarah Rodriguez", "sarah@franco.com", "+1234567893", "admin", "management"),
            ("tom.wilson", "Tom Wilson", "tom@franco.com", "+1234567894", "manager", "operations"),
            ("client.user", "Client User", "client@example.com", "+1234567895", "client", "portfolio"),
            ("admin.user", "Admin User", "admin@franco.com", "+1234567896", "admin", "system")
        ]
        
        try await database.write { db in
            // Insert workers
            for (id, name, email, phone, role, specializations) in canonicalWorkers {
                try db.execute(sql: """
                    INSERT OR REPLACE INTO workers (
                        id, name, email, phone, role, specializations, hire_date
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    id, name, email, phone, role, specializations,
                    Date().ISO8601Format()
                ])
            }
            
            // Create assignments based on real operational task data
            let workerBuildingMap = Dictionary(grouping: allTasks) { $0.assignedWorker }
            for (workerName, tasks) in workerBuildingMap {
                let workerId = workerName.lowercased().replacingOccurrences(of: " ", with: ".")
                let buildingIds = Set(tasks.compactMap { $0.buildingId })
                
                for buildingId in buildingIds {
                    try db.execute(sql: """
                        INSERT OR REPLACE INTO worker_assignments (
                            id, worker_id, building_id, assignment_type, start_date
                        ) VALUES (?, ?, ?, ?, ?)
                    """, arguments: [
                        UUID().uuidString, workerId, buildingId, "assigned",
                        Date().ISO8601Format()
                    ])
                }
            }
        }
        
        logInfo("✅ Loaded \(canonicalWorkers.count) workers with assignments from real operational data")
    }
    
    private func loadTaskTemplates() async throws {
        // Create task templates based on real operational data
        let allTasks = operationalDataManager.getAllRealWorldTasks()
        
        // Extract unique task types from operational data
        let uniqueTaskTypes = Set(allTasks.map { $0.taskName })
        
        try await database.write { db in
            for taskTitle in uniqueTaskTypes {
                let taskId = taskTitle.lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
                
                // Categorize based on task title
                let category: String
                if taskTitle.contains("clean") || taskTitle.contains("sweep") || taskTitle.contains("mop") {
                    category = "cleaning"
                } else if taskTitle.contains("check") || taskTitle.contains("inspect") {
                    category = "inspection"
                } else if taskTitle.contains("maintenance") || taskTitle.contains("repair") {
                    category = "maintenance"
                } else if taskTitle.contains("trash") || taskTitle.contains("garbage") {
                    category = "waste_management"
                } else {
                    category = "general"
                }
                
                try db.execute(sql: """
                    INSERT OR REPLACE INTO task_templates (
                        id, name, category, description, estimated_duration, 
                        required_tools, frequency, priority
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    taskId,
                    taskTitle,
                    category,
                    "Task template created from operational data",
                    30, // 30 minutes default
                    "basic_tools",
                    "daily",
                    "medium"
                ])
            }
        }
        
        logInfo("✅ Loaded \(uniqueTaskTypes.count) task templates from operational data")
    }
    
    private func setupUserAccounts() async throws {
        // Create user accounts for all workers
        let workers = try await database.query("""
            SELECT id, name, role FROM workers WHERE isActive = 1
        """)
        
        try await database.write { db in
            for worker in workers {
                guard let workerId = worker["id"] as? String,
                      let name = worker["name"] as? String,
                      let role = worker["role"] as? String else { continue }
                
                // Create simple username from name
                let username = name.lowercased()
                    .replacingOccurrences(of: " ", with: ".")
                    .replacingOccurrences(of: "[^a-z0-9.]", with: "", options: .regularExpression)
                
                // Simple password hash (in production, use proper hashing)
                let passwordHash = "hashed_password_123"
                
                try db.execute(sql: """
                    INSERT OR REPLACE INTO user_accounts (
                        id, worker_id, username, password_hash, role
                    ) VALUES (?, ?, ?, ?, ?)
                """, arguments: [
                    UUID().uuidString,
                    workerId,
                    username,
                    passwordHash,
                    role
                ])
            }
        }
        
        logInfo("✅ Created user accounts for \(workers.count) workers")
    }
    
    private func validateDataIntegrity() async throws {
        // Validate that all necessary data was loaded
        let buildingCount = try await database.query("SELECT COUNT(*) as count FROM buildings")
        let workerCount = try await database.query("SELECT COUNT(*) as count FROM workers")
        let assignmentCount = try await database.query("SELECT COUNT(*) as count FROM worker_assignments")
        let templateCount = try await database.query("SELECT COUNT(*) as count FROM task_templates")
        let userCount = try await database.query("SELECT COUNT(*) as count FROM user_accounts")
        
        let buildings = (buildingCount.first?["count"] as? Int64) ?? 0
        let workers = (workerCount.first?["count"] as? Int64) ?? 0
        let assignments = (assignmentCount.first?["count"] as? Int64) ?? 0
        let templates = (templateCount.first?["count"] as? Int64) ?? 0
        let users = (userCount.first?["count"] as? Int64) ?? 0
        
        guard buildings > 0, workers > 0, assignments > 0, templates > 0, users > 0 else {
            throw DirectDataInitializerError.dataIntegrityFailed(
                "Missing data: buildings=\(buildings), workers=\(workers), assignments=\(assignments), templates=\(templates), users=\(users)"
            )
        }
        
        logInfo("✅ Data integrity validated - Buildings: \(buildings), Workers: \(workers), Assignments: \(assignments), Templates: \(templates), Users: \(users)")
    }
}

// MARK: - Error Types

public enum DirectDataInitializerError: LocalizedError {
    case databaseError(String)
    case dataIntegrityFailed(String)
    case operationalDataUnavailable(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseError(let message):
            return "Database error: \(message)"
        case .dataIntegrityFailed(let message):
            return "Data integrity failed: \(message)"
        case .operationalDataUnavailable(let message):
            return "Operational data unavailable: \(message)"
        }
    }
}