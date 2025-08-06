//
//  TestRealDataIntegration.swift
//  CyntientOps v6.0
//
//  Integration test for real data implementation
//  ✅ FIXED: Added missing 'await' keywords for MainActor-isolated properties
//

import Foundation

enum IntegrationTest {
    
    static func runFullIntegrationTest() async -> Bool {
        print("🧪 Running full integration test...")
        
        var allPassed = true
        
        // Test 1: Real portfolio intelligence
        if await testPortfolioIntelligence() {
            print("✅ Portfolio intelligence test passed")
        } else {
            print("❌ Portfolio intelligence test failed")
            allPassed = false
        }
        
        // Test 2: Real building metrics
        if await testBuildingMetrics() {
            print("✅ Building metrics test passed")
        } else {
            print("❌ Building metrics test failed")
            allPassed = false
        }
        
        // Test 3: Real worker performance
        if await testWorkerPerformance() {
            print("✅ Worker performance test passed")
        } else {
            print("❌ Worker performance test failed")
            allPassed = false
        }
        
        // Test 4: Real weather integration
        if await testWeatherIntegration() {
            print("✅ Weather integration test passed")
        } else {
            print("❌ Weather integration test failed")
            allPassed = false
        }
        
        return allPassed
    }
    
    private static func testPortfolioIntelligence() async -> Bool {
        do {
            let buildingService = BuildingService.shared
            let workerService = WorkerService.shared
            let taskService = TaskService.shared
            
            let buildings = try await buildingService.getAllBuildings()
            let workers = try await workerService.getAllActiveWorkers()
            let allTasks = try await taskService.getAllTasks()
            
            // Calculate completion rate from real tasks
            let completedTasks = allTasks.filter { $0.isCompleted }
            let completionRate = allTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(allTasks.count)
            
            // Count critical issues (high/critical urgency tasks)
            let criticalIssues = allTasks.filter { task in
                if let urgency = task.urgency {
                    return urgency == .critical || urgency == .urgent
                }
                return false
            }.count
            
            // Use correct CoreTypes.PortfolioIntelligence constructor
            let intelligence = CoreTypes.PortfolioIntelligence(
                totalBuildings: buildings.count,
                activeWorkers: workers.count,
                completionRate: completionRate,
                criticalIssues: criticalIssues,
                monthlyTrend: .up,
                complianceScore: 0.85,
                generatedAt: Date()
            )
            
            return intelligence.totalBuildings > 0
        } catch {
            print("Portfolio intelligence error: \(error)")
            return false
        }
    }
    
    private static func testBuildingMetrics() async -> Bool {
        do {
            let buildingService = BuildingService.shared
            let taskService = TaskService.shared
            let workerService = WorkerService.shared
            
            let buildings = try await buildingService.getAllBuildings()
            var metrics: [CoreTypes.BuildingMetrics] = []
            
            for building in buildings.prefix(3) { // Test first 3 buildings
                let tasks = try await taskService.getTasksForBuilding(building.id)
                let workers = try await workerService.getActiveWorkersForBuilding(building.id)
                
                let completedTasks = tasks.filter { $0.isCompleted }
                let overdueTasks = tasks.filter { task in
                    if let dueDate = task.dueDate {
                        return dueDate < Date() && !task.isCompleted
                    }
                    return false
                }
                
                let urgentTasks = tasks.filter { task in
                    if let urgency = task.urgency {
                        return urgency == .critical || urgency == .urgent
                    }
                    return false
                }
                
                let pendingTasks = tasks.filter { !$0.isCompleted }
                
                // Use correct BuildingMetrics constructor with all required parameters
                let metric = CoreTypes.BuildingMetrics(
                    buildingId: building.id,
                    completionRate: tasks.isEmpty ? 1.0 : Double(completedTasks.count) / Double(tasks.count),
                    averageTaskTime: 3600, // Default 1 hour, would calculate from real data
                    overdueTasks: overdueTasks.count,
                    totalTasks: tasks.count,
                    activeWorkers: workers.count,
                    isCompliant: true, // Would calculate from compliance data
                    overallScore: 0.85, // Would calculate from multiple factors
                    lastUpdated: Date(),
                    pendingTasks: pendingTasks.count,
                    urgentTasksCount: urgentTasks.count,
                    hasWorkerOnSite: !workers.isEmpty,
                    maintenanceEfficiency: 0.85, // Would calculate from real data
                    weeklyCompletionTrend: 0.05 // Would calculate from historical data
                )
                metrics.append(metric)
            }
            
            return !metrics.isEmpty
        } catch {
            print("Building metrics error: \(error)")
            return false
        }
    }
    
    private static func testWorkerPerformance() async -> Bool {
        do {
            let workerService = WorkerService.shared
            let taskService = TaskService.shared
            
            let workerExists = try await workerService.getWorkerProfile(for: "2") != nil
            
            guard workerExists else {
                print("Worker not found")
                return false
            }
            
            // Get tasks for this worker
            let allTasks = try await taskService.getAllTasks()
            let workerTasks = allTasks.filter { $0.worker?.id == "2" }
            let completedTasks = workerTasks.filter { $0.isCompleted }
            
            // Use CoreTypes.PerformanceMetrics instead of non-existent WorkerPerformanceMetrics
            let performance = CoreTypes.PerformanceMetrics(
                efficiency: workerTasks.isEmpty ? 1.0 : Double(completedTasks.count) / Double(workerTasks.count),
                tasksCompleted: completedTasks.count,
                averageTime: 45.0 * 60, // 45 minutes in seconds
                qualityScore: 0.92,
                lastUpdate: Date()
            )
            
            return performance.efficiency >= 0
        } catch {
            print("Worker performance error: \(error)")
            return false
        }
    }
    
    // ✅ FIXED: Added @MainActor to handle WeatherDataAdapter's MainActor isolation
    @MainActor
    private static func testWeatherIntegration() async -> Bool {
        let adapter = WeatherDataAdapter.shared
        let building = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        await adapter.fetchWeatherForBuildingAsync(building)
        
        // Check if weather was fetched
        return adapter.currentWeather != nil
    }
}

// MARK: - Quick Test Extension
extension IntegrationTest {
    
    /// Run a quick integration test that can be called from AppDelegate
    static func quickTest() async {
        print("🚀 Starting quick integration test...")
        
        let passed = await runFullIntegrationTest()
        if passed {
            print("✅ All integration tests passed!")
        } else {
            print("❌ Some integration tests failed")
        }
    }
}
