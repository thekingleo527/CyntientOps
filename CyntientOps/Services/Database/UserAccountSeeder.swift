//
//  UserAccountSeeder.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  UserAccountSeeder.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0A.1: Seed User Accounts with SHA256 Hashing
//  Creates all production user accounts with secure passwords
//

import Foundation
import CryptoKit
import GRDB
import Security

@MainActor
public final class UserAccountSeeder {
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    private let authManager = NewAuthManager.shared
    
    // MARK: - User Account Data
    private struct UserAccount {
        let id: String
        let name: String
        let email: String
        let password: String // Will be hashed
        let role: String
        let isActive: Bool
        let capabilities: WorkerCapabilities?
    }
    
    private struct WorkerCapabilities {
        let simplifiedInterface: Bool
        let language: String
        let languageToggle: Bool // Can switch languages (default: false)
        let requiresPhotoForSanitation: Bool
        let canUploadPhotos: Bool // Can optionally upload photos (default: true)
        let canAddEmergencyTasks: Bool
        let eveningModeUI: Bool
        
        // Default initializer
        init(
            simplifiedInterface: Bool = false,
            language: String = "en",
            languageToggle: Bool = false,
            requiresPhotoForSanitation: Bool = true,
            canUploadPhotos: Bool = true,
            canAddEmergencyTasks: Bool = false,
            eveningModeUI: Bool = false
        ) {
            self.simplifiedInterface = simplifiedInterface
            self.language = language
            self.languageToggle = languageToggle
            self.requiresPhotoForSanitation = requiresPhotoForSanitation
            self.canUploadPhotos = canUploadPhotos
            self.canAddEmergencyTasks = canAddEmergencyTasks
            self.eveningModeUI = eveningModeUI
        }
    }
    
    // MARK: - Production User Accounts
    private let productionAccounts: [UserAccount] = [
        // System Admin
        UserAccount(
            id: "0",
            name: "System Administrator",
            email: "admin@cyntientops.com",
            password: "CyntientAdmin2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Workers
        UserAccount(
            id: "1",
            name: "Greg Hutson", 
            email: "greg.hutson@cyntientops.com",
            password: "GregWorker2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false, // Full dashboard
                language: "en",
                languageToggle: false,
                requiresPhotoForSanitation: true,
                canUploadPhotos: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "8",
            name: "Shawn Magloire",
            email: "shawn.magloire@cyntientops.com",
            password: "ShawnHVAC2025!",
            role: "manager",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false, // Full management dashboard
                language: "en", // English interface
                languageToggle: false,
                requiresPhotoForSanitation: false, // Manager doesn't need photo requirements
                canUploadPhotos: true,
                canAddEmergencyTasks: true, // Can create emergency tasks
                eveningModeUI: false
            )
        ),
        
        // Workers
        UserAccount(
            id: "2",
            name: "Edwin Lema",
            email: "edwin.lema@cyntientops.com",
            password: "EdwinPark2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false, // Full dashboard - standard worker
                language: "en", // English primary with Spanish toggle
                languageToggle: true, // Can switch to Spanish
                requiresPhotoForSanitation: true, // Required for maintenance tasks
                canUploadPhotos: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "4",
            name: "Kevin Dutan",
            email: "kevin.dutan@cyntientops.com",
            password: "KevinRubin2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false, // Full dashboard - high task volume (38 tasks)
                language: "es", // Spanish primary with English toggle
                languageToggle: true, // Can switch to English
                requiresPhotoForSanitation: true, // Required for his extensive sanitation tasks
                canUploadPhotos: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "5",
            name: "Mercedes Inamagua",
            email: "mercedes.inamagua@cyntientops.com",
            password: "MercedesGlass2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: true, // Simplified dashboard - clock in/out + basic tasks
                language: "es", // Spanish interface
                languageToggle: false,
                requiresPhotoForSanitation: false, // Optional photos, not required
                canUploadPhotos: true, // Can optionally add photos for database updates
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "6",
            name: "Luis Lopez",
            email: "luis.lopez@cyntientops.com",
            password: "LuisElizabeth2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false, // Full dashboard
                language: "en", // English primary with Spanish toggle
                languageToggle: true, // Can switch to Spanish
                requiresPhotoForSanitation: true,
                canUploadPhotos: true,
                canAddEmergencyTasks: false,
                eveningModeUI: false
            )
        ),
        UserAccount(
            id: "7",
            name: "Angel Guiracocha",
            email: "angel.guiracocha@cyntientops.com",
            password: "AngelDSNY2025!",
            role: "worker",
            isActive: true,
            capabilities: WorkerCapabilities(
                simplifiedInterface: false, // Full dashboard - evening shift worker
                language: "en", // English primary with Spanish toggle
                languageToggle: true, // Can switch to Spanish
                requiresPhotoForSanitation: true, // Required for DSNY tasks
                canUploadPhotos: true,
                canAddEmergencyTasks: false,
                eveningModeUI: true // Evening shift UI theme
            )
        )
    ]
    
    // MARK: - Client User Accounts
    private let clientAccounts: [UserAccount] = [
        // JM Realty
        UserAccount(
            id: "100",
            name: "JM Realty Admin",
            email: "jm@jmrealty.com",
            password: "JMRealty2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        UserAccount(
            id: "101",
            name: "David Edelman", 
            email: "David@jmrealty.org",
            password: "DavidJM2025!",
            role: "client",
            isActive: true,
            capabilities: nil
        ),
        UserAccount(
            id: "111",
            name: "Jerry Edelman",
            email: "jedelman@jmrealty.org", 
            password: "JerryJM2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Weber Farhat - Moises Farhat
        UserAccount(
            id: "103",
            name: "Moises Farhat",
            email: "mfarhat@farhatrealtymanagement.com",
            password: "MoisesFarhat2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Solar One - Candace
        UserAccount(
            id: "104",
            name: "Candace",
            email: "candace@solar1.org",
            password: "CandaceSolar2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Grand Elizabeth LLC - Michelle
        UserAccount(
            id: "105",
            name: "Michelle",
            email: "michelle@remidgroup.com",
            password: "Michelle41E2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Citadel Realty - Stephen Shapiro
        UserAccount(
            id: "106",
            name: "Stephen Shapiro",
            email: "sshapiro@citadelre.com",
            password: "StephenCit2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        ),
        
        // Corbel Property - Paul Lamban
        UserAccount(
            id: "107",
            name: "Paul Lamban",
            email: "paul@corbelpm.com",
            password: "PaulCorbel2025!",
            role: "admin",
            isActive: true,
            capabilities: nil
        )
    ]
    
    // MARK: - Public Methods
    
    /// Seed all user accounts
    public func seedAccounts() async throws {
        print("🌱 Starting user account seeding...")
        
        let allAccounts = productionAccounts + clientAccounts
        
        // Pre-hash all passwords in parallel for better performance
        var hashedAccounts: [(UserAccount, String)] = []
        
        // Hash passwords concurrently
        await withTaskGroup(of: (UserAccount, String).self) { group in
            for account in allAccounts {
                group.addTask {
                    do {
                        let hashedPassword = try await self.hashPassword(account.password, for: account.email)
                        return (account, hashedPassword)
                    } catch {
                        print("❌ Failed to hash password for \(account.email): \(error)")
                        return (account, "")
                    }
                }
            }
            
            for await result in group {
                if !result.1.isEmpty {
                    hashedAccounts.append(result)
                }
            }
        }
        
        // Batch insert all accounts using direct database access
        let currentTime = Date().ISO8601Format()
        
        for (account, hashedPassword) in hashedAccounts {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO workers (
                    id, name, email, password, role, isActive, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                account.id,
                account.name,
                account.email,
                hashedPassword,
                account.role,
                account.isActive ? 1 : 0,
                currentTime,
                currentTime
            ])
        }
        
        print("✅ Seeded \(hashedAccounts.count) accounts in batch")
        
        // Debug: Verify users were actually created
        let verifyUsers = try await grdbManager.query("SELECT id, name, email, role FROM workers")
        print("🔍 DEBUG: Found \(verifyUsers.count) users in database:")
        for user in verifyUsers {
            if let id = user["id"] as? String, 
               let name = user["name"] as? String,
               let email = user["email"] as? String,
               let role = user["role"] as? String {
                print("  - \(name) (\(email)) - Role: \(role) - ID: \(id)")
            }
        }
        
        // Debug: Also insert some plain text passwords for testing
        #if DEBUG
        print("🔧 DEBUG: Adding plain text test credentials...")
        let testCredentials = [
            ("test_admin", "Test Admin", "admin@test.com", "password", "admin"),
            ("test_shawn", "Shawn Test", "shawn@test.com", "password", "admin")
        ]
        
        for (id, name, email, password, role) in testCredentials {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO workers (
                    id, name, email, password, role, isActive, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, 1, datetime('now'), datetime('now'))
            """, [id, name, email, password, role])
        }
        print("✅ Added test credentials with plain text passwords")
        #endif
        
        // Seed worker capabilities
        try await seedWorkerCapabilities()
        
        print("🎉 Account seeding completed successfully")
    }
    
    // MARK: - Private Methods
    
    private func seedAccount(_ account: UserAccount) async throws {
        // Hash the password
        let hashedPassword = try await hashPassword(account.password, for: account.email)
        
        // Check if account already exists
        let existing = try await grdbManager.query(
            "SELECT id FROM workers WHERE email = ?",
            [account.email]
        )
        
        if !existing.isEmpty {
            // Update existing account
            try await grdbManager.execute("""
                UPDATE workers 
                SET name = ?, password = ?, role = ?, isActive = ?, updated_at = ?
                WHERE email = ?
            """, [
                account.name,
                hashedPassword,
                account.role,
                account.isActive ? 1 : 0,
                Date().ISO8601Format(),
                account.email
            ])
        } else {
            // Insert new account
            try await grdbManager.execute("""
                INSERT INTO workers (id, name, email, password, role, isActive, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                account.id,
                account.name,
                account.email,
                hashedPassword,
                account.role,
                account.isActive ? 1 : 0,
                Date().ISO8601Format(),
                Date().ISO8601Format()
            ])
        }
    }
    
    private func hashPassword(_ password: String, for email: String) async throws -> String {
        // Generate salt
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        
        // Store salt in keychain using the same method as NewAuthManager
        let keychainService = "com.cyntientops.auth"
        let saltKey = "\(keychainService).salt.\(email)"
        try storeInKeychain(salt, for: saltKey)
        
        // Hash password with salt
        let passwordData = Data(password.utf8)
        let saltedPassword = salt + passwordData
        let hash = SHA256.hash(data: saltedPassword)
        
        return Data(hash).base64EncodedString()
    }
    
    // MARK: - Keychain Methods (matching NewAuthManager)
    
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
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to store in keychain: \(status)"])
        }
    }
    
    private func seedWorkerCapabilities() async throws {
        print("🔧 Seeding worker capabilities...")
        
        // Create worker_capabilities table if it doesn't exist
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_capabilities (
                worker_id TEXT PRIMARY KEY,
                simplified_interface INTEGER DEFAULT 0,
                language TEXT DEFAULT 'en',
                requires_photo_for_sanitation INTEGER DEFAULT 1,
                can_add_emergency_tasks INTEGER DEFAULT 0,
                evening_mode_ui INTEGER DEFAULT 0,
                priority_level INTEGER DEFAULT 0,
                created_at TEXT,
                updated_at TEXT,
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)
        
        // Batch insert all capabilities 
        let accountsWithCapabilities = productionAccounts.filter { $0.capabilities != nil }
        
        for account in accountsWithCapabilities {
            let cap = account.capabilities!
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_capabilities (
                    worker_id, can_upload_photos, can_add_notes, can_view_map, 
                    can_add_emergency_tasks, requires_photo_for_sanitation, 
                    simplified_interface, preferred_language
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                account.id,
                1, // can_upload_photos - default enabled
                1, // can_add_notes - default enabled  
                1, // can_view_map - default enabled
                cap.canAddEmergencyTasks ? 1 : 0,
                cap.requiresPhotoForSanitation ? 1 : 0,
                cap.simplifiedInterface ? 1 : 0,
                cap.language
            ])
        }
        
        print("✅ Seeded worker capabilities in batch")
    }
}