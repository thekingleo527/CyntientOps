//
//  RealDataVerification.swift
//  CyntientOps Production
//
//  Verification script to ensure all mock data has been replaced
//  with real operational data connections
//

import Foundation

@MainActor
public final class RealDataVerification {
    
    public static let shared = RealDataVerification()
    
    private init() {}
    
    // MARK: - Verification Results
    
    public struct VerificationResult {
        public let component: String
        public let isRealData: Bool
        public let dataSource: String
        public let recordCount: Int
        public let notes: String
        
        public var status: String {
            return isRealData ? "✅ REAL DATA" : "❌ MOCK DATA"
        }
    }
    
    // MARK: - Main Verification
    
    /// Run comprehensive verification of all data sources
    public func runCompleteVerification() async -> [VerificationResult] {
        print("🔍 Starting comprehensive real data verification...")
        
        var results: [VerificationResult] = []
        
        // Test Kevin's 38 tasks
        results.append(await verifyKevinTasks())
        
        // Test building data
        results.append(await verifyBuildingData())
        
        // Test worker assignments
        results.append(await verifyWorkerAssignments())
        
        // Test metric calculations
        results.append(await verifyMetricCalculations())
        
        // Test building intelligence
        results.append(await verifyBuildingIntelligence())
        
        // Test building preview popover
        results.append(await verifyBuildingPreview())
        
        // Test routine scheduling
        results.append(await verifyRoutineScheduling())
        
        // Print summary
        await printVerificationSummary(results)
        
        return results
    }
    
    // MARK: - Individual Verifications
    
    private func verifyKevinTasks() async -> VerificationResult {
        do {
            let database = GRDBManager.shared
            let kevinTasks = try await database.query("""
                SELECT COUNT(*) as task_count
                FROM tasks 
                WHERE assignee_id = '4'
                  AND DATE(scheduled_date) = DATE('now')
            """)
            
            let taskCount = kevinTasks.first?["task_count"] as? Int64 ?? 0
            
            // Also check OperationalDataManager
            let operationalData = OperationalDataManager.shared
            let todaysTasks = operationalData.getTodaysTasks(for: "4")
            
            return VerificationResult(
                component: "Kevin's Daily Tasks",
                isRealData: taskCount > 0 || todaysTasks.count > 0,
                dataSource: taskCount > 0 ? "Database" : "OperationalDataManager",
                recordCount: Int(taskCount) + todaysTasks.count,
                notes: "Kevin (ID: 4) should have 38+ tasks. Found \(taskCount) in DB, \(todaysTasks.count) in OpData"
            )
        } catch {
            return VerificationResult(
                component: "Kevin's Daily Tasks",
                isRealData: false,
                dataSource: "Error",
                recordCount: 0,
                notes: "Failed to load: \(error.localizedDescription)"
            )
        }
    }
    
    private func verifyBuildingData() async -> VerificationResult {
        do {
            let database = GRDBManager.shared
            let buildingData = try await database.query("""
                SELECT b.id, b.name, b.numberOfUnits, b.yearBuilt,
                       c.name as client_name
                FROM buildings b
                LEFT JOIN client_buildings cb ON b.id = cb.building_id
                LEFT JOIN clients c ON cb.client_id = c.id
                WHERE b.id IN ('14', '4')
            """)
            
            let rubinFound = buildingData.contains { ($0["id"] as? String) == "14" }
            let perryFound = buildingData.contains { ($0["id"] as? String) == "4" }
            
            return VerificationResult(
                component: "Building Details",
                isRealData: buildingData.count > 0 && rubinFound && perryFound,
                dataSource: "Database + Client Relations",
                recordCount: buildingData.count,
                notes: "Rubin Museum (14): \(rubinFound ? "✅" : "❌"), 131 Perry (4): \(perryFound ? "✅" : "❌")"
            )
        } catch {
            return VerificationResult(
                component: "Building Details",
                isRealData: false,
                dataSource: "Error",
                recordCount: 0,
                notes: "Database query failed: \(error.localizedDescription)"
            )
        }
    }
    
    private func verifyWorkerAssignments() async -> VerificationResult {
        do {
            let database = GRDBManager.shared
            let assignments = try await database.query("""
                SELECT wba.*, w.name, w.role
                FROM worker_building_assignments wba
                JOIN workers w ON wba.worker_id = w.id
                WHERE wba.is_active = 1
            """)
            
            let kevinAssignments = assignments.filter { ($0["worker_id"] as? String) == "4" }
            
            return VerificationResult(
                component: "Worker-Building Assignments",
                isRealData: assignments.count > 0,
                dataSource: "Database Relations",
                recordCount: assignments.count,
                notes: "Kevin has \(kevinAssignments.count) active building assignments"
            )
        } catch {
            return VerificationResult(
                component: "Worker-Building Assignments",
                isRealData: false,
                dataSource: "Error",
                recordCount: 0,
                notes: "Assignment query failed: \(error.localizedDescription)"
            )
        }
    }
    
    private func verifyMetricCalculations() async -> VerificationResult {
        do {
            let metricsService = BuildingMetricsService.shared
            let rubinMetrics = try await metricsService.calculateMetrics(for: "14")
            let perryMetrics = try await metricsService.calculateMetrics(for: "4")
            
            let hasRealMetrics = rubinMetrics.totalTasks > 0 || perryMetrics.totalTasks > 0
            
            return VerificationResult(
                component: "Building Metrics",
                isRealData: hasRealMetrics,
                dataSource: "BuildingMetricsService",
                recordCount: rubinMetrics.totalTasks + perryMetrics.totalTasks,
                notes: "Rubin: \(rubinMetrics.totalTasks) tasks, Perry: \(perryMetrics.totalTasks) tasks"
            )
        } catch {
            return VerificationResult(
                component: "Building Metrics",
                isRealData: false,
                dataSource: "Service Error",
                recordCount: 0,
                notes: "Metrics calculation failed: \(error.localizedDescription)"
            )
        }
    }
    
    private func verifyBuildingIntelligence() async -> VerificationResult {
        let operationalData = OperationalDataManager.shared
        let buildings = operationalData.buildings
        
        let rubinBuilding = buildings.first { $0.id == "14" }
        let perryBuilding = buildings.first { $0.id == "4" }
        
        return VerificationResult(
            component: "Building Intelligence",
            isRealData: rubinBuilding != nil && perryBuilding != nil,
            dataSource: "OperationalDataManager",
            recordCount: buildings.count,
            notes: "Total buildings: \(buildings.count), Key buildings found: \(rubinBuilding != nil && perryBuilding != nil)"
        )
    }
    
    private func verifyBuildingPreview() async -> VerificationResult {
        let contextEngine = WorkerContextEngine.shared
        let todaysTasks = contextEngine.getTodaysTasks()
        
        let rubinTasks = todaysTasks.filter { $0.buildingId == "14" }
        let perryTasks = todaysTasks.filter { $0.buildingId == "4" }
        
        return VerificationResult(
            component: "Building Preview Popover",
            isRealData: todaysTasks.count > 0,
            dataSource: "WorkerContextEngine",
            recordCount: todaysTasks.count,
            notes: "Rubin tasks: \(rubinTasks.count), Perry tasks: \(perryTasks.count)"
        )
    }
    
    private func verifyRoutineScheduling() async -> VerificationResult {
        do {
            let database = GRDBManager.shared
            let routineData = try await database.query("""
                SELECT t.*, w.name as worker_name, tt.name as template_name
                FROM tasks t
                LEFT JOIN workers w ON t.assignee_id = w.id
                LEFT JOIN task_templates tt ON t.template_id = tt.id
                WHERE DATE(t.scheduled_date) = DATE('now')
                ORDER BY t.scheduled_date ASC
                LIMIT 100
            """)
            
            let hasScheduledRoutines = routineData.count > 0
            
            return VerificationResult(
                component: "Routine Scheduling",
                isRealData: hasScheduledRoutines,
                dataSource: "Database + Task Templates",
                recordCount: routineData.count,
                notes: "Found \(routineData.count) scheduled routines for today"
            )
        } catch {
            return VerificationResult(
                component: "Routine Scheduling",
                isRealData: false,
                dataSource: "Database Error",
                recordCount: 0,
                notes: "Routine query failed: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Summary Report
    
    private func printVerificationSummary(_ results: [VerificationResult]) async {
        print("\n" + "="*60)
        print("🎯 REAL DATA VERIFICATION SUMMARY")
        print("="*60)
        
        let realDataCount = results.filter { $0.isRealData }.count
        let totalComponents = results.count
        let percentage = Double(realDataCount) / Double(totalComponents) * 100
        
        print("📊 Overall Status: \(String(format: "%.1f", percentage))% Real Data")
        print("✅ Real Data Components: \(realDataCount)/\(totalComponents)")
        print("")
        
        for result in results {
            print("\(result.status) - \(result.component)")
            print("   Source: \(result.dataSource)")
            print("   Records: \(result.recordCount)")
            print("   Notes: \(result.notes)")
            print("")
        }
        
        if percentage >= 95.0 {
            print("🎉 EXCELLENT: Production ready with real data!")
        } else if percentage >= 80.0 {
            print("✅ GOOD: Minor mock data cleanup needed")
        } else {
            print("⚠️ WARNING: Significant mock data remains")
        }
        
        print("="*60)
    }
}

// MARK: - String Extension

private extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}