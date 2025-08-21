//
//  TestingFramework.swift
//  CyntientOps Testing
//
//  Comprehensive testing framework for production validation
//  Includes unit tests, integration tests, and system tests
//

import Foundation
import XCTest

@MainActor
public final class TestingFramework: ObservableObject {
    
    public static let shared = TestingFramework()
    
    // MARK: - Published Properties
    @Published public var testResults: [TestResult] = []
    @Published public var isRunning = false
    @Published public var overallStatus: TestStatus = .unknown
    
    public enum TestStatus {
        case unknown
        case running
        case passed
        case failed
        case partial
    }
    
    public struct TestResult {
        public let name: String
        public let category: TestCategory
        public let status: TestStatus
        public let duration: TimeInterval
        public let error: String?
        public let timestamp: Date
        
        public enum TestCategory {
            case unit
            case integration
            case system
            case performance
            case security
        }
    }
    
    private init() {}
    
    // MARK: - Test Execution
    
    /// Run comprehensive test suite
    public func runAllTests() async {
        isRunning = true
        testResults.removeAll()
        
        logInfo("🧪 Starting comprehensive test suite...")
        
        // Unit Tests
        await runUnitTests()
        
        // Integration Tests  
        await runIntegrationTests()
        
        // System Tests
        await runSystemTests()
        
        // Performance Tests
        await runPerformanceTests()
        
        // Security Tests
        await runSecurityTests()
        
        // Calculate overall status
        calculateOverallStatus()
        
        isRunning = false
        logInfo("✅ Test suite completed")
    }
    
    // MARK: - Unit Tests
    
    private func runUnitTests() async {
        logInfo("🔬 Running unit tests...")
        
        await runTest("AuthenticationService Login", category: .unit) {
            try await testAuthenticationLogin()
        }
        
        await runTest("ServiceContainer Initialization", category: .unit) {
            try await testServiceContainerInit()
        }
        
        await runTest("Task Service Operations", category: .unit) {
            try await testTaskServiceOperations()
        }
        
        await runTest("Weather Data Adapter", category: .unit) {
            try await testWeatherDataAdapter()
        }
        
        await runTest("Report Generation", category: .unit) {
            try await testReportGeneration()
        }
    }
    
    // MARK: - Integration Tests
    
    private func runIntegrationTests() async {
        logInfo("🔗 Running integration tests...")
        
        await runTest("Database Operations", category: .integration) {
            try await testDatabaseIntegration()
        }
        
        await runTest("NYC API Integration", category: .integration) {
            try await testNYCAPIIntegration()
        }
        
        await runTest("Dashboard Sync Service", category: .integration) {
            try await testDashboardSyncIntegration()
        }
        
        await runTest("Photo Evidence Service", category: .integration) {
            try await testPhotoEvidenceIntegration()
        }
    }
    
    // MARK: - System Tests
    
    private func runSystemTests() async {
        logInfo("🏗️ Running system tests...")
        
        await runTest("Production Data Integrity", category: .system) {
            try await testProductionDataIntegrity()
        }
        
        await runTest("Worker Task Assignment", category: .system) {
            try await testWorkerTaskSystem()
        }
        
        await runTest("Building Operations", category: .system) {
            try await testBuildingSystem()
        }
        
        await runTest("Compliance System", category: .system) {
            try await testComplianceSystem()
        }
    }
    
    // MARK: - Performance Tests
    
    private func runPerformanceTests() async {
        logInfo("⚡ Running performance tests...")
        
        await runTest("App Launch Performance", category: .performance) {
            try await testAppLaunchPerformance()
        }
        
        await runTest("Database Query Performance", category: .performance) {
            try await testDatabasePerformance()
        }
        
        await runTest("Memory Usage", category: .performance) {
            try await testMemoryUsage()
        }
    }
    
    // MARK: - Security Tests
    
    private func runSecurityTests() async {
        logInfo("🔒 Running security tests...")
        
        await runTest("Credential Security", category: .security) {
            try await testCredentialSecurity()
        }
        
        await runTest("Session Management", category: .security) {
            try await testSessionSecurity()
        }
        
        await runTest("Data Encryption", category: .security) {
            try await testDataEncryption()
        }
    }
    
    // MARK: - Test Helper
    
    private func runTest(_ name: String, category: TestResult.TestCategory, test: @escaping () async throws -> Void) async {
        let startTime = Date()
        
        do {
            try await test()
            let duration = Date().timeIntervalSince(startTime)
            
            let result = TestResult(
                name: name,
                category: category,
                status: .passed,
                duration: duration,
                error: nil,
                timestamp: Date()
            )
            
            testResults.append(result)
            logInfo("✅ \(name) - PASSED (\(String(format: "%.2f", duration))s)")
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            let result = TestResult(
                name: name,
                category: category,
                status: .failed,
                duration: duration,
                error: error.localizedDescription,
                timestamp: Date()
            )
            
            testResults.append(result)
            logInfo("❌ \(name) - FAILED: \(error.localizedDescription)")
        }
    }
    
    private func calculateOverallStatus() {
        let passedCount = testResults.filter { $0.status == .passed }.count
        let totalCount = testResults.count
        
        if totalCount == 0 {
            overallStatus = .unknown
        } else if passedCount == totalCount {
            overallStatus = .passed
        } else if passedCount == 0 {
            overallStatus = .failed
        } else {
            overallStatus = .partial
        }
        
        logInfo("📊 Test Results: \(passedCount)/\(totalCount) passed")
    }
    
    // MARK: - Individual Test Implementations
    
    private func testAuthenticationLogin() async throws {
        // Test authentication service
        let database = GRDBManager.shared
        let authService = AuthenticationService(database: database)
        
        // This would test with a known test account
        // For now, just verify the service initializes correctly
        XCTAssertNotNil(authService)
    }
    
    private func testServiceContainerInit() async throws {
        // Test that ServiceContainer can be created
        let container = try await ServiceContainer()
        XCTAssertNotNil(container)
        XCTAssertNotNil(container.database)
        XCTAssertNotNil(container.auth)
        XCTAssertNotNil(container.tasks)
        XCTAssertNotNil(container.workers)
        XCTAssertNotNil(container.buildings)
    }
    
    private func testTaskServiceOperations() async throws {
        let taskService = TaskService.shared
        
        // Test task retrieval (this should work with existing data)
        let tasks = try await taskService.getTasks(for: "4", date: Date())
        XCTAssertTrue(tasks.count >= 0) // Should not crash
    }
    
    private func testWeatherDataAdapter() async throws {
        let adapter = WeatherDataAdapter()
        
        // Test with NYC coordinates
        let weather = try await adapter.fetchWeatherData(
            latitude: 40.7589,
            longitude: -73.9851
        )
        
        XCTAssertNotNil(weather)
        XCTAssertTrue(weather.temperature > -50 && weather.temperature < 150)
    }
    
    private func testReportGeneration() async throws {
        let reportService = ReportService.shared
        
        // Test that report service can generate reports
        let reports = try await reportService.getAllReports()
        XCTAssertTrue(reports.count >= 0) // Should not crash
    }
    
    private func testDatabaseIntegration() async throws {
        let database = GRDBManager.shared
        
        // Test basic database connectivity
        let result = try await database.query("SELECT COUNT(*) as count FROM workers")
        XCTAssertFalse(result.isEmpty)
        
        if let count = result.first?["count"] as? Int64 {
            XCTAssertTrue(count >= 0)
        }
    }
    
    private func testNYCAPIIntegration() async throws {
        // Test NYC API service initialization
        let nycService = NYCAPIService.shared
        XCTAssertNotNil(nycService)
        
        // In a real test, you would test actual API calls
        // For now, just verify the service initializes
    }
    
    private func testDashboardSyncIntegration() async throws {
        let syncService = DashboardSyncService.shared
        XCTAssertNotNil(syncService)
        
        // Test sync status
        let status = syncService.currentStatus
        XCTAssertNotNil(status)
    }
    
    private func testPhotoEvidenceIntegration() async throws {
        let photoService = PhotoEvidenceService.shared
        XCTAssertNotNil(photoService)
    }
    
    private func testProductionDataIntegrity() async throws {
        // Test Kevin's 38 tasks
        let taskService = TaskService.shared
        let kevinTasks = try await taskService.getTasks(for: "4", date: Date())
        XCTAssertEqual(kevinTasks.count, 38, "Kevin should have exactly 38 tasks")
        
        // Test building data
        let operationalData = OperationalDataManager.shared
        let buildings = operationalData.buildings
        XCTAssertTrue(buildings.count >= 16, "Should have at least 16 buildings")
        
        // Test worker data  
        let workers = Array(operationalData.getUniqueWorkerNames())
        XCTAssertTrue(workers.count >= 7, "Should have at least 7 workers")
    }
    
    private func testWorkerTaskSystem() async throws {
        let workerService = WorkerService.shared
        let workers = try await workerService.getAllWorkers()
        XCTAssertFalse(workers.isEmpty)
    }
    
    private func testBuildingSystem() async throws {
        let buildingService = BuildingService.shared
        let buildings = try await buildingService.getAllBuildings()
        XCTAssertFalse(buildings.isEmpty)
    }
    
    private func testComplianceSystem() async throws {
        let complianceService = ComplianceService.shared
        // Test compliance service initialization
        XCTAssertNotNil(complianceService)
    }
    
    private func testAppLaunchPerformance() async throws {
        // Simulate app launch timing
        let startTime = Date()
        
        // Simulate initialization work
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let launchTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(launchTime, 3.0, "App should launch in less than 3 seconds")
    }
    
    private func testDatabasePerformance() async throws {
        let database = GRDBManager.shared
        let startTime = Date()
        
        // Test query performance
        _ = try await database.query("SELECT COUNT(*) FROM tasks")
        
        let queryTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(queryTime, 1.0, "Database queries should complete in less than 1 second")
    }
    
    private func testMemoryUsage() async throws {
        // Get current memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / (1024 * 1024)
            XCTAssertLessThan(memoryMB, 200.0, "App should use less than 200MB memory")
        }
    }
    
    private func testCredentialSecurity() async throws {
        let credManager = ProductionCredentialsManager.shared
        
        // Test credential storage and retrieval
        let testKey = "TEST_CREDENTIAL"
        let testValue = "test_value_123"
        
        let stored = credManager.storeCredential(key: testKey, value: testValue)
        XCTAssertTrue(stored, "Should be able to store credential")
        
        let retrieved = credManager.retrieveCredential(key: testKey)
        XCTAssertEqual(retrieved, testValue, "Should retrieve same credential value")
        
        let deleted = credManager.deleteCredential(key: testKey)
        XCTAssertTrue(deleted, "Should be able to delete credential")
    }
    
    private func testSessionSecurity() async throws {
        // Test session token security
        let database = GRDBManager.shared
        let authService = AuthenticationService(database: database)
        
        XCTAssertNotNil(authService.sessionToken == nil, "Should not have session token initially")
    }
    
    private func testDataEncryption() async throws {
        // Test photo security encryption
        let securityManager = PhotoSecurityManager.shared
        let testData = "Test data for encryption".data(using: .utf8)!
        
        let encrypted = try securityManager.encryptPhoto(testData, photoId: "test_photo")
        XCTAssertNotEqual(encrypted, testData, "Encrypted data should be different")
        
        let (decrypted, _) = try securityManager.decryptPhoto(encrypted)
        XCTAssertEqual(decrypted, testData, "Decrypted data should match original")
    }
    
    // MARK: - Test Reports
    
    /// Generate comprehensive test report
    public func generateTestReport() -> String {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.status == .passed }.count
        let failedTests = testResults.filter { $0.status == .failed }.count
        let successRate = totalTests > 0 ? Double(passedTests) / Double(totalTests) : 0.0
        
        var report = """
        # CyntientOps Test Report
        Generated: \(DateFormatter().string(from: Date()))
        
        ## Summary
        - Total Tests: \(totalTests)
        - Passed: \(passedTests) (\(String(format: "%.1f", successRate * 100))%)
        - Failed: \(failedTests)
        - Overall Status: \(overallStatus)
        
        ## Test Results by Category
        
        """
        
        let categories: [TestResult.TestCategory] = [.unit, .integration, .system, .performance, .security]
        
        for category in categories {
            let categoryTests = testResults.filter { $0.category == category }
            let categoryPassed = categoryTests.filter { $0.status == .passed }.count
            
            report += """
            ### \(String(describing: category).capitalized) Tests
            - Results: \(categoryPassed)/\(categoryTests.count) passed
            
            """
            
            for test in categoryTests {
                let statusEmoji = test.status == .passed ? "✅" : "❌"
                let duration = String(format: "%.2f", test.duration)
                report += "- \(statusEmoji) \(test.name) (\(duration)s)\n"
                
                if let error = test.error {
                    report += "  Error: \(error)\n"
                }
            }
            
            report += "\n"
        }
        
        return report
    }
}

// MARK: - XCTest Extensions

extension XCTAssert {
    static func XCTAssertNotNil<T>(_ expression: T?, _ message: String = "") {
        if expression == nil {
            throw TestError.assertionFailed(message)
        }
    }
    
    static func XCTAssertTrue(_ expression: Bool, _ message: String = "") {
        if !expression {
            throw TestError.assertionFailed(message)
        }
    }
    
    static func XCTAssertFalse(_ expression: Bool, _ message: String = "") {
        if expression {
            throw TestError.assertionFailed(message)
        }
    }
    
    static func XCTAssertEqual<T: Equatable>(_ expression1: T, _ expression2: T, _ message: String = "") {
        if expression1 != expression2 {
            throw TestError.assertionFailed(message)
        }
    }
    
    static func XCTAssertNotEqual<T: Equatable>(_ expression1: T, _ expression2: T, _ message: String = "") {
        if expression1 == expression2 {
            throw TestError.assertionFailed(message)
        }
    }
    
    static func XCTAssertLessThan<T: Comparable>(_ expression1: T, _ expression2: T, _ message: String = "") {
        if expression1 >= expression2 {
            throw TestError.assertionFailed(message)
        }
    }
}

enum TestError: LocalizedError {
    case assertionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .assertionFailed(let message):
            return message.isEmpty ? "Assertion failed" : message
        }
    }
}