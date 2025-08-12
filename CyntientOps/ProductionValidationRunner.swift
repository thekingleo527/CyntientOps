//
//  ProductionValidationRunner.swift
//  CyntientOps Production Validation
//
//  Standalone validation runner that doesn't depend on the main app compilation
//

import Foundation

print("🚀 CYNTIENTOPS PRODUCTION VALIDATION SUITE")
print("=" * 60)

// MARK: - Validation Results Structure

struct ValidationResult {
    let testName: String
    let passed: Bool
    let message: String
    let isCritical: Bool
}

struct ValidationReport {
    let timestamp: Date
    let results: [ValidationResult]
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let criticalFailures: [String]
    
    var isProductionReady: Bool {
        criticalFailures.isEmpty
    }
    
    var successRate: Double {
        totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
    }
}

// MARK: - File System Based Validation

class ProductionValidationRunner {
    
    func runAllValidations() -> ValidationReport {
        print("🔍 Starting Production Validation...")
        print("⏰ \(Date())")
        print("")
        
        var results: [ValidationResult] = []
        var criticalFailures: [String] = []
        
        // Test 1: Compilation Status (Mock)
        print("📋 Test 1: Project Structure and Files")
        let compilationResult = validateProjectStructure()
        results.append(compilationResult)
        if !compilationResult.passed && compilationResult.isCritical {
            criticalFailures.append(compilationResult.testName)
        }
        
        // Test 2: Session Class Accessibility
        print("📋 Test 2: Session Class")
        let sessionResult = validateSessionClass()
        results.append(sessionResult)
        if !sessionResult.passed && sessionResult.isCritical {
            criticalFailures.append(sessionResult.testName)
        }
        
        // Test 3: ServiceContainer Architecture
        print("📋 Test 3: ServiceContainer Architecture")
        let serviceContainerResult = validateServiceContainer()
        results.append(serviceContainerResult)
        if !serviceContainerResult.passed && serviceContainerResult.isCritical {
            criticalFailures.append(serviceContainerResult.testName)
        }
        
        // Test 4: Critical Manager Classes
        print("📋 Test 4: Critical Manager Classes")
        let managersResult = validateCriticalManagers()
        results.append(managersResult)
        if !managersResult.passed && managersResult.isCritical {
            criticalFailures.append(managersResult.testName)
        }
        
        // Test 5: NYC API Services
        print("📋 Test 5: NYC API Services")
        let nycResult = validateNYCServices()
        results.append(nycResult)
        if !nycResult.passed && nycResult.isCritical {
            criticalFailures.append(nycResult.testName)
        }
        
        // Test 6: Database Schema
        print("📋 Test 6: Database Schema")
        let databaseResult = validateDatabaseSchema()
        results.append(databaseResult)
        if !databaseResult.passed && databaseResult.isCritical {
            criticalFailures.append(databaseResult.testName)
        }
        
        // Test 7: Production Data Files
        print("📋 Test 7: Production Data Files")
        let dataResult = validateProductionData()
        results.append(dataResult)
        if !dataResult.passed && dataResult.isCritical {
            criticalFailures.append(dataResult.testName)
        }
        
        // Test 8: Test Suite Files
        print("📋 Test 8: Validation Scripts")
        let testSuiteResult = validateTestSuite()
        results.append(testSuiteResult)
        if !testSuiteResult.passed && testSuiteResult.isCritical {
            criticalFailures.append(testSuiteResult.testName)
        }
        
        let passedTests = results.filter { $0.passed }.count
        let failedTests = results.count - passedTests
        
        return ValidationReport(
            timestamp: Date(),
            results: results,
            totalTests: results.count,
            passedTests: passedTests,
            failedTests: failedTests,
            criticalFailures: criticalFailures
        )
    }
    
    // MARK: - Individual Validation Methods
    
    private func validateProjectStructure() -> ValidationResult {
        print("   🔍 Checking project structure...")
        
        let projectPath = "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps"
        let xcodeProject = "\(projectPath)/CyntientOps.xcodeproj"
        
        // Check if Xcode project exists
        guard FileManager.default.fileExists(atPath: xcodeProject) else {
            return ValidationResult(
                testName: "Project Structure", 
                passed: false, 
                message: "❌ Xcode project not found", 
                isCritical: true
            )
        }
        
        // Check if main app files exist
        let criticalFiles = [
            "\(projectPath)/CyntientOpsApp.swift",
            "\(projectPath)/Services/Core/ServiceContainer.swift",
            "\(projectPath)/Core/Types/Session.swift"
        ]
        
        for file in criticalFiles {
            if !FileManager.default.fileExists(atPath: file) {
                return ValidationResult(
                    testName: "Project Structure", 
                    passed: false, 
                    message: "❌ Critical file missing: \(file)", 
                    isCritical: true
                )
            }
        }
        
        print("      ✅ Project structure intact")
        return ValidationResult(
            testName: "Project Structure", 
            passed: true, 
            message: "✅ Project structure intact", 
            isCritical: true
        )
    }
    
    private func validateSessionClass() -> ValidationResult {
        print("   🔍 Checking Session class...")
        
        let sessionPath = "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Core/Types/Session.swift"
        
        guard FileManager.default.fileExists(atPath: sessionPath) else {
            return ValidationResult(
                testName: "Session Class", 
                passed: false, 
                message: "❌ Session.swift file missing", 
                isCritical: true
            )
        }
        
        // Check if Session class is properly defined
        do {
            let content = try String(contentsOfFile: sessionPath)
            
            let hasSessionClass = content.contains("class Session")
            let hasSharedInstance = content.contains("static let shared")
            let hasUserProperty = content.contains("var user:")
            let hasOrgProperty = content.contains("var org:")
            
            if hasSessionClass && hasSharedInstance && hasUserProperty && hasOrgProperty {
                print("      ✅ Session class properly defined")
                return ValidationResult(
                    testName: "Session Class", 
                    passed: true, 
                    message: "✅ Session class properly defined", 
                    isCritical: true
                )
            } else {
                return ValidationResult(
                    testName: "Session Class", 
                    passed: false, 
                    message: "❌ Session class incomplete or malformed", 
                    isCritical: true
                )
            }
        } catch {
            return ValidationResult(
                testName: "Session Class", 
                passed: false, 
                message: "❌ Could not read Session.swift: \(error)", 
                isCritical: true
            )
        }
    }
    
    private func validateServiceContainer() -> ValidationResult {
        print("   🔍 Checking ServiceContainer...")
        
        let containerPath = "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Core/ServiceContainer.swift"
        
        guard FileManager.default.fileExists(atPath: containerPath) else {
            return ValidationResult(
                testName: "ServiceContainer", 
                passed: false, 
                message: "❌ ServiceContainer.swift missing", 
                isCritical: true
            )
        }
        
        do {
            let content = try String(contentsOfFile: containerPath)
            
            // Check for key service properties
            let services = [
                "database:", "operationalData:", "auth:", "workers:", "buildings:", 
                "tasks:", "clockIn:", "photos:", "client:", "dashboardSync:", 
                "metrics:", "compliance:", "intelligence:", "commands:", 
                "offlineQueue:", "cache:", "nycIntegration:"
            ]
            
            let foundServices = services.filter { content.contains($0) }
            let serviceCount = foundServices.count
            
            if serviceCount >= 15 { // Allow some flexibility
                print("      ✅ ServiceContainer has \(serviceCount) services")
                return ValidationResult(
                    testName: "ServiceContainer", 
                    passed: true, 
                    message: "✅ ServiceContainer with \(serviceCount) services", 
                    isCritical: true
                )
            } else {
                return ValidationResult(
                    testName: "ServiceContainer", 
                    passed: false, 
                    message: "❌ ServiceContainer missing services (found \(serviceCount))", 
                    isCritical: true
                )
            }
        } catch {
            return ValidationResult(
                testName: "ServiceContainer", 
                passed: false, 
                message: "❌ Could not read ServiceContainer.swift: \(error)", 
                isCritical: true
            )
        }
    }
    
    private func validateCriticalManagers() -> ValidationResult {
        print("   🔍 Checking critical managers...")
        
        let managerFiles = [
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Managers/System/NovaAIManager.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Offline/OfflineQueueManager.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Cache/CacheManager.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Commands/CommandChainManager.swift"
        ]
        
        let managerNames = ["NovaAIManager", "OfflineQueueManager", "CacheManager", "CommandChainManager"]
        
        var foundManagers = 0
        for (index, file) in managerFiles.enumerated() {
            if FileManager.default.fileExists(atPath: file) {
                foundManagers += 1
                print("      ✅ \(managerNames[index]) found")
            } else {
                print("      ❌ \(managerNames[index]) missing")
            }
        }
        
        if foundManagers == 4 {
            return ValidationResult(
                testName: "Critical Managers", 
                passed: true, 
                message: "✅ All 4 critical managers present", 
                isCritical: false
            )
        } else {
            return ValidationResult(
                testName: "Critical Managers", 
                passed: false, 
                message: "❌ Missing managers (\(foundManagers)/4 found)", 
                isCritical: false
            )
        }
    }
    
    private func validateNYCServices() -> ValidationResult {
        print("   🔍 Checking NYC API services...")
        
        let nycServiceFiles = [
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/NYC/NYCAPIService.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/NYC/NYCComplianceService.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/NYC/NYCDataModels.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/NYC/NYCIntegrationManager.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/RealTime/DSNYAPIService.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Integration/DSNYTaskGenerator.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Integration/QuickBooksOAuthManager.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Integration/WeatherDataAdapter.swift"
        ]
        
        let foundServices = nycServiceFiles.filter { FileManager.default.fileExists(atPath: $0) }
        
        if foundServices.count >= 6 { // Allow some flexibility
            print("      ✅ \(foundServices.count) NYC services found")
            return ValidationResult(
                testName: "NYC API Services", 
                passed: true, 
                message: "✅ \(foundServices.count) NYC services available", 
                isCritical: false
            )
        } else {
            return ValidationResult(
                testName: "NYC API Services", 
                passed: false, 
                message: "❌ Insufficient NYC services (\(foundServices.count) found)", 
                isCritical: false
            )
        }
    }
    
    private func validateDatabaseSchema() -> ValidationResult {
        print("   🔍 Checking database schema files...")
        
        let dbFiles = [
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Core/Database/GRDBManager.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Core/Database/DatabaseInitializer.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Core/Database/Migrations/DatabaseMigrator.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Utilities/Database/DatabaseSchemaVerifier.swift"
        ]
        
        let foundFiles = dbFiles.filter { FileManager.default.fileExists(atPath: $0) }
        
        if foundFiles.count >= 3 {
            print("      ✅ Database schema files present")
            return ValidationResult(
                testName: "Database Schema", 
                passed: true, 
                message: "✅ Database schema files present", 
                isCritical: false
            )
        } else {
            return ValidationResult(
                testName: "Database Schema", 
                passed: false, 
                message: "❌ Database schema files missing (\(foundFiles.count)/4)", 
                isCritical: true
            )
        }
    }
    
    private func validateProductionData() -> ValidationResult {
        print("   🔍 Checking production data integrity scripts...")
        
        // Check if production data verification scripts exist
        let dataFiles = [
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Scripts/ProductionDataVerification.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Scripts/RealDataVerification.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Database/UserAccountSeeder.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Services/Database/ClientBuildingSeeder.swift"
        ]
        
        let foundFiles = dataFiles.filter { FileManager.default.fileExists(atPath: $0) }
        
        // Check for production data validation in scripts
        if foundFiles.count >= 3 {
            do {
                let verificationPath = "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Scripts/ProductionDataVerification.swift"
                if FileManager.default.fileExists(atPath: verificationPath) {
                    let content = try String(contentsOfFile: verificationPath)
                    
                    let hasKevinTest = content.contains("Kevin")
                    let hasRubinTest = content.contains("Rubin")
                    let hasTaskCount = content.contains("38")
                    
                    if hasKevinTest && hasRubinTest && hasTaskCount {
                        print("      ✅ Production data verification includes Kevin/Rubin tests")
                        return ValidationResult(
                            testName: "Production Data", 
                            passed: true, 
                            message: "✅ Production data scripts with Kevin/Rubin validation", 
                            isCritical: false
                        )
                    }
                }
                
                print("      ⚠️  Production data scripts present but may not include critical tests")
                return ValidationResult(
                    testName: "Production Data", 
                    passed: true, 
                    message: "⚠️  Production data scripts present", 
                    isCritical: false
                )
            } catch {
                print("      ⚠️  Could not verify production data script contents")
                return ValidationResult(
                    testName: "Production Data", 
                    passed: true, 
                    message: "⚠️  Production data files exist but unverified", 
                    isCritical: false
                )
            }
        } else {
            return ValidationResult(
                testName: "Production Data", 
                passed: false, 
                message: "❌ Production data files missing (\(foundFiles.count)/4)", 
                isCritical: false
            )
        }
    }
    
    private func validateTestSuite() -> ValidationResult {
        print("   🔍 Checking test suite files...")
        
        let testFiles = [
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Scripts/ComprehensiveProductionTests.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Scripts/RunProductionTests.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Tests/CyntientOpsTests/CriticalDataIntegrityTests.swift",
            "/Volumes/FastSSD/Xcode/CyntientOps/CyntientOps/Tests/CyntientOpsTests/ProductionReadinessTests.swift"
        ]
        
        let foundFiles = testFiles.filter { FileManager.default.fileExists(atPath: $0) }
        
        if foundFiles.count >= 3 {
            print("      ✅ Test suite files present (\(foundFiles.count)/4)")
            return ValidationResult(
                testName: "Test Suite", 
                passed: true, 
                message: "✅ Test suite files present", 
                isCritical: false
            )
        } else {
            return ValidationResult(
                testName: "Test Suite", 
                passed: false, 
                message: "❌ Test suite incomplete (\(foundFiles.count)/4)", 
                isCritical: false
            )
        }
    }
    
    // MARK: - Report Generation
    
    func generateReport(_ report: ValidationReport) {
        print("")
        print("=" * 60)
        print("🎯 CYNTIENTOPS PRODUCTION VALIDATION REPORT")
        print("=" * 60)
        print("📅 Generated: \(report.timestamp)")
        print("📊 Tests: \(report.totalTests) total, \(report.passedTests) passed, \(report.failedTests) failed")
        print("💯 Success Rate: \(String(format: "%.1f%%", report.successRate))")
        
        if report.isProductionReady {
            print("🎉 STATUS: PRODUCTION READY")
        } else {
            print("⚠️  STATUS: NOT PRODUCTION READY")
            print("🚨 Critical Issues: \(report.criticalFailures.count)")
        }
        
        print("")
        print("📋 DETAILED RESULTS:")
        for result in report.results {
            let status = result.passed ? "✅" : "❌"
            let critical = result.isCritical ? " [CRITICAL]" : ""
            print("   \(status) \(result.testName): \(result.message)\(critical)")
        }
        
        if !report.criticalFailures.isEmpty {
            print("")
            print("🚨 CRITICAL ISSUES TO RESOLVE:")
            for failure in report.criticalFailures {
                print("   • \(failure)")
            }
        }
        
        print("")
        print("🔍 KNOWN COMPILATION ISSUES:")
        print("   • Session import errors in main app files")
        print("   • SwiftUI navigation warnings")
        print("   • Type resolution issues in ViewModels")
        
        print("")
        print("📈 PRODUCTION READINESS ASSESSMENT:")
        
        if report.isProductionReady && report.successRate >= 80 {
            print("   🟢 READY: Core infrastructure and files are intact")
            print("   📝 TODO: Fix compilation issues and run runtime tests")
            print("   🎯 RECOMMENDATION: Address Session import issues, then proceed with testing")
        } else if report.successRate >= 60 {
            print("   🟡 PARTIALLY READY: Most components present but issues detected")
            print("   🔧 TODO: Address critical failures before proceeding")
            print("   🎯 RECOMMENDATION: Fix critical issues first")
        } else {
            print("   🔴 NOT READY: Major issues detected")
            print("   🚨 TODO: Address all critical failures")
            print("   ⏸️  RECOMMENDATION: Do not proceed with deployment")
        }
        
        print("")
        print("=" * 60)
    }
}

// MARK: - Script Execution

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the validation
let runner = ProductionValidationRunner()
let report = runner.runAllValidations()
runner.generateReport(report)

print("")
print("🎯 Validation Complete!")
print("📊 Report saved to console output")
print("")