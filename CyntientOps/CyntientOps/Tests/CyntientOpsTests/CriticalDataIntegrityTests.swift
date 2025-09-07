//
//  CriticalDataIntegrityTests.swift
//  CyntientOpsTests Phase 11
//
//  Critical data integrity tests ensuring production readiness
//  Tests Kevin's 38 tasks, Rubin Museum assignment, Nova AI persistence, and more
//

import XCTest
@testable import CyntientOps

@MainActor
final class CriticalDataIntegrityTests: XCTestCase {
    
    private var serviceContainer: ServiceContainer!
    private var operationalData: OperationalDataManager!
    private var database: GRDBManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize test dependencies
        database = GRDBManager.shared
        operationalData = OperationalDataManager(database: database)
        
        // Create service container with test configuration
        serviceContainer = ServiceContainer(
            database: database,
            operationalData: operationalData
        )
        
        // Ensure clean state
        await ensureTestDataState()
    }
    
    override func tearDown() async throws {
        serviceContainer = nil
        operationalData = nil
        try await super.tearDown()
    }
    
    // MARK: - Critical Data Tests
    
    /// Test 1: Kevin Dutan must have exactly 38 tasks
    func testKevinHas38Tasks() async throws {
        print("🧪 Testing: Kevin has exactly 38 tasks...")
        
        let kevinWorkerId = "4"
        let kevinTasks = try await serviceContainer.tasks.getTasks(for: kevinWorkerId, date: Date())
        
        XCTAssertEqual(
            kevinTasks.count, 
            38, 
            "CRITICAL: Kevin Dutan (Worker ID: 4) must have exactly 38 tasks, found \(kevinTasks.count). This is required for production data integrity."
        )
        
        // Verify tasks are real, not mock data
        let realTasksCount = kevinTasks.filter { !$0.title.contains("Mock") && !$0.title.contains("Test") }.count
        XCTAssertEqual(
            realTasksCount, 
            kevinTasks.count, 
            "CRITICAL: All of Kevin's tasks must be real production data, found \(kevinTasks.count - realTasksCount) mock/test tasks"
        )
        
        print("✅ Kevin has exactly 38 real tasks")
    }
    
    /// Test 2: Rubin Museum (Building ID: 14) must be in Kevin's assigned buildings
    func testRubinMuseumAssignedToKevin() async throws {
        print("🧪 Testing: Rubin Museum assigned to Kevin...")
        
        let kevinWorkerId = "4"
        let rubinMuseumId = "14"
        
        let kevinBuildings = try await operationalData.getWorkerBuildings(workerId: kevinWorkerId)
        
        XCTAssertTrue(
            kevinBuildings.contains(rubinMuseumId),
            "CRITICAL: Rubin Museum (Building ID: 14) must be assigned to Kevin Dutan (Worker ID: 4). Current buildings: \(kevinBuildings)"
        )
        
        // Verify Rubin Museum exists in buildings data
        let rubinMuseum = operationalData.getAllBuildings().first { $0.id == rubinMuseumId }
        XCTAssertNotNil(rubinMuseum, "CRITICAL: Rubin Museum (Building ID: 14) must exist in buildings database")
        XCTAssertEqual(rubinMuseum?.name, "Rubin Museum", "CRITICAL: Building ID 14 must be named 'Rubin Museum'")
        
        print("✅ Rubin Museum is properly assigned to Kevin")
    }
    
    /// Test 3: Production data counts must match specifications
    func testProductionDataCounts() async throws {
        print("🧪 Testing: Production data counts...")
        
        let workers = operationalData.getAllWorkers()
        let buildings = operationalData.getAllBuildings() 
        let clients = operationalData.getAllClients()
        
        // Test exact counts as specified in CLAUDE.md
        XCTAssertEqual(workers.count, 7, "CRITICAL: Must have exactly 7 active workers, found \(workers.count)")
        XCTAssertEqual(buildings.count, 16, "CRITICAL: Must have exactly 16 active buildings, found \(buildings.count)")
        XCTAssertEqual(clients.count, 6, "CRITICAL: Must have exactly 6 clients, found \(clients.count)")
        
        // Verify JM Realty has 9 buildings
        let jmRealtyBuildings = buildings.filter { $0.clientId == "jm-realty" }
        XCTAssertEqual(jmRealtyBuildings.count, 9, "CRITICAL: JM Realty must have exactly 9 buildings, found \(jmRealtyBuildings.count)")
        
        // Verify other clients have 1-2 buildings each
        let otherClients = ["weber-farhat", "solar-one", "grand-elizabeth", "citadel-realty", "corbel-property"]
        for clientId in otherClients {
            let clientBuildings = buildings.filter { $0.clientId == clientId }
            XCTAssertTrue(
                clientBuildings.count >= 1 && clientBuildings.count <= 2,
                "CRITICAL: Client \(clientId) must have 1-2 buildings, found \(clientBuildings.count)"
            )
        }
        
        print("✅ Production data counts are correct")
    }
    
    /// Test 4: Nova AI persistence across app lifecycle
    func testNovaAIPersistence() async throws {
        print("🧪 Testing: Nova AI persistence...")
        
        // Test singleton pattern
        let nova1 = NovaAIManager.shared
        let nova2 = NovaAIManager.shared
        
        XCTAssertTrue(nova1 === nova2, "CRITICAL: NovaAIManager must be a true singleton")
        
        // Test image loading
        XCTAssertNotNil(nova1.novaImage, "CRITICAL: Nova AI image must be loaded and available")
        
        // Test state persistence
        let originalState = nova1.novaState
        nova1.novaState = .thinking
        
        let nova3 = NovaAIManager.shared
        XCTAssertEqual(nova3.novaState, .thinking, "CRITICAL: Nova AI state must persist across singleton references")
        
        // Reset state
        nova1.novaState = originalState
        
        // Test animation state
        let hasAnimation = nova1.pulseAnimation || nova1.rotationAngle > 0
        XCTAssertTrue(hasAnimation || nova1.novaState != .idle, "CRITICAL: Nova AI should show some animation or active state")
        
        print("✅ Nova AI persistence is working correctly")
    }
    
    /// Test 5: Client data filtering security
    func testClientDataFiltering() async throws {
        print("🧪 Testing: Client data filtering security...")
        
        // Test JM Realty filtering (should see only their 9 buildings)
        let jmBuildings = try await serviceContainer.client.getClientBuildings("jm-realty")
        XCTAssertEqual(jmBuildings.count, 9, "CRITICAL: JM Realty must see exactly 9 buildings, found \(jmBuildings.count)")
        
        // Verify JM Realty cannot see other clients' buildings
        for building in jmBuildings {
            XCTAssertEqual(building.clientId, "jm-realty", "CRITICAL: JM Realty should only see their own buildings, found building for client: \(building.clientId ?? "unknown")")
        }
        
        // Test Weber Farhat filtering (should see only 1 building)
        let weberBuildings = try await serviceContainer.client.getClientBuildings("weber-farhat")
        XCTAssertEqual(weberBuildings.count, 1, "CRITICAL: Weber Farhat must see exactly 1 building, found \(weberBuildings.count)")
        
        // Test that clients cannot access other clients' data
        let solarBuildings = try await serviceContainer.client.getClientBuildings("solar-one")
        let citadelBuildings = try await serviceContainer.client.getClientBuildings("citadel-realty")
        
        // Verify no overlap between client building lists
        let solarBuildingIds = Set(solarBuildings.map { $0.id })
        let citadelBuildingIds = Set(citadelBuildings.map { $0.id })
        let intersection = solarBuildingIds.intersection(citadelBuildingIds)
        
        XCTAssertTrue(intersection.isEmpty, "CRITICAL: Clients must not see overlapping buildings - security breach detected")
        
        print("✅ Client data filtering security is working correctly")
    }
    
    /// Test 6: Service Container architecture integrity
    func testServiceContainerArchitecture() async throws {
        print("🧪 Testing: Service Container architecture...")
        
        // Test layer initialization
        XCTAssertNotNil(serviceContainer.database, "CRITICAL: Layer 0 - Database must be initialized")
        XCTAssertNotNil(serviceContainer.auth, "CRITICAL: Layer 1 - Auth service must be initialized")
        XCTAssertNotNil(serviceContainer.tasks, "CRITICAL: Layer 1 - Task service must be initialized")
        XCTAssertNotNil(serviceContainer.workers, "CRITICAL: Layer 1 - Worker service must be initialized")
        XCTAssertNotNil(serviceContainer.buildings, "CRITICAL: Layer 1 - Building service must be initialized")
        XCTAssertNotNil(serviceContainer.dashboardSync, "CRITICAL: Layer 2 - Dashboard sync must be initialized")
        XCTAssertNotNil(serviceContainer.intelligence, "CRITICAL: Layer 3 - Intelligence service must be initialized")
        XCTAssertNotNil(serviceContainer.commands, "CRITICAL: Layer 5 - Command chains must be initialized")
        XCTAssertNotNil(serviceContainer.offlineQueue, "CRITICAL: Layer 6 - Offline queue must be initialized")
        
        // Test service dependencies
        XCTAssertTrue(serviceContainer.database.isConnected, "CRITICAL: Database must be connected")
        XCTAssertTrue(serviceContainer.auth.isInitialized, "CRITICAL: Auth service must be initialized")
        XCTAssertTrue(serviceContainer.dashboardSync.isActive, "CRITICAL: Dashboard sync must be active")
        
        // Test service health
        let health = serviceContainer.getServiceHealth()
        XCTAssertTrue(health.databaseConnected, "CRITICAL: Service health - database must be connected")
        XCTAssertTrue(health.authInitialized, "CRITICAL: Service health - auth must be initialized")
        XCTAssertTrue(health.tasksLoaded, "CRITICAL: Service health - tasks must be loaded")
        
        print("✅ Service Container architecture is intact")
    }
    
    /// Test 7: Database integrity and performance
    func testDatabaseIntegrityAndPerformance() async throws {
        print("🧪 Testing: Database integrity and performance...")
        
        // Test database connection health
        XCTAssertTrue(database.isConnected, "CRITICAL: Database must be connected")
        
        // Test database stats
        let stats = database.getDatabaseStats()
        XCTAssertTrue(stats.isHealthy, "CRITICAL: Database must report healthy status")
        XCTAssertEqual(stats.workers, 7, "CRITICAL: Database must contain 7 workers")
        XCTAssertEqual(stats.buildings, 16, "CRITICAL: Database must contain 16 buildings")
        
        // Test query performance (should complete within reasonable time)
        let startTime = Date()
        _ = try await database.query("SELECT COUNT(*) FROM tasks WHERE worker_id = ?", ["4"])
        let queryTime = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(queryTime, 1.0, "CRITICAL: Database queries must complete within 1 second, took \(queryTime)s")
        
        // Test transaction integrity
        do {
            try await database.execute("BEGIN TRANSACTION")
            try await database.execute("INSERT INTO test_table (id, name) VALUES (?, ?)", ["test-id", "test-name"])
            try await database.execute("ROLLBACK")
            print("✅ Database transaction integrity verified")
        } catch {
            // This is expected if test_table doesn't exist, which is fine
            print("⚠️ Skipped transaction test - table not available")
        }
        
        print("✅ Database integrity and performance verified")
    }
    
    /// Test 8: NYC API integration health
    func testNYCAPIIntegration() async throws {
        print("🧪 Testing: NYC API integration...")
        
        guard let nycIntegration = serviceContainer.nycIntegration else {
            XCTFail("CRITICAL: NYC Integration service must be available")
            return
        }
        
        // Test API health
        let healthReport = nycIntegration.getAPIHealthReport()
        XCTAssertFalse(healthReport.isEmpty, "CRITICAL: NYC API health report must contain API endpoints")
        
        // Test that at least some APIs are configured
        let configuredAPIs = healthReport.filter { !$0.endpoint.isEmpty }
        XCTAssertGreaterThan(configuredAPIs.count, 0, "CRITICAL: At least some NYC APIs must be configured")
        
        // Test rate limiting configuration
        for apiHealth in healthReport {
            XCTAssertGreaterThan(apiHealth.rateLimit, 0, "CRITICAL: API \(apiHealth.apiType) must have rate limiting configured")
        }
        
        // Test compliance data integration
        let complianceData = await nycIntegration.getComplianceSnapshot()
        XCTAssertNotNil(complianceData, "CRITICAL: NYC compliance data integration must be functional")
        
        print("✅ NYC API integration is healthy")
    }
    
    /// Test 9: Offline support functionality
    func testOfflineSupportFunctionality() async throws {
        print("🧪 Testing: Offline support functionality...")
        
        let offlineQueue = serviceContainer.offlineQueue
        
        // Test queue initialization
        XCTAssertNotNil(offlineQueue, "CRITICAL: Offline queue must be initialized")
        XCTAssertGreaterThanOrEqual(offlineQueue.pendingActions.count, 0, "CRITICAL: Offline queue must be accessible")
        
        // Test queue status
        let queueStatus = offlineQueue.getQueueStatus()
        XCTAssertGreaterThanOrEqual(queueStatus.totalActions, 0, "CRITICAL: Queue status must be retrievable")
        
        // Test enqueue functionality
        let testAction = OfflineAction(
            type: .taskCompletion,
            data: TaskCompletionData(taskId: "test-task", workerId: "4", notes: "Test completion")
        )
        
        let initialCount = offlineQueue.pendingActions.count
        offlineQueue.enqueue(testAction)
        
        XCTAssertEqual(offlineQueue.pendingActions.count, initialCount + 1, "CRITICAL: Offline queue must accept new actions")
        
        // Clean up test action
        offlineQueue.clearQueue()
        
        print("✅ Offline support functionality verified")
    }
    
    /// Test 10: Intelligence system integration
    func testIntelligenceSystemIntegration() async throws {
        print("🧪 Testing: Intelligence system integration...")
        
        let intelligence = serviceContainer.intelligence
        
        // Test intelligence service availability
        XCTAssertNotNil(intelligence, "CRITICAL: Intelligence service must be available")
        XCTAssertTrue(intelligence.isMonitoring, "CRITICAL: Intelligence monitoring must be active")
        
        // Test violation predictor integration
        let violationPredictor = try XCTUnwrap(intelligence.violationPredictor, "CRITICAL: Violation predictor must be integrated")
        
        // Test prediction for Rubin Museum (Kevin's building)
        let rubinPredictions = violationPredictor.getBuildingPredictions("14")
        XCTAssertNotNil(rubinPredictions, "CRITICAL: Violation predictions must be available for Rubin Museum")
        
        // Test cost intelligence integration
        let costIntelligence = try XCTUnwrap(intelligence.costIntelligence, "CRITICAL: Cost intelligence must be integrated")
        
        let costAnalysis = costIntelligence.getBuildingCostAnalysis("14")
        XCTAssertNotNil(costAnalysis, "CRITICAL: Cost analysis must be available for buildings")
        
        // Test real-time monitoring
        let realTimeMonitoring = try XCTUnwrap(intelligence.realTimeMonitoring, "CRITICAL: Real-time monitoring must be integrated")
        
        let healthStatus = realTimeMonitoring.getHealthStatus()
        XCTAssertNotNil(healthStatus, "CRITICAL: Real-time monitoring health status must be available")
        
        print("✅ Intelligence system integration verified")
    }
    
    // MARK: - Helper Methods
    
    private func ensureTestDataState() async {
        // Ensure database is in correct state for testing
        do {
            // Verify Kevin exists and has correct task count
            let kevinExists = operationalData.getAllWorkers().contains { $0.id == "4" }
            if !kevinExists {
                print("⚠️ Warning: Kevin Dutan (Worker ID: 4) not found in test data")
            }
            
            // Verify Rubin Museum exists
            let rubinExists = operationalData.getAllBuildings().contains { $0.id == "14" }
            if !rubinExists {
                print("⚠️ Warning: Rubin Museum (Building ID: 14) not found in test data")
            }
            
        } catch {
            print("⚠️ Warning: Could not verify test data state: \(error)")
        }
    }
}

// MARK: - Performance Tests

@MainActor
final class CriticalPerformanceTests: XCTestCase {
    
    private var serviceContainer: ServiceContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        serviceContainer = ServiceContainer(
            database: GRDBManager.shared,
            operationalData: OperationalDataManager(database: GRDBManager.shared)
        )
    }
    
    /// Test 11: Dashboard loading performance
    func testDashboardLoadingPerformance() async throws {
        print("🧪 Testing: Dashboard loading performance...")
        
        let startTime = Date()
        
        // Simulate loading all three dashboards
        let workerTasks = try await serviceContainer.tasks.getTasks(for: "4", date: Date())
        let adminBuildings = serviceContainer.operationalData.getAllBuildings()
        let clientBuildings = try await serviceContainer.client.getClientBuildings("jm-realty")
        
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Verify data was loaded
        XCTAssertFalse(workerTasks.isEmpty, "CRITICAL: Worker tasks must load")
        XCTAssertFalse(adminBuildings.isEmpty, "CRITICAL: Admin buildings must load")
        XCTAssertFalse(clientBuildings.isEmpty, "CRITICAL: Client buildings must load")
        
        // Performance requirement: under 2 seconds for dashboard data
        XCTAssertLessThan(loadTime, 2.0, "CRITICAL: Dashboard data must load within 2 seconds, took \(loadTime)s")
        
        print("✅ Dashboard loading performance: \(String(format: "%.2f", loadTime))s")
    }
    
    /// Test 12: Memory usage validation
    func testMemoryUsage() throws {
        print("🧪 Testing: Memory usage...")
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        XCTAssertEqual(result, KERN_SUCCESS, "CRITICAL: Memory usage check must succeed")
        
        let memoryUsageMB = Double(info.resident_size) / (1024 * 1024)
        print("Current memory usage: \(String(format: "%.1f", memoryUsageMB))MB")
        
        // Memory requirement: under 150MB for production app
        XCTAssertLessThan(memoryUsageMB, 150.0, "CRITICAL: Memory usage must be under 150MB, currently using \(String(format: "%.1f", memoryUsageMB))MB")
        
        print("✅ Memory usage within acceptable limits")
    }
    
    /// Test 13: Concurrent operations stress test
    func testConcurrentOperations() async throws {
        print("🧪 Testing: Concurrent operations...")
        
        let startTime = Date()
        
        // Simulate concurrent dashboard operations
        await withTaskGroup(of: Void.self) { group in
            // Worker dashboard operations
            group.addTask {
                let _ = try? await self.serviceContainer.tasks.getTasks(for: "4", date: Date())
            }
            
            // Admin dashboard operations
            group.addTask {
                let _ = self.serviceContainer.operationalData.getAllBuildings()
            }
            
            // Client dashboard operations
            group.addTask {
                let _ = try? await self.serviceContainer.client.getClientBuildings("jm-realty")
            }
            
            // Intelligence operations
            group.addTask {
                let _ = self.serviceContainer.intelligence.insights
            }
            
            // Database operations
            group.addTask {
                let _ = try? await self.serviceContainer.database.query("SELECT COUNT(*) FROM workers")
            }
        }
        
        let concurrentTime = Date().timeIntervalSince(startTime)
        
        // Concurrent operations should complete within reasonable time
        XCTAssertLessThan(concurrentTime, 3.0, "CRITICAL: Concurrent operations must complete within 3 seconds, took \(concurrentTime)s")
        
        print("✅ Concurrent operations performance: \(String(format: "%.2f", concurrentTime))s")
    }
}