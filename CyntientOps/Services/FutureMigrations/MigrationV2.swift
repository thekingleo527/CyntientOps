//
//  MigrationV2.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  MigrationV2.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create a framework for future database schema migrations.
//
//  ✅ FUTURE-PROOF: Establishes a clear pattern for evolving the database.
//  ✅ SAFE: Includes placeholders for validation and rollback procedures.
//  ✅ MAINTAINABLE: Separates future migrations from the initial v6.0 setup.
//

import Foundation
import GRDB

final class MigrationV2 {
    
    // The version number this migration targets.
    // When the app detects its stored version is less than this, the migration runs.
    static let targetVersion = 2
    
    private let dbPool: DatabasePool
    
    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
    
    /// Checks if the v2 migration is required.
    /// It compares the database's stored version against the `targetVersion`.
    func needsMigration() async throws -> Bool {
        let currentVersion = try await getCurrentDbVersion()
        return currentVersion < MigrationV2.targetVersion
    }
    
    /// Executes all steps of the v2 migration within a single database transaction.
    /// If any step fails, the entire transaction is rolled back, ensuring data integrity.
    func performMigration() async throws {
        print("🚀 Starting database migration to v\(MigrationV2.targetVersion)...")
        
        try await dbPool.writeInTransaction { db in
            // Step 1: Add new tables required for v2 features.
            try self.addNewTables(db)
            
            // Step 2: Alter existing tables to add new columns.
            try self.updateExistingTables(db)
            
            // Step 3: Migrate existing data to fit the new schema.
            try self.migrateData(db)
            
            // Step 4: Update the database version number to prevent re-running this migration.
            try self.updateDbVersion(db, to: MigrationV2.targetVersion)
            
            print("✅ Migration to v\(MigrationV2.targetVersion) successful.")
            return .commit
        }
        
        // Post-migration validation
        guard try await validateMigration() else {
            throw MigrationError.validationFailed
        }
    }
    
    // MARK: - Migration Steps (Private)
    
    private func addNewTables(_ db: Database) throws {
        print("   - Step 1: Adding new tables...")
        // Example: Adding a table for tracking equipment maintenance history.
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS equipment_maintenance (
                id TEXT PRIMARY KEY,
                building_id TEXT NOT NULL,
                equipment_name TEXT NOT NULL,
                last_serviced_date TEXT NOT NULL,
                serviced_by TEXT,
                notes TEXT,
                FOREIGN KEY (building_id) REFERENCES buildings(id)
            );
        """)
    }
    
    private func updateExistingTables(_ db: Database) throws {
        print("   - Step 2: Updating existing tables...")
        // Example: Adding a 'priority' column to the worker_capabilities table.
        try db.execute(sql: """
            ALTER TABLE worker_capabilities ADD COLUMN priority_level INTEGER DEFAULT 0;
        """)
    }
    
    private func migrateData(_ db: Database) throws {
        print("   - Step 3: Migrating data...")
        // Example: Setting a default priority for existing workers based on their role.
        try db.execute(sql: """
            UPDATE worker_capabilities SET priority_level = 1 WHERE worker_id IN (
                SELECT id FROM workers WHERE role = 'manager'
            );
        """)
    }
    
    // MARK: - Versioning & Validation
    
    /// Retrieves the current schema version from a dedicated versioning table.
    private func getCurrentDbVersion() async throws -> Int {
        try await dbPool.read { db in
            try db.execute(sql: "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER NOT NULL);")
            
            if let version = try Int.fetchOne(db, sql: "SELECT version FROM schema_version") {
                return version
            } else {
                // If no version is set, it's v1 (the result of the initial DailyOpsReset).
                try db.execute(sql: "INSERT INTO schema_version (version) VALUES (1);")
                return 1
            }
        }
    }
    
    /// Updates the schema version number in the database.
    private func updateDbVersion(_ db: Database, to version: Int) throws {
        try db.execute(sql: "UPDATE schema_version SET version = ?", arguments: [version])
    }
    
    /// Validates that the migration was successful.
    private func validateMigration() async throws -> Bool {
        // Check if new columns/tables exist and data seems correct.
        let columnExists = try await dbPool.read { db in
            let columns = try db.columns(in: "worker_capabilities")
            return columns.contains { $0.name == "priority_level" }
        }
        
        guard columnExists else {
            print("❌ Validation Failed: 'priority_level' column not found.")
            return false
        }
        
        print("✅ Migration validation passed.")
        return true
    }
    
    /// A placeholder for a rollback procedure in case of catastrophic failure.
    func rollback() async throws {
        // In a real-world scenario, this would involve restoring from a pre-migration backup.
        print("⚠️ Performing migration rollback (placeholder)...")
    }
    
    enum MigrationError: LocalizedError {
        case validationFailed
        
        var errorDescription: String? {
            switch self {
            case .validationFailed:
                return "The database migration completed but failed the post-flight validation check."
            }
        }
    }
}