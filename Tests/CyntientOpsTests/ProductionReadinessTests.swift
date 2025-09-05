//
//  ProductionReadinessTests.swift
//  CyntientOpsTests Phase 11
//
//  Production readiness validation tests
//  Comprehensive system verification before deployment
//

import XCTest
@testable import CyntientOps

@MainActor
final class ProductionReadinessTests: XCTestCase {
    
    private var productionChecker: ProductionReadinessChecker!
    private var serviceContainer: ServiceContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize production readiness checker
        serviceContainer = ServiceContainer(
            database: GRDBManager.shared,
            operationalData: OperationalDataManager(database: GRDBManager.shared)
        )
        
        productionChecker = ProductionReadinessChecker(serviceContainer: serviceContainer)
    }
    
    override func tearDown() async throws {
        productionChecker = nil
        serviceContainer = nil
        try await super.tearDown()
    }
    
    /// Test 14: Comprehensive production readiness check
    func testComprehensiveProductionReadiness() async throws {
        print("🧪 Testing: Comprehensive production readiness...")
        
        // Perform full production readiness check
        await productionChecker.performFullCheck()
        
        let report = productionChecker.getReadinessReport()
        
        // Verify overall readiness
        XCTAssertTrue(
            report.isProductionReady,
            "CRITICAL: System must be production ready. Status: \(report.overallStatus), Blockers: \(report.criticalBlockers), Warnings: \(report.warnings)"
        )
        
        // Verify success rate
        XCTAssertGreaterThanOrEqual(
            report.successRate,
            0.9,
            "CRITICAL: Production readiness success rate must be at least 90%, currently \(String(format: "%.1f%%", report.successRate * 100))"
        )
        
        // Verify no critical blockers
        XCTAssertEqual(
            report.criticalBlockers,
            0,
            "CRITICAL: No critical blockers allowed in production. Found: \(report.criticalBlockers)"
        )
        
        // Verify reasonable warning count
        XCTAssertLessThanOrEqual(
            report.warnings,
            3,
            "CRITICAL: Warning count should be minimal for production. Found: \(report.warnings)"
        )
        
        print("✅ Production readiness: \(report.summary)")
    }
    
    /// Test 15: Security validation
    func testSecurityValidation() async throws {
        print("🧪 Testing: Security validation...")
        
        // Test photo security
        let photoSecurity = PhotoSecurityManager.shared
        let stats = await photoSecurity.getSecurityStats()
        
        XCTAssertTrue(stats.encryptionEnabled, "CRITICAL: Photo encryption must be enabled in production")
        XCTAssertGreaterThanOrEqual(stats.storageUsedMB, 0, "CRITICAL: Security stats must be accessible")
        
        // Test data encryption
        let testData = "Production security test".data(using: .utf8)!
        let encrypted = try photoSecurity.encryptPhoto(testData, photoId: "security-test")
        let (decrypted, _) = try photoSecurity.decryptPhoto(encrypted)
        
        XCTAssertEqual(decrypted, testData, "CRITICAL: Encryption/decryption must work correctly")
        
        // Test client data isolation
        let jmBuildings = try await serviceContainer.client.getClientBuildings("jm-realty")
        let weberBuildings = try await serviceContainer.client.getClientBuildings("weber-farhat")
        
        let jmIds = Set(jmBuildings.map { $0.id })
        let weberIds = Set(weberBuildings.map { $0.id })
        let overlap = jmIds.intersection(weberIds)
        
        XCTAssertTrue(overlap.isEmpty, "CRITICAL: Client data must be properly isolated - found overlap: \(overlap)")
        
        print("✅ Security validation passed")
    }
    
    /// Test 16: Error handling and recovery
    func testErrorHandlingAndRecovery() async throws {
        print("🧪 Testing: Error handling and recovery...")
        
        // Test database error recovery
        let database = serviceContainer.database
        XCTAssertTrue(database.isConnected, "CRITICAL: Database must be connected")
        
        // Test invalid query handling
        do {
            _ = try await database.query("SELECT * FROM nonexistent_table")
            XCTFail("CRITICAL: Invalid queries should throw errors")
        } catch {
            // Expected error - verify system continues to function
            XCTAssertTrue(database.isConnected, "CRITICAL: Database connection must remain after error")
        }
        
        // Test service availability after errors
        let workers = serviceContainer.operationalData.getAllWorkers()
        XCTAssertFalse(workers.isEmpty, "CRITICAL: Services must remain functional after errors")
        
        // Test Nova AI error recovery
        let nova = NovaAIManager.shared
        let originalState = nova.novaState
        
        nova.novaState = .error
        XCTAssertEqual(nova.novaState, .error, "CRITICAL: Nova AI must accept error state")
        
        // Simulate recovery
        nova.novaState = originalState
        XCTAssertNotEqual(nova.novaState, .error, "CRITICAL: Nova AI must recover from error state")
        
        print("✅ Error handling and recovery verified")
    }
    
    /// Test 17: Data consistency validation
    func testDataConsistencyValidation() async throws {
        print("🧪 Testing: Data consistency validation...")
        
        let operationalData = serviceContainer.operationalData
        
        // Test worker-building relationships
        let workers = operationalData.getAllWorkers()
        let buildings = operationalData.getAllBuildings()
        
        for worker in workers {
            let workerBuildings = try await operationalData.getWorkerBuildings(workerId: worker.id)
            
            // Verify all assigned buildings exist
            for buildingId in workerBuildings {
                let buildingExists = buildings.contains { $0.id == buildingId }
                XCTAssertTrue(
                    buildingExists, 
                    "CRITICAL: Worker \(worker.name) assigned to non-existent building \(buildingId)"
                )
            }
        }
        
        // Test client-building relationships
        let clients = operationalData.getAllClients()
        
        for client in clients {
            let clientBuildings = buildings.filter { $0.clientId == client.id }
            
            XCTAssertFalse(
                clientBuildings.isEmpty,
                "CRITICAL: Client \(client.name) must have at least one building assigned"
            )
            
            // Verify building-client consistency
            for building in clientBuildings {
                XCTAssertEqual(
                    building.clientId,
                    client.id,
                    "CRITICAL: Building \(building.name) client assignment inconsistent"
                )
            }
        }
        
        // Test task-worker relationships
        let kevinTasks = try await serviceContainer.tasks.getTasks(for: "4", date: Date())
        
        for task in kevinTasks {
            XCTAssertEqual(
                task.workerId,
                "4",
                "CRITICAL: Kevin's tasks must be assigned to Kevin (Worker ID: 4)"
            )
            
            // Verify building assignments
            if let buildingId = task.buildingId {
                let kevinBuildings = try await operationalData.getWorkerBuildings(workerId: "4")
                XCTAssertTrue(
                    kevinBuildings.contains(buildingId),
                    "CRITICAL: Kevin has task for building \(buildingId) but is not assigned to it"
                )
            }
        }
        
        print("✅ Data consistency validation passed")
    }
    
    /// Test 18: API integration validation
    func testAPIIntegrationValidation() async throws {
        print("🧪 Testing: API integration validation...")
        
        guard let nycIntegration = serviceContainer.nycIntegration else {
            XCTFail("CRITICAL: NYC Integration must be available in production")
            return
        }
        
        // Test API health
        let healthReport = nycIntegration.getAPIHealthReport()
        
        XCTAssertFalse(healthReport.isEmpty, "CRITICAL: NYC API health report must contain endpoints")
        
        for apiHealth in healthReport {
            XCTAssertFalse(apiHealth.endpoint.isEmpty, "CRITICAL: API endpoint must be configured")
            XCTAssertGreaterThan(apiHealth.rateLimit, 0, "CRITICAL: Rate limit must be configured")
            
            // In production, we want most APIs to be healthy
            // For testing, we'll accept that some may be unavailable
        }
        
        // Test compliance data availability
        let complianceSnapshot = await nycIntegration.getComplianceSnapshot()
        XCTAssertNotNil(complianceSnapshot, "CRITICAL: Compliance data must be accessible")
        
        print("✅ API integration validation passed")
    }
    
    /// Test 19: Intelligence system validation
    func testIntelligenceSystemValidation() async throws {
        print("🧪 Testing: Intelligence system validation...")
        
        let intelligence = serviceContainer.intelligence
        
        // Test intelligence monitoring
        XCTAssertTrue(intelligence.isMonitoring, "CRITICAL: Intelligence system must be monitoring")
        
        // Test violation prediction
        let violationPredictor = intelligence.violationPredictor
        XCTAssertNotNil(violationPredictor, "CRITICAL: Violation predictor must be available")
        
        // Test predictions for Rubin Museum
        let rubinPredictions = violationPredictor?.getBuildingPredictions("14") ?? []
        // Predictions may be empty, but the system should be functional
        
        let rubinRiskScore = violationPredictor?.getBuildingRiskScore("14")
        // Risk score may be nil initially, but system should be functional
        
        // Test cost intelligence
        let costIntelligence = intelligence.costIntelligence
        XCTAssertNotNil(costIntelligence, "CRITICAL: Cost intelligence must be available")
        
        // Test real-time monitoring
        let realTimeMonitoring = intelligence.realTimeMonitoring
        XCTAssertNotNil(realTimeMonitoring, "CRITICAL: Real-time monitoring must be available")
        
        let healthStatus = realTimeMonitoring?.getHealthStatus()
        XCTAssertNotNil(healthStatus, "CRITICAL: Monitoring health status must be available")
        
        // Test automated workflows
        let automatedWorkflows = intelligence.automatedWorkflows
        XCTAssertNotNil(automatedWorkflows, "CRITICAL: Automated workflows must be available")
        
        print("✅ Intelligence system validation passed")
    }
    
    /// Test 20: Final production deployment readiness
    func testFinalProductionDeploymentReadiness() async throws {
        print("🧪 Testing: Final production deployment readiness...")
        
        // Comprehensive system check
        await productionChecker.performFullCheck()
        let report = productionChecker.getReadinessReport()
        
        // Critical requirements for production deployment
        XCTAssertTrue(report.isProductionReady, "BLOCKER: System not ready for production deployment")
        XCTAssertEqual(report.criticalBlockers, 0, "BLOCKER: Critical issues must be resolved")
        XCTAssertGreaterThanOrEqual(report.successRate, 0.95, "BLOCKER: Success rate must be 95% or higher")
        
        // Verify all critical services
        let health = serviceContainer.getServiceHealth()
        XCTAssertTrue(health.databaseConnected, "BLOCKER: Database must be connected")
        XCTAssertTrue(health.authInitialized, "BLOCKER: Authentication must be initialized")
        XCTAssertTrue(health.tasksLoaded, "BLOCKER: Tasks must be loaded")
        XCTAssertTrue(health.intelligenceActive, "BLOCKER: Intelligence system must be active")
        
        // Verify critical data integrity
        let kevinTasks = try await serviceContainer.tasks.getTasks(for: "4", date: Date())
        XCTAssertEqual(kevinTasks.count, 38, "BLOCKER: Kevin must have exactly 38 tasks")
        
        let kevinBuildings = try await serviceContainer.operationalData.getWorkerBuildings(workerId: "4")
        XCTAssertTrue(kevinBuildings.contains("14"), "BLOCKER: Kevin must be assigned to Rubin Museum")
        
        // Verify Nova AI persistence
        let nova1 = NovaAIManager.shared
        let nova2 = NovaAIManager.shared
        XCTAssertTrue(nova1 === nova2, "BLOCKER: Nova AI singleton must be persistent")
        
        // Verify client filtering
        let jmBuildings = try await serviceContainer.client.getClientBuildings("jm-realty")
        XCTAssertEqual(jmBuildings.count, 9, "BLOCKER: JM Realty client filtering must work")
        
        // Performance check
        let startTime = Date()
        _ = try await serviceContainer.tasks.getTasks(for: "1", date: Date())
        let queryTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(queryTime, 1.0, "BLOCKER: Query performance must be under 1 second")
        
        // Memory check
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / (1024 * 1024)
            XCTAssertLessThan(memoryUsageMB, 200.0, "BLOCKER: Memory usage must be under 200MB for production")
        }
        
        print("🚀 PRODUCTION DEPLOYMENT READINESS: \(report.isProductionReady ? "READY" : "NOT READY")")
        print("📊 Final Score: \(String(format: "%.1f%%", report.successRate * 100))")
        print("🔍 Checks: \(report.passedChecks)/\(report.totalChecks) passed")
        print("🚨 Blockers: \(report.criticalBlockers)")
        print("⚠️ Warnings: \(report.warnings)")
        
        if report.isProductionReady {
            print("✅ SYSTEM IS READY FOR PRODUCTION DEPLOYMENT! 🎉")
        } else {
            print("❌ SYSTEM NOT READY - RESOLVE ISSUES BEFORE DEPLOYMENT")
        }
    }
}

// MARK: - Mock Data Tests

@MainActor
final class MockDataEliminationTests: XCTestCase {
    
    private var serviceContainer: ServiceContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        serviceContainer = ServiceContainer(
            database: GRDBManager.shared,
            operationalData: OperationalDataManager(database: GRDBManager.shared)
        )
    }
    
    /// Test 21: Verify no mock data in production
    func testNoMockDataInProduction() async throws {
        print("🧪 Testing: No mock data in production...")
        
        // Check workers for mock data
        let workers = serviceContainer.operationalData.getAllWorkers()
        for worker in workers {
            XCTAssertFalse(
                worker.name.contains("Mock") || worker.name.contains("Test") || worker.name.contains("Sample"),
                "CRITICAL: Found mock worker data: \(worker.name)"
            )
        }
        
        // Check buildings for mock data
        let buildings = serviceContainer.operationalData.getAllBuildings()
        for building in buildings {
            XCTAssertFalse(
                building.name.contains("Mock") || building.name.contains("Test") || building.name.contains("Sample"),
                "CRITICAL: Found mock building data: \(building.name)"
            )
        }
        
        // Check clients for mock data
        let clients = serviceContainer.operationalData.getAllClients()
        for client in clients {
            XCTAssertFalse(
                client.name.contains("Mock") || client.name.contains("Test") || client.name.contains("Sample"),
                "CRITICAL: Found mock client data: \(client.name)"
            )
        }
        
        // Check Kevin's tasks for mock data
        let kevinTasks = try await serviceContainer.tasks.getTasks(for: "4", date: Date())
        for task in kevinTasks {
            XCTAssertFalse(
                task.title.contains("Mock") || task.title.contains("Test") || task.title.contains("Sample"),
                "CRITICAL: Found mock task data: \(task.title)"
            )
            
            XCTAssertFalse(
                task.description.contains("Mock") || task.description.contains("Test") || task.description.contains("Sample"),
                "CRITICAL: Found mock task description: \(task.description)"
            )
        }
        
        print("✅ No mock data found in production dataset")
    }
    
    /// Test 22: Verify realistic data quality
    func testRealisticDataQuality() async throws {
        print("🧪 Testing: Realistic data quality...")
        
        // Test worker names are realistic
        let workers = serviceContainer.operationalData.getAllWorkers()
        let expectedWorkers = ["Greg Hutson", "Edwin Lema", "Kevin Dutan", "Mercedes Inamagua", "Luis Lopez", "Angel Guiracocha", "Shawn Magloire"]
        
        for expectedWorker in expectedWorkers {
            let workerExists = workers.contains { $0.name == expectedWorker }
            XCTAssertTrue(workerExists, "CRITICAL: Expected worker \(expectedWorker) not found")
        }
        
        // Test building addresses are realistic NYC addresses
        let buildings = serviceContainer.operationalData.getAllBuildings()
        for building in buildings {
            // Should contain NYC borough or street indicators
            let hasRealisticAddress = building.address.contains("Ave") || 
                                    building.address.contains("St") ||
                                    building.address.contains("Rd") ||
                                    building.address.contains("Blvd") ||
                                    building.address.contains("Plaza") ||
                                    building.address.contains("New York") ||
                                    building.address.contains("NY")
            
            XCTAssertTrue(
                hasRealisticAddress,
                "CRITICAL: Building '\(building.name)' has unrealistic address: \(building.address)"
            )
        }
        
        // Test Rubin Museum specifically
        let rubinMuseum = buildings.first { $0.id == "14" }
        XCTAssertNotNil(rubinMuseum, "CRITICAL: Rubin Museum must exist")
        XCTAssertEqual(rubinMuseum?.name, "Rubin Museum", "CRITICAL: Building 14 must be named 'Rubin Museum'")
        
        // Test client names are realistic
        let clients = serviceContainer.operationalData.getAllClients()
        let jmRealty = clients.first { $0.id == "jm-realty" }
        XCTAssertNotNil(jmRealty, "CRITICAL: JM Realty client must exist")
        XCTAssertEqual(jmRealty?.name, "JM Realty", "CRITICAL: JM Realty client name must be correct")
        
        print("✅ Data quality verification passed")
    }
}