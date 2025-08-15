//
//  CreateProductionDatabase.swift
//  CyntientOps
//
//  PRODUCTION DATABASE CREATOR - Creates complete working database
//  Run this once to have 100% working app with real data
//

import Foundation
import GRDB
import CryptoKit
import Security

@MainActor
final class ProductionDatabaseCreator {
    
    private let grdbManager = GRDBManager.shared
    
    func createCompleteWorkingDatabase() async throws {
        print("🚀 Creating complete production database...")
        
        // Step 1: Create all tables
        try await createAllTables()
        
        // Step 2: Seed buildings
        try await seedBuildings()
        
        // Step 3: Seed users with authentication
        try await seedUsers()
        
        // Step 4: Seed clients and relationships
        try await seedClients()
        
        // Step 5: Seed worker assignments
        try await seedWorkerAssignments()
        
        // Step 6: Seed routines and tasks
        try await seedRoutinesAndTasks()
        
        // Step 7: Seed compliance data
        try await seedComplianceData()
        
        print("✅ Complete production database created successfully!")
    }
    
    // MARK: - Create Tables
    
    private func createAllTables() async throws {
        print("📋 Creating all database tables...")
        
        // Users/Workers table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS workers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT NOT NULL,
                isActive INTEGER DEFAULT 1,
                created_at TEXT,
                updated_at TEXT
            )
        """)
        
        // Buildings table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS buildings (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                address TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                imageAssetName TEXT,
                numberOfUnits INTEGER,
                yearBuilt INTEGER,
                squareFootage REAL,
                bin_number TEXT,
                bbl TEXT,
                created_at TEXT,
                updated_at TEXT
            )
        """)
        
        // Clients table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                short_name TEXT,
                contact_email TEXT,
                contact_phone TEXT,
                address TEXT,
                is_active INTEGER DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        """)
        
        // Client-Building relationships
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS client_buildings (
                client_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                is_primary INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                PRIMARY KEY (client_id, building_id)
            )
        """)
        
        // Worker assignments
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                is_active INTEGER DEFAULT 1,
                assigned_date TEXT DEFAULT CURRENT_TIMESTAMP,
                is_primary INTEGER DEFAULT 0,
                UNIQUE(worker_id, building_id)
            )
        """)
        
        // Routines table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS routine_templates (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                building_id TEXT NOT NULL,
                worker_id TEXT NOT NULL,
                estimated_duration INTEGER,
                requires_photo INTEGER DEFAULT 0,
                priority INTEGER DEFAULT 1,
                frequency TEXT DEFAULT 'daily',
                created_at TEXT,
                updated_at TEXT
            )
        """)
        
        // Tasks table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                building_id TEXT,
                worker_id TEXT,
                due_date TEXT,
                completed_at TEXT,
                is_completed INTEGER DEFAULT 0,
                priority INTEGER DEFAULT 1,
                created_at TEXT,
                updated_at TEXT
            )
        """)
        
        // Compliance table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS compliance_records (
                id TEXT PRIMARY KEY,
                building_id TEXT NOT NULL,
                violation_type TEXT NOT NULL,
                description TEXT NOT NULL,
                severity TEXT NOT NULL,
                status TEXT NOT NULL,
                issued_date TEXT,
                due_date TEXT,
                resolved_date TEXT,
                created_at TEXT
            )
        """)
        
        print("✅ All tables created")
    }
    
    // MARK: - Seed Buildings
    
    private func seedBuildings() async throws {
        print("🏢 Seeding buildings...")
        
        let buildings = [
            ("1", "12 West 18th Street", "12 West 18th Street, New York, NY 10011", 40.7387, -73.9941, nil, 45, 1920, 12500.0),
            ("3", "135-139 West 17th Street", "135-139 West 17th Street, New York, NY 10011", 40.7406, -73.9974, nil, 32, 1925, 8900.0),
            ("4", "104 Franklin Street", "104 Franklin Street, New York, NY 10013", 40.7197, -74.0079, nil, 28, 1910, 7200.0),
            ("5", "138 West 17th Street", "138 West 17th Street, New York, NY 10011", 40.7407, -73.9976, nil, 38, 1918, 9800.0),
            ("6", "68 Perry Street", "68 Perry Street, New York, NY 10014", 40.7351, -74.0063, nil, 22, 1895, 6100.0),
            ("7", "112 West 18th Street", "112 West 18th Street, New York, NY 10011", 40.7388, -73.9957, nil, 41, 1922, 11200.0),
            ("8", "41 Elizabeth Street", "41 Elizabeth Street, New York, NY 10013", 40.7204, -73.9956, nil, 35, 1908, 8500.0),
            ("9", "117 West 17th Street", "117 West 17th Street, New York, NY 10011", 40.7407, -73.9967, nil, 29, 1920, 7900.0),
            ("10", "131 Perry Street", "131 Perry Street, New York, NY 10014", 40.7350, -74.0081, nil, 26, 1900, 6800.0),
            ("11", "123 1st Avenue", "123 1st Avenue, New York, NY 10003", 40.7304, -73.9867, nil, 33, 1915, 8200.0),
            ("13", "136 West 17th Street", "136 West 17th Street, New York, NY 10011", 40.7407, -73.9975, nil, 37, 1919, 9500.0),
            ("14", "Rubin Museum (142-148 West 17th Street)", "142-148 West 17th Street, New York, NY 10011", 40.7408, -73.9978, "rubin_museum", 0, 1929, 28000.0),
            ("15", "133 East 15th Street", "133 East 15th Street, New York, NY 10003", 40.7340, -73.9862, nil, 44, 1925, 12000.0),
            ("16", "Stuyvesant Cove Park", "Stuyvesant Cove Park, New York, NY 10009", 40.7281, -73.9738, "stuyvesant_park", 0, 2005, 0.0),
            ("17", "178 Spring Street", "178 Spring Street, New York, NY 10012", 40.7248, -73.9971, nil, 24, 1912, 6500.0),
            ("18", "36 Walker Street", "36 Walker Street, New York, NY 10013", 40.7186, -74.0048, nil, 31, 1908, 8100.0),
            ("19", "115 7th Avenue", "115 7th Avenue, New York, NY 10011", 40.7405, -73.9987, nil, 39, 1924, 10200.0),
            ("20", "CyntientOps HQ", "Manhattan, NY", 40.7831, -73.9712, nil, 0, 2020, 5000.0),
            ("21", "148 Chambers Street", "148 Chambers Street, New York, NY 10007", 40.7155, -74.0086, nil, 42, 1923, 11800.0)
        ]
        
        let currentTime = Date().ISO8601Format()
        
        for building in buildings {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO buildings (
                    id, name, address, latitude, longitude, imageAssetName, 
                    numberOfUnits, yearBuilt, squareFootage, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                building.0, building.1, building.2, building.3, building.4,
                building.5, building.6, building.7, building.8, currentTime, currentTime
            ])
        }
        
        print("✅ Seeded \(buildings.count) buildings")
    }
    
    // MARK: - Seed Users
    
    private func seedUsers() async throws {
        print("👥 Seeding users with authentication...")
        
        let users = [
            ("1", "Greg Hutson", "greg.hutson@cyntientops.com", "GregWorker2025!", "worker"),
            ("2", "Edwin Lema", "edwin.lema@cyntientops.com", "EdwinPark2025!", "worker"),
            ("3", "David JM Realty", "David@jmrealty.org", "DavidClient2025!", "client"),
            ("4", "Kevin Dutan", "kevin.dutan@cyntientops.com", "KevinRubin2025!", "worker"),
            ("5", "Mercedes Inamagua", "mercedes.inamagua@cyntientops.com", "MercedesGlass2025!", "worker"),
            ("6", "Luis Lopez", "luis.lopez@cyntientops.com", "LuisElizabeth2025!", "worker"),
            ("7", "Angel Guiracocha", "angel.guiracocha@cyntientops.com", "AngelBuilding2025!", "worker"),
            ("8", "Shawn Magloire", "shawn.magloire@cyntientops.com", "ShawnHVAC2025!", "manager"),
            ("101", "David Johnson", "david@jmrealty.com", "DavidJM2025!", "client"),
            ("102", "Sarah Johnson", "sarah@jmrealty.com", "SarahJM2025!", "client"),
            ("103", "David Weber", "david@weberfarhat.com", "WeberFarhat2025!", "client"),
            ("104", "Maria Rodriguez", "maria@solarone.org", "SolarOne2025!", "client"),
            ("105", "Robert Chen", "robert@grandelizabeth.com", "GrandEliz2025!", "client"),
            ("106", "Alex Thompson", "alex@citadelrealty.com", "Citadel2025!", "client"),
            ("107", "Jennifer Lee", "jennifer@corbelproperty.com", "Corbel2025!", "client")
        ]
        
        let currentTime = Date().ISO8601Format()
        
        for user in users {
            // Hash password with salt
            let hashedPassword = try await hashPassword(user.3, for: user.2)
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO workers (
                    id, name, email, password, role, isActive, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, 1, ?, ?)
            """, [user.0, user.1, user.2, hashedPassword, user.4, currentTime, currentTime])
        }
        
        print("✅ Seeded \(users.count) users with authentication")
    }
    
    // MARK: - Seed Clients
    
    private func seedClients() async throws {
        print("🏢 Seeding clients and building relationships...")
        
        let clients = [
            ("JMR", "JM Realty", "JMR", "David@jmrealty.org", "+1 (212) 555-0200", 
             "350 Fifth Avenue, New York, NY 10118", ["3", "5", "6", "7", "9", "10", "11", "14", "21"]),
            ("WFR", "Weber Farhat Realty", "WFR", "david@weberfarhat.com", "+1 (212) 555-0201",
             "136 West 17th Street, New York, NY 10011", ["13"]),
            ("SOL", "Solar One", "SOL", "maria@solarone.org", "+1 (212) 555-0202",
             "Stuyvesant Cove Park, New York, NY 10009", ["16"]),
            ("GEL", "Grand Elizabeth LLC", "GEL", "robert@grandelizabeth.com", "+1 (212) 555-0203",
             "41 Elizabeth Street, New York, NY 10013", ["8"]),
            ("CIT", "Citadel Realty", "CIT", "alex@citadelrealty.com", "+1 (212) 555-0204",
             "104 Franklin Street, New York, NY 10013", ["4", "18"]),
            ("COR", "Corbel Property", "COR", "jennifer@corbelproperty.com", "+1 (212) 555-0205",
             "133 East 15th Street, New York, NY 10003", ["15"])
        ]
        
        let currentTime = Date().ISO8601Format()
        
        // Insert clients
        for client in clients {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO clients (
                    id, name, short_name, contact_email, contact_phone,
                    address, is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
            """, [client.0, client.1, client.2, client.3, client.4, client.5, currentTime, currentTime])
        }
        
        // Clear and create client-building relationships
        try await grdbManager.execute("DELETE FROM client_buildings")
        
        for client in clients {
            for (index, buildingId) in client.6.enumerated() {
                try await grdbManager.execute("""
                    INSERT INTO client_buildings (
                        client_id, building_id, is_primary, created_at
                    ) VALUES (?, ?, ?, ?)
                """, [client.0, buildingId, index == 0 ? 1 : 0, currentTime])
            }
        }
        
        print("✅ Seeded clients and building relationships")
    }
    
    // MARK: - Seed Worker Assignments
    
    private func seedWorkerAssignments() async throws {
        print("👷 Seeding worker assignments...")
        
        let assignments = [
            // Greg Hutson (Worker ID 1)
            ("1", "1", "Greg Hutson", true),   // 12 West 18th Street PRIMARY
            ("1", "3", "Greg Hutson", false),  // 135-139 West 17th Street
            ("1", "7", "Greg Hutson", false),  // 112 West 18th Street
            
            // Edwin Lema (Worker ID 2) - Stuyvesant Park PRIMARY
            ("2", "16", "Edwin Lema", true),   // Stuyvesant Cove Park PRIMARY
            ("2", "15", "Edwin Lema", false),  // 133 East 15th Street
            ("2", "13", "Edwin Lema", false),  // 136 West 17th Street
            ("2", "5", "Edwin Lema", false),   // 138 West 17th Street
            ("2", "9", "Edwin Lema", false),   // 117 West 17th Street
            ("2", "10", "Edwin Lema", false),  // 131 Perry Street
            ("2", "11", "Edwin Lema", false),  // 123 1st Avenue
            ("2", "1", "Edwin Lema", false),   // 12 West 18th Street
            
            // Kevin Dutan (Worker ID 4) - Rubin Museum PRIMARY
            ("4", "14", "Kevin Dutan", true),  // Rubin Museum PRIMARY
            ("4", "5", "Kevin Dutan", false),  // 138 West 17th Street
            ("4", "6", "Kevin Dutan", false),  // 68 Perry Street
            ("4", "7", "Kevin Dutan", false),  // 112 West 18th Street
            ("4", "9", "Kevin Dutan", false),  // 117 West 17th Street
            ("4", "17", "Kevin Dutan", false), // 178 Spring Street
            ("4", "19", "Kevin Dutan", false), // 115 7th Avenue
            ("4", "21", "Kevin Dutan", false), // 148 Chambers Street
            
            // Mercedes Inamagua (Worker ID 5) - Evening shift
            ("5", "20", "Mercedes Inamagua", true),  // CyntientOps HQ PRIMARY
            ("5", "14", "Mercedes Inamagua", false), // Rubin Museum - roof drain
            ("5", "7", "Mercedes Inamagua", false),  // 112 West 18th Street
            ("5", "15", "Mercedes Inamagua", false), // 133 East 15th Street
            ("5", "17", "Mercedes Inamagua", false), // 178 Spring Street
            
            // Luis Lopez (Worker ID 6) - Elizabeth Street PRIMARY
            ("6", "8", "Luis Lopez", true),    // 41 Elizabeth Street PRIMARY
            ("6", "4", "Luis Lopez", false),   // 104 Franklin Street
            ("6", "18", "Luis Lopez", false),  // 36 Walker Street
            
            // Angel Guiracocha (Worker ID 7)
            ("7", "4", "Angel Guiracocha", true),  // 104 Franklin Street PRIMARY
            ("7", "7", "Angel Guiracocha", false), // 112 West 18th Street
            ("7", "19", "Angel Guiracocha", false), // 115 7th Avenue
            ("7", "18", "Angel Guiracocha", false), // 36 Walker Street
            
            // Shawn Magloire (Worker ID 8) - Admin oversight
            ("8", "1", "Shawn Magloire", false),  // 12 West 18th Street
            ("8", "14", "Shawn Magloire", false), // Rubin Museum
            ("8", "16", "Shawn Magloire", false), // Stuyvesant Cove Park
            ("8", "7", "Shawn Magloire", false)   // 112 West 18th Street
        ]
        
        try await grdbManager.execute("DELETE FROM worker_assignments")
        
        for assignment in assignments {
            try await grdbManager.execute("""
                INSERT INTO worker_assignments (
                    worker_id, building_id, worker_name, is_active, is_primary, assigned_date
                ) VALUES (?, ?, ?, 1, ?, ?)
            """, [
                assignment.0, assignment.1, assignment.2,
                assignment.3 ? 1 : 0, Date().ISO8601Format()
            ])
        }
        
        print("✅ Seeded \(assignments.count) worker assignments")
    }
    
    // MARK: - Seed Routines and Tasks
    
    private func seedRoutinesAndTasks() async throws {
        print("📋 Seeding routines and tasks...")
        
        // Sample routines based on real Franco Management operations
        let routines = [
            // Greg Hutson - 12 West 18th Street
            ("greg-18th-lobby", "Lobby Cleaning & Maintenance", "Daily lobby cleaning, mail sorting, and entrance maintenance", "maintenance", "1", "1", 45, true, 1, "daily"),
            ("greg-18th-trash", "DSNY Bag Removal", "Remove DSNY bags from sidewalk and clean surrounding area", "sanitation", "1", "1", 20, true, 2, "daily"),
            ("greg-18th-sweep", "Sidewalk Sweep", "Sweep and maintain sidewalk cleanliness", "sanitation", "1", "1", 15, false, 1, "daily"),
            
            // Kevin Dutan - Rubin Museum
            ("kevin-rubin-museum", "Museum Facility Maintenance", "Complete facility maintenance for Rubin Museum including HVAC, lighting, and visitor areas", "maintenance", "14", "4", 180, true, 1, "daily"),
            ("kevin-rubin-hvac", "HVAC System Check", "Monitor and maintain museum HVAC systems for art preservation", "maintenance", "14", "4", 30, false, 1, "daily"),
            ("kevin-rubin-lighting", "Gallery Lighting Maintenance", "Check and adjust gallery lighting systems", "maintenance", "14", "4", 45, false, 2, "daily"),
            
            // Edwin Lema - Stuyvesant Cove Park
            ("edwin-park-grounds", "Park Grounds Maintenance", "Maintain park grounds, pathways, and green spaces", "maintenance", "16", "2", 120, true, 1, "daily"),
            ("edwin-park-waste", "Waste Management", "Empty trash receptacles and maintain cleanliness", "sanitation", "16", "2", 30, true, 2, "daily"),
            ("edwin-park-safety", "Safety Inspection", "Daily safety inspection of park facilities and equipment", "inspection", "16", "2", 20, true, 1, "daily"),
            
            // Luis Lopez - Elizabeth Street
            ("luis-elizabeth-building", "Building Maintenance - Elizabeth", "Complete building maintenance including common areas and utilities", "maintenance", "8", "6", 90, true, 1, "daily"),
            ("luis-elizabeth-sanitation", "Sanitation Services", "Building sanitation and waste management", "sanitation", "8", "6", 25, true, 2, "daily"),
            
            // Mercedes - Evening Operations
            ("mercedes-evening-hq", "Evening Operations - HQ", "Evening shift operations and facility maintenance", "maintenance", "20", "5", 240, false, 1, "daily"),
            ("mercedes-evening-security", "Security Check", "Evening security rounds and facility check", "security", "20", "5", 30, false, 1, "daily"),
            
            // Angel - Franklin Street
            ("angel-franklin-building", "Franklin Street Maintenance", "Complete building maintenance and tenant services", "maintenance", "4", "7", 75, true, 1, "daily"),
            ("angel-franklin-dsny", "DSNY Compliance", "Ensure DSNY compliance and waste management", "sanitation", "4", "7", 20, true, 2, "daily")
        ]
        
        let currentTime = Date().ISO8601Format()
        
        // Insert routine templates
        for routine in routines {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO routine_templates (
                    id, title, description, category, building_id, worker_id,
                    estimated_duration, requires_photo, priority, frequency, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                routine.0, routine.1, routine.2, routine.3, routine.4, routine.5,
                routine.6, routine.7 ? 1 : 0, routine.8, routine.9, currentTime, currentTime
            ])
        }
        
        // Create today's tasks from routines
        for routine in routines {
            let taskId = "task-\(routine.0)-\(Date().timeIntervalSince1970)"
            let dueDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())?.ISO8601Format()
            
            try await grdbManager.execute("""
                INSERT INTO tasks (
                    id, title, description, category, building_id, worker_id,
                    due_date, is_completed, priority, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
            """, [
                taskId, routine.1, routine.2, routine.3, routine.4, routine.5,
                dueDate, routine.8, currentTime, currentTime
            ])
        }
        
        print("✅ Seeded \(routines.count) routines and tasks")
    }
    
    // MARK: - Seed Compliance Data
    
    private func seedComplianceData() async throws {
        print("⚖️ Seeding compliance data...")
        
        let complianceRecords = [
            // Sample HPD violations
            ("hpd-001-jmr", "14", "HPD", "Minor maintenance issue in common area", "low", "resolved", "2024-01-15", "2024-02-15", "2024-02-10"),
            ("hpd-002-jmr", "7", "HPD", "Heating system maintenance required", "medium", "in_progress", "2024-02-01", "2024-03-01", nil),
            
            // DOB inspections
            ("dob-001-citadel", "4", "DOB", "Annual building inspection", "low", "scheduled", "2024-03-01", "2024-04-01", nil),
            ("dob-002-weber", "13", "DOB", "Fire safety system check", "medium", "pending", "2024-02-15", "2024-03-15", nil),
            
            // DSNY compliance
            ("dsny-001-grand", "8", "DSNY", "Proper waste disposal verification", "low", "compliant", "2024-02-01", nil, "2024-02-01"),
            ("dsny-002-solar", "16", "DSNY", "Park waste management compliance", "low", "compliant", "2024-01-20", nil, "2024-01-20")
        ]
        
        let currentTime = Date().ISO8601Format()
        
        for record in complianceRecords {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO compliance_records (
                    id, building_id, violation_type, description, severity,
                    status, issued_date, due_date, resolved_date, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                record.0, record.1, record.2, record.3, record.4,
                record.5, record.6, record.7, record.8, currentTime
            ])
        }
        
        print("✅ Seeded \(complianceRecords.count) compliance records")
    }
    
    // MARK: - Helper Methods
    
    private func hashPassword(_ password: String, for email: String) async throws -> String {
        // Generate salt
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        
        // Store salt in keychain
        let keychainService = "com.cyntientops.auth"
        let saltKey = "\(keychainService).salt.\(email)"
        try storeInKeychain(salt, for: saltKey)
        
        // Hash password with salt
        let passwordData = Data(password.utf8)
        let saltedPassword = salt + passwordData
        let hash = SHA256.hash(data: saltedPassword)
        
        return Data(hash).base64EncodedString()
    }
    
    private func storeInKeychain(_ data: Data, for key: String) throws {
        let keychainService = "com.cyntientops.auth"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }
}