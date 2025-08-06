// ===================================================================
// File: Scripts/ProductionLaunchValidator.swift
// ===================================================================

import Foundation

@MainActor
public final class ProductionLaunchValidator {
    
    private let container: ServiceContainer
    
    public init(container: ServiceContainer) {
        self.container = container
    }
    
    // MARK: - Critical Validations
    
    public func validateCriticalSystems() async -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // 1. Database Validation
        if !container.database.isConnected {
            issues.append("❌ Database not connected")
        }
        
        // 2. Authentication
        if !container.auth.isInitialized {
            issues.append("❌ Authentication service not initialized")
        }
        
        // 3. Operational Data
        let taskCount = container.operationalData.realWorldTasks.count
        if taskCount != 88 {
            issues.append("❌ Expected 88 task templates, found \(taskCount)")
        }
        
        // 4. Workers
        do {
            let workers = try await container.workers.getAllActiveWorkers()
            if workers.count != 7 {
                issues.append("❌ Expected 7 workers, found \(workers.count)")
            }
        } catch {
            issues.append("❌ Failed to validate workers: \(error)")
        }
        
        // 5. Buildings
        do {
            let buildings = try await container.buildings.getAllBuildings()
            if buildings.count < 16 {
                warnings.append("⚠️ Expected 16+ buildings, found \(buildings.count)")
            }
        } catch {
            issues.append("❌ Failed to validate buildings: \(error)")
        }
        
        // 6. NYC API Integration
        if ProductionConfiguration.FeatureFlags.isNYCAPIEnabled {
            let nycAPIKey = ProductionConfiguration.Environment.production.nycAPIKey
            if nycAPIKey.isEmpty {
                issues.append("❌ NYC API key not configured")
            }
        }
        
        // 7. Photo Storage
        if !PhotoEvidenceService.isConfigured {
            warnings.append("⚠️ Photo evidence service not fully configured")
        }
        
        // 8. Offline Queue
        let queueSize = container.offlineQueue.getQueueStatus().totalActions
        if queueSize > 100 {
            warnings.append("⚠️ Large offline queue: \(queueSize) items")
        }
        
        // 9. Memory Usage
        let memoryUsage = getMemoryUsage()
        if memoryUsage > 100 { // MB
            warnings.append("⚠️ High memory usage: \(memoryUsage)MB")
        }
        
        // 10. Service Health
        let health = await container.getServiceHealth()
        if !health.isHealthy {
            issues.append("❌ Service health check failed: \(health.summary)")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            criticalIssues: issues,
            warnings: warnings,
            timestamp: Date()
        )
    }
    
    // MARK: - Pre-Flight Checks
    
    public func runPreFlightChecks() async -> PreFlightResult {
        print("🚀 Running pre-flight checks...")
        
        var checks: [PreFlightCheck] = []
        
        // Check 1: Database Schema
        checks.append(PreFlightCheck(
            name: "Database Schema",
            passed: await validateDatabaseSchema(),
            critical: true
        ))
        
        // Check 2: User Accounts
        checks.append(PreFlightCheck(
            name: "User Accounts",
            passed: await validateUserAccounts(),
            critical: true
        ))
        
        // Check 3: API Connectivity
        checks.append(PreFlightCheck(
            name: "API Connectivity",
            passed: await testAPIConnectivity(),
            critical: true
        ))
        
        // Check 4: Photo Upload
        checks.append(PreFlightCheck(
            name: "Photo Upload",
            passed: await testPhotoUpload(),
            critical: false
        ))
        
        // Check 5: Real-time Sync
        checks.append(PreFlightCheck(
            name: "Real-time Sync",
            passed: await testRealtimeSync(),
            critical: false
        ))
        
        // Check 6: NYC APIs
        if ProductionConfiguration.FeatureFlags.isNYCAPIEnabled {
            checks.append(PreFlightCheck(
                name: "NYC API Integration",
                passed: await testNYCAPIs(),
                critical: false
            ))
        }
        
        let allPassed = checks.allSatisfy { $0.passed }
        let criticalPassed = checks.filter { $0.critical }.allSatisfy { $0.passed }
        
        return PreFlightResult(
            checks: checks,
            allPassed: allPassed,
            criticalPassed: criticalPassed,
            canLaunch: criticalPassed,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Validation Methods
    
    private func validateDatabaseSchema() async -> Bool {
        // Check if all required tables exist
        do {
            let tables = try await container.database.query("SELECT name FROM sqlite_master WHERE type='table'")
            let requiredTables = [
                "users", "workers", "buildings", "routine_tasks",
                "clock_sessions", "photo_evidence", "clients",
                "client_buildings", "worker_capabilities"
            ]
            
            let existingTables = tables.compactMap { $0["name"] as? String }
            return requiredTables.allSatisfy { existingTables.contains($0) }
        } catch {
            print("❌ Database schema validation failed: \(error)")
            return false
        }
    }
    
    private func validateUserAccounts() async -> Bool {
        // Check if all required users exist
        let requiredEmails = [
            "admin@cyntientops.com",
            "greg.hutson@cyntientops.com",
            "kevin.dutan@cyntientops.com",
            "edwin.lema@cyntientops.com",
            "mercedes.inamagua@cyntientops.com",
            "luis.lopez@cyntientops.com",
            "angel.guiracocha@cyntientops.com",
            "shawn.magloire@cyntientops.com"
        ]
        
        for email in requiredEmails {
            do {
                let exists = try await container.auth.userExists(email: email)
                if !exists {
                    print("❌ Missing user account: \(email)")
                    return false
                }
            } catch {
                print("❌ Error checking user \(email): \(error)")
                return false
            }
        }
        
        return true
    }
    
    private func testAPIConnectivity() async -> Bool {
        // Test connection to production API
        let url = URL(string: ProductionConfiguration.Environment.production.baseURL + "/health")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ API connectivity test failed: \(error)")
        }
        
        return false
    }
    
    private func testPhotoUpload() async -> Bool {
        // Test photo upload capability
        return PhotoEvidenceService.isConfigured
    }
    
    private func testRealtimeSync() async -> Bool {
        // Test WebSocket connection
        return await container.dashboardSync.testConnection()
    }
    
    private func testNYCAPIs() async -> Bool {
        // Test NYC API connectivity
        do {
            _ = try await NYCAPIService.shared.fetchHPDViolations(bin: "test")
            return true
        } catch {
            print("⚠️ NYC API test failed: \(error)")
            return false
        }
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size / 1024 / 1024) : 0
    }
}

// MARK: - Result Models

public struct ValidationResult {
    public let isValid: Bool
    public let criticalIssues: [String]
    public let warnings: [String]
    public let timestamp: Date
}

public struct PreFlightCheck {
    public let name: String
    public let passed: Bool
    public let critical: Bool
}

public struct PreFlightResult {
    public let checks: [PreFlightCheck]
    public let allPassed: Bool
    public let criticalPassed: Bool
    public let canLaunch: Bool
    public let timestamp: Date
}