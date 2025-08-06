//
//  BuildingMetricsService.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: All compilation errors resolved for cross-dashboard integration
//  ✅ CORRECTED: CoreTypes.BuildingMetrics constructor parameters
//  ✅ ALIGNED: With current GRDB implementation and existing CoreTypes
//  ✅ OPTIMIZED: Actor pattern with proper async/await and Combine integration
//  ✅ INTEGRATION: Ready for Worker, Admin, and Client dashboards
//

import Foundation
import GRDB
import Combine

// MARK: - BuildingMetricsService Actor

public actor BuildingMetricsService {
    public static let shared = BuildingMetricsService()
    
    // MARK: - Cross-Dashboard Integration
    
    /// Initialize the service for cross-dashboard integration
    /// Call this during app startup to ensure proper integration across Worker, Admin, and Client dashboards
    ///
    /// Usage across dashboards:
    /// - Worker Dashboard: Use calculateMetrics(for:) for individual building metrics
    /// - Admin Dashboard: Use calculateBatchMetrics(for:) for portfolio-wide analytics
    /// - Client Dashboard: Use observeMetrics(for:) for real-time executive insights
    public static func initializeForCrossDashboardIntegration() async {
        await shared.initialize()
    }
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    
    // MARK: - Cache Management
    private var metricsCache: [String: CachedMetrics] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Real-time Observations
    private var cancellables = Set<AnyCancellable>()
    private var observationSubscriptions: [String: AnyPublisher<CoreTypes.BuildingMetrics, Error>] = [:]
    
    private struct CachedMetrics {
        let metrics: CoreTypes.BuildingMetrics
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }
    
    private init() {
        // ✅ FIXED: Use proper actor initialization pattern
        // Don't call async methods in init - use separate initialize() method
    }
    
    // MARK: - Initialization
    
    /// Initialize the service with real-time observations
    public func initialize() async {
        // ✅ FIXED: Remove await since setupRealTimeObservations is not async
        setupRealTimeObservations()
        print("📊 BuildingMetricsService initialized")
    }
    
    // MARK: - Public Interface
    
    /// Calculate comprehensive building metrics for PropertyCard (single building)
    public func calculateMetrics(for buildingId: String) async throws -> CoreTypes.BuildingMetrics {
        // Check cache first
        if let cached = metricsCache[buildingId], !cached.isExpired {
            print("📊 Using cached metrics for building: \(buildingId)")
            return cached.metrics
        }
        
        // Calculate fresh metrics from REAL GRDB data
        let metrics = try await performRealMetricsCalculation(buildingId: buildingId)
        
        // Update cache
        metricsCache[buildingId] = CachedMetrics(metrics: metrics, timestamp: Date())
        
        
        // Notify other dashboards
        await MainActor.run {
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: "",
                data: ["metricsUpdated": "true"]
            )
            DashboardSyncService.shared.broadcastAdminUpdate(update)
        }
        return metrics
    }
    
    /// Batch calculate metrics for multiple buildings (concurrent with GRDB)
    public func calculateBatchMetrics(for buildingIds: [String]) async throws -> [String: CoreTypes.BuildingMetrics] {
        var results: [String: CoreTypes.BuildingMetrics] = [:]
        
        print("📊 Calculating metrics for \(buildingIds.count) buildings concurrently")
        
        // Use TaskGroup for concurrent GRDB queries
        await withTaskGroup(of: (String, CoreTypes.BuildingMetrics?).self) { group in
            for buildingId in buildingIds {
                group.addTask {
                    do {
                        let metrics = try await self.calculateMetrics(for: buildingId)
                        return (buildingId, metrics)
                    } catch {
                        print("⚠️ Failed to calculate metrics for building \(buildingId): \(error)")
                        return (buildingId, nil)
                    }
                }
            }
            
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    results[buildingId] = metrics
                }
            }
        }
        
        print("✅ Calculated metrics for \(results.count) buildings")
        return results
    }
    
    /// Get real-time metrics observation for a building (using existing GRDBManager methods)
    public func observeMetrics(for buildingId: String) -> AnyPublisher<CoreTypes.BuildingMetrics, Error> {
        // Return cached observation if available
        if let existing = observationSubscriptions[buildingId] {
            return existing
        }
        
        print("🔄 Setting up real-time observation for building: \(buildingId)")
        
        // ✅ FIXED: Use proper Combine pattern with existing GRDBManager methods
        let observation = grdbManager.observeTasks(for: buildingId)
            .map { [weak self] tasks in
                // Convert synchronously to avoid async issues in Combine
                self?.convertTasksToMetricsSync(tasks, buildingId: buildingId) ?? CoreTypes.BuildingMetrics.empty
            }
            .eraseToAnyPublisher()
        
        // Cache the observation
        observationSubscriptions[buildingId] = observation
        
        return observation
    }
    
    /// Invalidate cache for a building (trigger on task completion)
    public func invalidateCache(for buildingId: String) {
        print("🗑️ Invalidating cache for building: \(buildingId)")
        metricsCache.removeValue(forKey: buildingId)
        observationSubscriptions.removeValue(forKey: buildingId)
    }
    
    /// Invalidate all caches (trigger on major data changes)
    public func invalidateAllCaches() {
        print("🗑️ Invalidating all building metrics caches")
        metricsCache.removeAll()
        observationSubscriptions.removeAll()
    }
    
    // MARK: - Real Data Calculation (GRDB)
    
    private func performRealMetricsCalculation(buildingId: String) async throws -> CoreTypes.BuildingMetrics {
        print("📊 Calculating REAL metrics for building: \(buildingId) with GRDB")
        
        // 1. Get today's tasks for the building using GRDB
        let taskRows = try await grdbManager.query("""
            SELECT 
                t.*,
                w.name as worker_name, 
                w.id as worker_id,
                w.isActive as worker_active
            FROM routine_tasks t
            LEFT JOIN workers w ON t.workerId = w.id
            WHERE t.buildingId = ? AND date(t.scheduledDate) = date('now')
            ORDER BY t.scheduledDate
        """, [buildingId])
        
        // 2. Calculate task metrics from real GRDB data
        let totalTasks = taskRows.count
        let completedTasks = taskRows.filter { ($0["isCompleted"] as? Int64 ?? 0) > 0 }.count
        
        // Calculate overdue tasks
        let currentTime = Date()
        let dateFormatter = ISO8601DateFormatter()
        
        let overdueTasks = taskRows.filter { row in
            let isCompleted = (row["isCompleted"] as? Int64 ?? 0) > 0
            guard !isCompleted else { return false }
            
            if let dueDateString = row["dueDate"] as? String,
               let dueDate = dateFormatter.date(from: dueDateString) {
                return dueDate < currentTime
            }
            
            // If no due date, check if scheduled for earlier today
            if let scheduledString = row["scheduledDate"] as? String,
               let scheduledDate = dateFormatter.date(from: scheduledString) {
                let calendar = Calendar.current
                let now = Date()
                if calendar.isDate(scheduledDate, inSameDayAs: now) {
                    return scheduledDate < now
                }
            }
            
            return false
        }.count
        
        let pendingTasks = totalTasks - completedTasks
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 1.0
        
        // 3. Get active workers for building using GRDB
        let workerRows = try await grdbManager.query("""
            SELECT DISTINCT w.*
            FROM workers w
            JOIN worker_assignments wa ON w.id = wa.worker_id
            WHERE wa.building_id = ? AND w.isActive = 1 AND wa.is_active = 1
        """, [buildingId])
        
        let activeWorkerCount = workerRows.count
        
        // 4. Check for workers currently on site (clocked in)
        let clockedInRows = try await grdbManager.query("""
            SELECT COUNT(*) as count
            FROM worker_time_logs wtl
            JOIN worker_assignments wa ON wtl.workerId = wa.worker_id
            WHERE wa.building_id = ? AND wtl.clockOutTime IS NULL
            AND date(wtl.clockInTime) = date('now')
        """, [buildingId])
        
        let hasWorkerOnSite = (clockedInRows.first?["count"] as? Int64 ?? 0) > 0
        
        // 5. Calculate compliance (no overdue tasks = compliant)
        let isCompliant = overdueTasks == 0
        
        // 6. Calculate overall score (weighted average)
        let completionScore = completionRate * 60  // 60% weight
        let complianceScore = isCompliant ? 30.0 : 0.0  // 30% weight
        let workerScore = activeWorkerCount > 0 ? 10.0 : 0.0  // 10% weight
        let overallScore = completionScore + complianceScore + workerScore
        
        // 7. Calculate additional enhanced metrics
        let maintenanceEfficiency = try await calculateMaintenanceEfficiency(buildingId: buildingId)
        let lastActivityTime = try await getLastActivityTime(buildingId: buildingId)
        let urgentTasksCount = try await getUrgentTasksCount(buildingId: buildingId)
        let weeklyCompletionTrend = try await getWeeklyCompletionTrend(buildingId: buildingId)
        
        // ✅ FIXED: Use correct CoreTypes.BuildingMetrics constructor with all required parameters
        let metrics = CoreTypes.BuildingMetrics(
            id: UUID().uuidString,
            buildingId: buildingId,
            completionRate: completionRate,
            averageTaskTime: 3600, // 1 hour default
            overdueTasks: overdueTasks,
            totalTasks: totalTasks, // ✅ FIXED: Added missing totalTasks parameter
            activeWorkers: activeWorkerCount,
            isCompliant: isCompliant,
            overallScore: overallScore, // ✅ FIXED: Already Double, no conversion needed
            lastUpdated: lastActivityTime ?? Date(), // ✅ FIXED: Changed from lastActivityDate to lastUpdated
            pendingTasks: pendingTasks,
            urgentTasksCount: urgentTasksCount,
            hasWorkerOnSite: hasWorkerOnSite,
            maintenanceEfficiency: maintenanceEfficiency,
            weeklyCompletionTrend: weeklyCompletionTrend
        )
        
        print("✅ GRDB Metrics calculated - Building: \(buildingId), Score: \(Int(overallScore)), Completion: \(Int(completionRate * 100))%")
        
        
        // Notify other dashboards
        await MainActor.run {
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: "",
                data: ["metricsUpdated": "true"]
            )
            DashboardSyncService.shared.broadcastAdminUpdate(update)
        }
        return metrics
    }
    
    // MARK: - Enhanced Metrics Calculations (GRDB)
    
    private func calculateMaintenanceEfficiency(buildingId: String) async throws -> Double {
        let efficiencyRows = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total_tasks,
                SUM(CASE WHEN isCompleted = 1 AND dueDate >= scheduledDate THEN 1 ELSE 0 END) as on_time_tasks
            FROM routine_tasks
            WHERE buildingId = ? AND category = 'maintenance'
              AND date(scheduledDate) >= date('now', '-30 days')
        """, [buildingId])
        
        guard let row = efficiencyRows.first,
              let total = row["total_tasks"] as? Int64,
              let onTime = row["on_time_tasks"] as? Int64,
              total > 0 else { return 0.85 } // Default efficiency
        
        return Double(onTime) / Double(total)
    }
    
    private func getLastActivityTime(buildingId: String) async throws -> Date? {
        let activityRows = try await grdbManager.query("""
            SELECT MAX(
                CASE 
                    WHEN completedDate IS NOT NULL THEN completedDate
                    ELSE scheduledDate
                END
            ) as last_activity
            FROM routine_tasks
            WHERE buildingId = ?
        """, [buildingId])
        
        guard let lastActivityString = activityRows.first?["last_activity"] as? String else { return nil }
        
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastActivityString)
    }
    
    private func getUrgentTasksCount(buildingId: String) async throws -> Int {
        let urgentRows = try await grdbManager.query("""
            SELECT COUNT(*) as count
            FROM routine_tasks
            WHERE buildingId = ? AND urgency IN ('high', 'critical', 'urgent') 
              AND isCompleted = 0 AND date(scheduledDate) = date('now')
        """, [buildingId])
        
        return Int(urgentRows.first?["count"] as? Int64 ?? 0)
    }
    
    private func getWeeklyCompletionTrend(buildingId: String) async throws -> Double {
        let trendRows = try await grdbManager.query("""
            SELECT 
                AVG(daily_completion) as avg_completion
            FROM (
                SELECT 
                    date(scheduledDate) as day,
                    CAST(SUM(isCompleted) AS REAL) / COUNT(*) as daily_completion
                FROM routine_tasks
                WHERE buildingId = ? AND date(scheduledDate) >= date('now', '-7 days')
                GROUP BY date(scheduledDate)
            )
        """, [buildingId])
        
        return trendRows.first?["avg_completion"] as? Double ?? 0.0
    }
    
    // MARK: - Real-time Observations Setup
    
    private func setupRealTimeObservations() {
        print("🔄 Setting up GRDB real-time observations for building metrics")
        
        // ✅ FIXED: Use standard Task syntax for periodic refresh
        Task { [weak self] in
            while true {
                do {
                    try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                    guard let self = self else { break }
                    await self.invalidateAllCaches()
                    print("🔄 Periodic cache invalidation completed")
                } catch {
                    break // Exit if task is cancelled
                }
            }
        }
        
        // ✅ FIXED: Set up additional periodic refresh for building metrics
        Task { [weak self] in
            while true {
                do {
                    try await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                    guard let self = self else { break }
                    await self.invalidateAllCaches()
                    print("🔄 Periodic building metrics refresh")
                } catch {
                    break // Exit if task is cancelled
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // ✅ FIXED: Made this method synchronous and nonisolated to work with Combine publishers across all dashboards
    nonisolated private func convertTasksToMetricsSync(_ tasks: [ContextualTask], buildingId: String) -> CoreTypes.BuildingMetrics {
        // Convert ContextualTask array to metrics (for real-time observation)
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 1.0
        
        // Count urgent tasks
        let urgentTasks = tasks.filter { task in
            if let urgency = task.urgency {
                return urgency == .high || urgency == .critical || urgency == .urgent
            }
            return false
        }.count
        
        // Count overdue tasks
        let overdueTasks = tasks.filter { task in
            !task.isCompleted && (task.dueDate ?? Date.distantFuture) < Date()
        }.count
        
        // Get unique workers - use worker property if available
        let uniqueWorkers = Set(tasks.compactMap { task in
            task.worker?.id
        }).count
        
        // ✅ FIXED: Use correct CoreTypes.BuildingMetrics constructor with proper parameter order
        return CoreTypes.BuildingMetrics(
            id: UUID().uuidString,
            buildingId: buildingId,
            completionRate: completionRate,
            averageTaskTime: 3600, // 1 hour default
            overdueTasks: overdueTasks,
            totalTasks: totalTasks, // ✅ FIXED: Added missing totalTasks parameter
            activeWorkers: uniqueWorkers,
            isCompliant: overdueTasks == 0,
            overallScore: completionRate * 100, // ✅ FIXED: Convert to Double
            lastUpdated: Date(),
            pendingTasks: totalTasks - completedTasks,
            urgentTasksCount: urgentTasks,
            hasWorkerOnSite: uniqueWorkers > 0,
            maintenanceEfficiency: 0.85,
            weeklyCompletionTrend: completionRate
        )
    }
}

// MARK: - Convenience Extensions

extension BuildingMetricsService {
    /// Convenience method for PropertyCard integration
    public func getPropertyCardMetrics(for buildingId: String) async throws -> CoreTypes.BuildingMetrics {
        return try await calculateMetrics(for: buildingId)
    }
    
    /// Batch metrics for dashboard views (uses renamed method)
    public func getDashboardMetrics(for buildingIds: [String]) async throws -> [String: CoreTypes.BuildingMetrics] {
        return try await calculateBatchMetrics(for: buildingIds)
    }
    
    /// Subscribe to real-time metrics for SwiftUI views (fixed error handling)
    public func subscribeToMetrics(for buildingId: String) -> AnyPublisher<CoreTypes.BuildingMetrics, Never> {
        return observeMetrics(for: buildingId)
            .catch { error in
                print("⚠️ Metrics observation error for building \(buildingId): \(error)")
                return Just(CoreTypes.BuildingMetrics.empty)
            }
            .eraseToAnyPublisher()
    }
    
    /// Get metrics for multiple buildings with real-time updates
    public func subscribeToMultipleMetrics(for buildingIds: [String]) -> AnyPublisher<[String: CoreTypes.BuildingMetrics], Never> {
        let publishers = buildingIds.map { buildingId in
            subscribeToMetrics(for: buildingId)
                .map { metrics in (buildingId, metrics) }
        }
        
        return Publishers.MergeMany(publishers)
            .scan([String: CoreTypes.BuildingMetrics]()) { result, update in
                var newResult = result
                newResult[update.0] = update.1
                return newResult
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Building-Specific Metrics Extensions

extension BuildingMetricsService {
    /// Get Kevin's Rubin Museum specific metrics
    public func getRubinMuseumMetrics() async throws -> CoreTypes.BuildingMetrics {
        return try await calculateMetrics(for: "14") // Rubin Museum building ID
    }
    
    /// Get Edwin's Stuyvesant Park metrics
    public func getStuyvesantParkMetrics() async throws -> CoreTypes.BuildingMetrics {
        return try await calculateMetrics(for: "15") // Stuyvesant Park building ID
    }
    
    /// Get all CyntientOps portfolio metrics
    public func getPortfolioMetrics() async throws -> [String: CoreTypes.BuildingMetrics] {
        let buildingIds = ["1", "4", "7", "8", "10", "12", "13", "14", "15", "16", "17"]
        return try await calculateBatchMetrics(for: buildingIds)
    }
}

// MARK: - Usage Instructions for Cross-Dashboard Integration
//
// To ensure proper integration across all three dashboards, call this in CyntientOpsApp.swift:
//
// @main
// struct CyntientOpsApp: App {
//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//                 .task {
//                     await BuildingMetricsService.initializeForCrossDashboardIntegration()
//                 }
//         }
//     }
// }
//
// MARK: - End of BuildingMetricsService
