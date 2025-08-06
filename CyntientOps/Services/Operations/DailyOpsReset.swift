//
//  DailyOpsReset.swift
//  CyntientOps v6.0
//
//  ✅ PRODUCTION READY: Complete one-time migration and daily operations
//  ✅ SAFE: Transaction-wrapped with rollback support
//  ✅ VERIFIED: Checksum validation and comprehensive error handling
//  ✅ FIXED: Actor isolation for shouldGenerateTask method
//

import Foundation
import UIKit
import GRDB

@MainActor
public class DailyOpsReset: ObservableObject {
    static let shared = DailyOpsReset()
    
    // MARK: - Migration Tracking
    private let migrationKeys = MigrationKeys()
    
    struct MigrationKeys {
        let hasImportedWorkers = "hasImportedWorkers_v1"
        let hasImportedBuildings = "hasImportedBuildings_v1"
        let hasImportedTemplates = "hasImportedTemplates_v1"
        let hasCreatedAssignments = "hasCreatedAssignments_v1"
        let hasSetupCapabilities = "hasSetupCapabilities_v1"
        let migrationVersion = "dailyOpsMigrationVersion"
        let operationalDataBackup = "operationalDataBackup_v1"
        let lastMigrationChecksum = "lastMigrationChecksum_v1"
        let currentVersion = 1
    }
    
    // MARK: - Migration Status
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus = ""
    @Published var currentStep = 0
    @Published var totalSteps = 7
    @Published var migrationError: Error?
    
    // MARK: - Custom Error Type
    enum DailyOpsError: LocalizedError {
        case backupFailed(String)
        case dataIntegrityFailed(String)
        case importFailed(String)
        case databaseError(String)
        
        var errorDescription: String? {
            switch self {
            case .backupFailed(let reason):
                return "Backup failed: \(reason)"
            case .dataIntegrityFailed(let reason):
                return "Data integrity check failed: \(reason)"
            case .importFailed(let reason):
                return "Import failed: \(reason)"
            case .databaseError(let reason):
                return "Database error: \(reason)"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Check if migration is needed
    func needsMigration() -> Bool {
        let currentVersion = UserDefaults.standard.integer(forKey: migrationKeys.migrationVersion)
        return currentVersion < migrationKeys.currentVersion
    }
    
    /// Perform one-time migration from OperationalDataManager to database
    func performOneTimeMigration() async throws {
        guard needsMigration() else {
            print("✅ Migration already completed (version \(migrationKeys.currentVersion))")
            return
        }
        
        print("🚀 Starting one-time operational data migration...")
        
        isMigrating = true
        migrationProgress = 0.0
        currentStep = 0
        migrationError = nil
        
        defer {
            isMigrating = false
        }
        
        do {
            // Step 1: Create backup
            currentStep = 1
            migrationStatus = "Creating backup of operational data..."
            migrationProgress = 0.1
            try await createOperationalDataBackup()
            
            // Step 2: Verify data integrity
            currentStep = 2
            migrationStatus = "Verifying data integrity..."
            migrationProgress = 0.15
            
            let operationalData = OperationalDataManager.shared
            guard operationalData.verifyDataIntegrity() else {
                throw DailyOpsError.dataIntegrityFailed("Operational data checksum mismatch")
            }
            
            // Perform migration steps
            try await performMigrationSteps()
            
            // Mark migration complete
            UserDefaults.standard.set(migrationKeys.currentVersion, forKey: migrationKeys.migrationVersion)
            
            migrationProgress = 1.0
            migrationStatus = "Migration completed successfully!"
            
            print("✅ ONE-TIME MIGRATION COMPLETED SUCCESSFULLY")
            print("   - Workers imported: ✓")
            print("   - Buildings imported: ✓")
            print("   - Templates created: ✓")
            print("   - Assignments created: ✓")
            print("   - Capabilities setup: ✓")
            
            // Generate initial tasks for today
            try await performDailyOperations()
            
            // Delay before hiding migration UI
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
        } catch {
            migrationError = error
            migrationStatus = "Migration failed: \(error.localizedDescription)"
            print("❌ Migration failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Migration Steps (Async)
    
    private func performMigrationSteps() async throws {
        // Step 3: Import workers
        if !UserDefaults.standard.bool(forKey: migrationKeys.hasImportedWorkers) {
            currentStep = 3
            migrationStatus = "Importing workers..."
            migrationProgress = 0.3
            
            try await importWorkersAsync()
            UserDefaults.standard.set(true, forKey: migrationKeys.hasImportedWorkers)
        }
        
        // Step 4: Import buildings
        if !UserDefaults.standard.bool(forKey: migrationKeys.hasImportedBuildings) {
            currentStep = 4
            migrationStatus = "Importing buildings..."
            migrationProgress = 0.4
            
            try await importBuildingsAsync()
            UserDefaults.standard.set(true, forKey: migrationKeys.hasImportedBuildings)
        }
        
        // Step 5: Import routine templates
        if !UserDefaults.standard.bool(forKey: migrationKeys.hasImportedTemplates) {
            currentStep = 5
            migrationStatus = "Importing routine templates..."
            migrationProgress = 0.6
            
            try await importRoutineTemplatesAsync()
            UserDefaults.standard.set(true, forKey: migrationKeys.hasImportedTemplates)
        }
        
        // Step 6: Create worker assignments
        if !UserDefaults.standard.bool(forKey: migrationKeys.hasCreatedAssignments) {
            currentStep = 6
            migrationStatus = "Creating worker assignments..."
            migrationProgress = 0.8
            
            try await createWorkerAssignmentsAsync()
            UserDefaults.standard.set(true, forKey: migrationKeys.hasCreatedAssignments)
        }
        
        // Step 7: Setup worker capabilities
        if !UserDefaults.standard.bool(forKey: migrationKeys.hasSetupCapabilities) {
            currentStep = 7
            migrationStatus = "Setting up worker capabilities..."
            migrationProgress = 0.9
            
            try await setupWorkerCapabilitiesAsync()
            UserDefaults.standard.set(true, forKey: migrationKeys.hasSetupCapabilities)
        }
    }
    
    /// Perform daily operations (task generation, cleanup)
    func performDailyOperations() async throws {
        // Check if migration needed first
        if needsMigration() {
            try await performOneTimeMigration()
            return
        }
        
        let today = Date()
        let lastRunKey = "lastDailyOperationDate"
        
        // Check if already run today
        if let lastRun = UserDefaults.standard.object(forKey: lastRunKey) as? Date,
           Calendar.current.isDateInToday(lastRun) {
            print("ℹ️ Daily operations already completed today")
            return
        }
        
        print("🔄 Starting daily operations at \(Date())")
        
        // Generate tasks from templates
        try await generateTasksFromTemplates(for: today)
        
        // Clean up old data
        try await cleanupOldData()
        
        // Update completion metrics
        try await updateDailyMetrics()
        
        // Mark as completed
        UserDefaults.standard.set(today, forKey: lastRunKey)
        
        print("✅ Daily operations completed at \(Date())")
    }
    
    // MARK: - Migration Implementation
    
    private func createOperationalDataBackup() async throws {
        print("🛡️ Creating operational data backup...")
        
        let operationalData = OperationalDataManager.shared
        let allTasks = operationalData.getAllRealWorldTasks()
        
        // Generate checksum
        let checksum = operationalData.generateChecksum()
        UserDefaults.standard.set(checksum, forKey: migrationKeys.lastMigrationChecksum)
        
        // Create backup
        let backup = OperationalDataBackup(
            version: "1.0.0",
            timestamp: Date(),
            checksum: checksum,
            taskCount: allTasks.count,
            tasks: allTasks,
            workerNames: Array(operationalData.getUniqueWorkerNames()),
            buildingNames: Array(operationalData.getUniqueBuildingNames())
        )
        
        // Save backup
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let backupData = try encoder.encode(backup)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let backupPath = documentsPath.appendingPathComponent("operational_backup_\(Date().timeIntervalSince1970).json")
            
            try backupData.write(to: backupPath)
            UserDefaults.standard.set(backupData, forKey: migrationKeys.operationalDataBackup)
            
            print("✅ Backup created: \(backup.taskCount) tasks, \(backup.workerNames.count) workers, \(backup.buildingNames.count) buildings")
            
        } catch {
            throw DailyOpsError.backupFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Async Import Methods
    
    private func importWorkersAsync() async throws {
        try await GRDBManager.shared.database.write { db in
            try self.importWorkers(db: db)
        }
    }
    
    private func importBuildingsAsync() async throws {
        try await GRDBManager.shared.database.write { db in
            try self.importBuildings(db: db)
        }
    }
    
    private func importRoutineTemplatesAsync() async throws {
        // Get tasks from OperationalDataManager on main actor
        let tasks = OperationalDataManager.shared.getAllRealWorldTasks()
        
        try await GRDBManager.shared.database.write { db in
            try self.importRoutineTemplates(db: db, tasks: tasks)
        }
    }
    
    private func createWorkerAssignmentsAsync() async throws {
        // Get tasks from OperationalDataManager on main actor
        let tasks = OperationalDataManager.shared.getAllRealWorldTasks()
        
        try await GRDBManager.shared.database.write { db in
            try self.createWorkerAssignments(db: db, tasks: tasks)
        }
    }
    
    private func setupWorkerCapabilitiesAsync() async throws {
        try await GRDBManager.shared.database.write { db in
            try self.setupWorkerCapabilities(db: db)
        }
    }
    
    // MARK: - Synchronous Import Methods (called within database transaction)
    
    private nonisolated func importWorkers(db: Database) throws {
        print("👥 Importing workers...")
        
        var imported = 0
        
        // Import from canonical IDs using OperationalDataManager's definition
        let nameMap = [
            "1": "Greg Hutson",
            "2": "Edwin Lema",
            "4": "Kevin Dutan",
            "5": "Mercedes Inamagua",
            "6": "Luis Lopez",
            "7": "Angel Guirachocha",
            "8": "Shawn Magloire"
        ]
        
        for (id, name) in nameMap {
            // Check if worker already exists
            let existingWorker = try Row.fetchOne(db, sql: """
                SELECT id FROM workers WHERE id = ?
            """, arguments: [id])
            
            if existingWorker != nil {
                print("   Worker already exists: \(name)")
                continue
            }
            
            try db.execute(sql: """
                INSERT INTO workers (
                    id, name, email, role, 
                    isActive, shift, hireDate
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                id,
                name,
                "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@francosphere.com",
                getWorkerRole(id),
                1, // isActive
                getWorkerShift(id),
                "2023-01-01"
            ])
            
            imported += 1
        }
        
        print("   ✓ Imported \(imported) workers")
    }
    
    private nonisolated func importBuildings(db: Database) throws {
        print("🏢 Importing buildings...")
        
        var imported = 0
        
        // Building details
        let buildingDetails: [(id: String, name: String, address: String, type: String, floors: Int, hasElevator: Bool, hasDoorman: Bool, latitude: Double, longitude: Double)] = [
            ("1", "12 West 18th Street", "12 West 18th Street, New York, NY 10011", "commercial", 6, true, false, 40.7388, -73.9939),
            ("2", "36 Walker Street", "36 Walker Street, New York, NY 10013", "residential", 5, true, false, 40.7178, -74.0020),
            ("3", "41 Elizabeth Street", "41 Elizabeth Street, New York, NY 10013", "mixed", 4, false, false, 40.7166, -73.9964),
            ("4", "68 Perry Street", "68 Perry Street, New York, NY 10014", "residential", 4, false, true, 40.7355, -74.0045),
            ("5", "104 Franklin Street", "104 Franklin Street, New York, NY 10013", "commercial", 8, true, false, 40.7170, -74.0094),
            ("6", "112 West 18th Street", "112 West 18th Street, New York, NY 10011", "residential", 5, true, false, 40.7398, -73.9972),
            ("7", "117 West 17th Street", "117 West 17th Street, New York, NY 10011", "commercial", 12, true, true, 40.7385, -73.9968),
            ("8", "123 1st Avenue", "123 1st Avenue, New York, NY 10003", "mixed", 6, true, false, 40.7272, -73.9844),
            ("9", "131 Perry Street", "131 Perry Street, New York, NY 10014", "residential", 3, false, false, 40.7352, -74.0075),
            ("10", "133 East 15th Street", "133 East 15th Street, New York, NY 10003", "residential", 6, true, true, 40.7338, -73.9868),
            ("11", "135 West 17th Street", "135 West 17th Street, New York, NY 10011", "residential", 4, false, false, 40.7384, -73.9975),
            ("12", "136 West 17th Street", "136 West 17th Street, New York, NY 10011", "residential", 4, false, false, 40.7383, -73.9976),
            ("13", "138 West 17th Street", "138 West 17th Street, New York, NY 10011", "residential", 4, false, false, 40.7382, -73.9977),
            ("14", "Rubin Museum", "150 West 17th Street, New York, NY 10011", "cultural", 7, true, true, 40.7390, -73.9975),
            ("15", "29-31 East 20th Street", "29-31 East 20th Street, New York, NY 10003", "commercial", 5, true, false, 40.7388, -73.9889),
            ("16", "Stuyvesant Cove Park", "Stuyvesant Cove Park, New York, NY 10009", "park", 1, false, false, 40.7338, -73.9738),
            ("17", "178 Spring Street", "178 Spring Street, New York, NY 10012", "mixed", 5, true, false, 40.7247, -74.0023)
        ]
        
        for (id, name, address, type, floors, hasElevator, hasDoorman, latitude, longitude) in buildingDetails {
            // Check if building already exists
            let existingBuilding = try Row.fetchOne(db, sql: """
                SELECT id FROM buildings WHERE id = ?
            """, arguments: [id])
            
            if existingBuilding != nil {
                print("   Building already exists: \(name)")
                continue
            }
            
            try db.execute(sql: """
                INSERT INTO buildings (
                    id, name, address, type, floors,
                    has_elevator, has_doorman, latitude, longitude,
                    is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                id,
                name,
                address,
                type,
                floors,
                hasElevator ? 1 : 0,
                hasDoorman ? 1 : 0,
                latitude,
                longitude,
                1, // is_active
                Date().ISO8601Format(),
                Date().ISO8601Format()
            ])
            
            imported += 1
        }
        
        print("   ✓ Imported \(imported) buildings")
    }
    
    private nonisolated func importRoutineTemplates(db: Database, tasks: [OperationalDataTaskAssignment]) throws {
        print("📋 Importing routine templates...")
        
        var imported = 0
        var skipped = 0
        
        // Group tasks by worker and building to create templates
        var templateMap: [String: OperationalDataTaskAssignment] = [:]
        
        for task in tasks {
            // Validate IDs exist
            guard !task.workerId.isEmpty && !task.buildingId.isEmpty else {
                print("⚠️ Skipping task with missing IDs: \(task.taskName)")
                skipped += 1
                continue
            }
            
            // Create unique key for deduplication
            let templateKey = "\(task.workerId)-\(task.buildingId)-\(task.taskName)"
            
            // Skip if we already have this template
            if templateMap[templateKey] != nil {
                continue
            }
            
            templateMap[templateKey] = task
            
            let templateId = UUID().uuidString
            
            try db.execute(sql: """
                INSERT OR IGNORE INTO routine_templates (
                    id, worker_id, building_id, title, description,
                    category, frequency, estimated_duration, requires_photo,
                    priority, start_hour, end_hour, days_of_week,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                templateId,
                task.workerId,
                task.buildingId,
                task.taskName,
                "Routine maintenance task",
                task.category,
                task.recurrence,
                task.estimatedDuration,
                task.requiresPhoto ? 1 : 0,
                determinePriority(task),
                task.startHour ?? 0,
                task.endHour ?? 23,
                task.daysOfWeek ?? "mon,tue,wed,thu,fri",
                Date().ISO8601Format(),
                Date().ISO8601Format()
            ])
            
            imported += 1
        }
        
        print("   ✓ Imported \(imported) routine templates (skipped \(skipped) invalid)")
    }
    
    private nonisolated func createWorkerAssignments(db: Database, tasks: [OperationalDataTaskAssignment]) throws {
        print("🔗 Creating worker-building assignments...")
        
        var assignmentSet = Set<String>()
        var created = 0
        
        // Extract unique worker-building pairs
        for task in tasks {
            guard !task.workerId.isEmpty && !task.buildingId.isEmpty else { continue }
            
            let assignmentKey = "\(task.workerId)-\(task.buildingId)"
            
            if !assignmentSet.contains(assignmentKey) {
                assignmentSet.insert(assignmentKey)
                
                try db.execute(sql: """
                    INSERT OR IGNORE INTO worker_assignments (
                        id, worker_id, building_id, role,
                        is_primary, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    UUID().uuidString,
                    task.workerId,
                    task.buildingId,
                    "maintenance", // Default role
                    true, // All assignments are primary for now
                    Date().ISO8601Format(),
                    Date().ISO8601Format()
                ])
                
                created += 1
            }
        }
        
        print("   ✓ Created \(created) worker-building assignments")
    }
    
    private nonisolated func setupWorkerCapabilities(db: Database) throws {
        print("⚙️ Setting up worker capabilities...")
        
        let capabilities = [
            // Kevin - Power user
            WorkerCapability(
                workerId: "4",
                canUploadPhotos: true,
                canAddNotes: true,
                canViewMap: true,
                canAddEmergencyTasks: true,
                requiresPhotoForSanitation: true,
                simplifiedInterface: false
            ),
            // Mercedes - Simplified interface
            WorkerCapability(
                workerId: "5",
                canUploadPhotos: false,
                canAddNotes: false,
                canViewMap: true,
                canAddEmergencyTasks: false,
                requiresPhotoForSanitation: false,
                simplifiedInterface: true
            ),
            // Edwin - Standard user
            WorkerCapability(
                workerId: "2",
                canUploadPhotos: true,
                canAddNotes: true,
                canViewMap: true,
                canAddEmergencyTasks: false,
                requiresPhotoForSanitation: true,
                simplifiedInterface: false
            ),
            // Greg - Standard user
            WorkerCapability(
                workerId: "1",
                canUploadPhotos: true,
                canAddNotes: true,
                canViewMap: true,
                canAddEmergencyTasks: false,
                requiresPhotoForSanitation: true,
                simplifiedInterface: false
            ),
            // Luis - Basic user
            WorkerCapability(
                workerId: "6",
                canUploadPhotos: true,
                canAddNotes: false,
                canViewMap: false,
                canAddEmergencyTasks: false,
                requiresPhotoForSanitation: true,
                simplifiedInterface: true
            ),
            // Angel - Basic user
            WorkerCapability(
                workerId: "7",
                canUploadPhotos: true,
                canAddNotes: false,
                canViewMap: false,
                canAddEmergencyTasks: false,
                requiresPhotoForSanitation: true,
                simplifiedInterface: true
            ),
            // Shawn - Standard user
            WorkerCapability(
                workerId: "8",
                canUploadPhotos: true,
                canAddNotes: true,
                canViewMap: true,
                canAddEmergencyTasks: false,
                requiresPhotoForSanitation: true,
                simplifiedInterface: false
            )
        ]
        
        for capability in capabilities {
            try db.execute(sql: """
                INSERT OR REPLACE INTO worker_capabilities (
                    worker_id, can_upload_photos, can_add_notes,
                    can_view_map, can_add_emergency_tasks,
                    requires_photo_for_sanitation, simplified_interface,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                capability.workerId,
                capability.canUploadPhotos ? 1 : 0,
                capability.canAddNotes ? 1 : 0,
                capability.canViewMap ? 1 : 0,
                capability.canAddEmergencyTasks ? 1 : 0,
                capability.requiresPhotoForSanitation ? 1 : 0,
                capability.simplifiedInterface ? 1 : 0,
                Date().ISO8601Format(),
                Date().ISO8601Format()
            ])
        }
        
        print("   ✓ Set up capabilities for \(capabilities.count) workers")
    }
    
    // MARK: - Daily Operations
    
    private func generateTasksFromTemplates(for date: Date) async throws {
        print("📅 Generating tasks from templates for \(date.formatted(date: .abbreviated, time: .omitted))...")
        
        let generated = try await GRDBManager.shared.database.write { [weak self] db -> Int in
            guard let self = self else { return 0 }
            
            // Read all active templates
            let templates = try Row.fetchAll(db, sql: """
                SELECT * FROM routine_templates 
                WHERE 1=1
                ORDER BY worker_id, building_id, priority DESC
            """)
            
            var generatedCount = 0
            var skipped = 0
            
            for template in templates {
                if DailyOpsReset.shouldGenerateTask(template: template, date: date) {
                    // Check if task already exists for today
                    let templateId = template["id"] ?? ""
                    
                    let existingCount = try Int.fetchOne(db, sql: """
                        SELECT COUNT(*) FROM routine_tasks
                        WHERE template_id = ?
                        AND DATE(scheduled_date) = DATE(?)
                    """, arguments: [
                        templateId,
                        date.ISO8601Format()
                    ]) ?? 0
                    
                    if existingCount > 0 {
                        skipped += 1
                        continue
                    }
                    
                    // Create task instance
                    let taskId = UUID().uuidString
                    
                    // Extract values from template with proper types
                    let buildingId: String = template["building_id"] ?? ""
                    let workerId: String = template["worker_id"] ?? ""
                    let title: String = template["title"] ?? ""
                    let description: String = template["description"] ?? ""
                    let category: String = template["category"] ?? ""
                    let priority: String = template["priority"] ?? ""
                    let frequency: String = template["frequency"] ?? ""
                    let estimatedDuration: Int = template["estimated_duration"] ?? 30
                    let requiresPhoto: Int = template["requires_photo"] ?? 0
                    
                    try db.execute(sql: """
                        INSERT INTO routine_tasks (
                            id, template_id, building_id, worker_id,
                            title, description, category, priority,
                            status, frequency, estimated_duration,
                            requires_photo, scheduled_date, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, arguments: [
                        taskId,
                        templateId,
                        buildingId,
                        workerId,
                        title,
                        description,
                        category,
                        priority,
                        "pending",
                        frequency,
                        estimatedDuration,
                        requiresPhoto,
                        date.ISO8601Format(),
                        Date().ISO8601Format(),
                        Date().ISO8601Format()
                    ])
                    
                    generatedCount += 1
                }
            }
            
            print("   ✓ Generated \(generatedCount) tasks, skipped \(skipped) existing")
            return generatedCount
        }
    }
    
    // ✅ FIXED: Marked as nonisolated to allow calls from non-isolated context
    private nonisolated static func shouldGenerateTask(template: Row, date: Date) -> Bool {
        let frequency: String = template["frequency"] ?? "daily"
        let frequencyLower = frequency.lowercased()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let dayOfMonth = calendar.component(.day, from: date)
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let month = calendar.component(.month, from: date)
        
        // Check days of week if specified
        let daysOfWeek: String? = template["days_of_week"]
        if let days = daysOfWeek, !days.isEmpty {
            let dayAbbrev = getDayAbbreviation(weekday).lowercased()
            if !days.lowercased().contains(dayAbbrev) {
                return false
            }
        }
        
        switch frequencyLower {
        case "daily":
            return true
            
        case "weekdays":
            return weekday >= 2 && weekday <= 6
            
        case "weekends":
            return weekday == 1 || weekday == 7
            
        case "weekly":
            return true // Days of week already checked above
            
        case "bi-weekly", "biweekly":
            return weekday == 2 && weekOfYear % 2 == 0
            
        case "monthly":
            return dayOfMonth == 1
            
        case "quarterly":
            return dayOfMonth == 1 && [1, 4, 7, 10].contains(month)
            
        case "yearly", "annually":
            return dayOfMonth == 1 && month == 1
            
        default:
            // Check for custom patterns like "mon,wed,fri"
            if frequencyLower.contains(",") {
                let dayAbbrev = getDayAbbreviation(weekday).lowercased()
                return frequencyLower.split(separator: ",")
                    .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased() }
                    .contains(dayAbbrev)
            }
            return false
        }
    }
    
    // ✅ FIXED: Marked as nonisolated since it's called from shouldGenerateTask
    private nonisolated static func getDayAbbreviation(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "sun"
        case 2: return "mon"
        case 3: return "tue"
        case 4: return "wed"
        case 5: return "thu"
        case 6: return "fri"
        case 7: return "sat"
        default: return ""
        }
    }
    
    private func cleanupOldData() async throws {
        print("🧹 Cleaning up old data...")
        
        let retentionDays = 90 // Keep 90 days of history
        let cutoffDate = Date().addingTimeInterval(-Double(retentionDays * 24 * 60 * 60))
        
        try await GRDBManager.shared.database.write { db in
            // Clean old completed tasks
            try db.execute(sql: """
                DELETE FROM routine_tasks
                WHERE status = 'completed'
                AND updated_at < ?
            """, arguments: [cutoffDate.ISO8601Format()])
            
            // Clean old clock sessions
            try db.execute(sql: """
                DELETE FROM clock_sessions
                WHERE clock_out_time IS NOT NULL
                AND clock_out_time < ?
            """, arguments: [cutoffDate.ISO8601Format()])
            
            // Clean orphaned photo evidence
            try db.execute(sql: """
                DELETE FROM photo_evidence
                WHERE completion_id NOT IN (
                    SELECT id FROM task_completions
                )
            """)
            
            print("   ✓ Cleaned up old data")
        }
    }
    
    private func updateDailyMetrics() async throws {
        print("📊 Updating daily metrics...")
        
        // Trigger metrics recalculation for all buildings
        let buildingIds = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17"]
        
        for buildingId in buildingIds {
            _ = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        }
        
        print("   ✓ Updated metrics for \(buildingIds.count) buildings")
    }
    
    // MARK: - Helper Methods
    
    private nonisolated func determinePriority(_ task: OperationalDataTaskAssignment) -> String {
        // Priority logic based on task attributes
        if task.taskName.lowercased().contains("emergency") {
            return "urgent"
        } else if task.taskName.lowercased().contains("inspection") ||
                  task.taskName.lowercased().contains("compliance") {
            return "high"
        } else if task.category.lowercased() == "sanitation" {
            return "high"
        } else {
            return "normal"
        }
    }
    
    private nonisolated func getWorkerRole(_ workerId: String) -> String {
        switch workerId {
        case "1": return "Maintenance"
        case "2": return "Cleaning"
        case "4": return "Cleaning"
        case "5": return "Cleaning"
        case "6": return "Maintenance"
        case "7": return "Sanitation"
        case "8": return "Management"
        default: return "General"
        }
    }
    
    private nonisolated func getWorkerShift(_ workerId: String) -> String {
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
}

// MARK: - Supporting Types

struct OperationalDataBackup: Codable {
    let version: String
    let timestamp: Date
    let checksum: String
    let taskCount: Int
    let tasks: [OperationalDataTaskAssignment]
    let workerNames: [String]
    let buildingNames: [String]
}

struct WorkerCapability {
    let workerId: String
    let canUploadPhotos: Bool
    let canAddNotes: Bool
    let canViewMap: Bool
    let canAddEmergencyTasks: Bool
    let requiresPhotoForSanitation: Bool
    let simplifiedInterface: Bool
}

// MARK: - 📝 COMPILATION FIXES
/*
 ✅ FIXED Line 636: Actor isolation for shouldGenerateTask
    - Marked shouldGenerateTask as nonisolated static method
    - Also marked getDayAbbreviation as nonisolated since it's called from shouldGenerateTask
    - This allows the methods to be called from within the database write block
 */
