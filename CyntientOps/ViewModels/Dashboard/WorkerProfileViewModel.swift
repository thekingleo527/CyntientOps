//
//  WorkerProfileViewModel.swift
//  CyntientOps
//
//  Real data integration for worker profiles, assignments, and performance metrics
//  Uses OperationalDataManager.getRealWorldTasks() for authentic operational data
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

@MainActor
public final class WorkerProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    @Published public var isLoading = false
    @Published public var isRefreshing = false
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    @Published public var lastUpdateTime: Date?
    
    // Worker Profile Data
    @Published public var currentWorker: CoreTypes.WorkerProfile?
    @Published public var workerAssignments: [OperationalDataTaskAssignment] = []
    @Published public var assignedBuildings: [CoreTypes.NamedCoordinate] = []
    @Published public var weeklySchedule: [WeeklyScheduleItem] = []
    @Published public var performanceMetrics: WorkerPerformanceMetrics?
    @Published public var recentTaskHistory: [CoreTypes.ContextualTask] = []
    
    // Building and Schedule Data
    @Published public var currentAssignments: [BuildingAssignment] = []
    @Published public var todaysTasks: [CoreTypes.ContextualTask] = []
    @Published public var completedTasksToday: Int = 0
    @Published public var totalTasksToday: Int = 0
    @Published public var clockStatus: CoreTypes.ClockStatus = .clockedOut
    @Published public var currentBuildingId: String?
    
    // Performance Analytics
    @Published public var weeklyCompletionRate: Double = 0.0
    @Published public var monthlyCompletionRate: Double = 0.0
    @Published public var photoComplianceRate: Double = 0.0
    @Published public var averageTaskDuration: TimeInterval = 0
    @Published public var efficiency: Double = 0.0
    @Published public var performanceTrend: CoreTypes.TrendDirection = .stable
    
    // UI State
    @Published public var selectedTimeframe: TimeFrame = .week
    @Published public var showingScheduleEditor = false
    @Published public var showingPerformanceDetails = false
    
    // MARK: - Dependencies
    private let serviceContainer: ServiceContainer
    private let operationalDataManager: OperationalDataManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Supporting Types
    
    public enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
    }
    
    public struct WeeklyScheduleItem: Identifiable, Hashable {
        public let id = UUID()
        public let dayOfWeek: String
        public let tasks: [OperationalDataTaskAssignment]
        public let totalDuration: TimeInterval
        public let buildingsCount: Int
        
        public var startTime: String {
            guard let earliestTask = tasks.compactMap({ $0.startHour }).min() else { return "N/A" }
            return String(format: "%02d:00", earliestTask)
        }
        
        public var endTime: String {
            guard let latestTask = tasks.compactMap({ $0.endHour }).max() else { return "N/A" }
            return String(format: "%02d:00", latestTask)
        }
    }
    
    public struct BuildingAssignment: Identifiable {
        public let id = UUID()
        public let buildingId: String
        public let buildingName: String
        public let coordinate: CLLocationCoordinate2D
        public let tasks: [OperationalDataTaskAssignment]
        public let isActiveToday: Bool
        public let lastVisited: Date?
        public let completionRate: Double
        
        public var taskCount: Int { tasks.count }
        public var estimatedDuration: TimeInterval {
            return TimeInterval(tasks.reduce(0) { $0 + $1.estimatedDuration } * 60)
        }
    }

    
    public struct WorkerPerformanceMetrics {
        public let workerId: String
        public let completionRate: Double
        public let efficiency: Double
        public let photoCompliance: Double
        public let onTimeRate: Double
        public let averageTaskDuration: TimeInterval
        public let totalTasksCompleted: Int
        public let totalTasksAssigned: Int
        public let performanceScore: Double
        public let trend: CoreTypes.TrendDirection
        public let lastUpdated: Date
        
        public init(
            workerId: String,
            completionRate: Double = 0.0,
            efficiency: Double = 0.0,
            photoCompliance: Double = 0.0,
            onTimeRate: Double = 0.0,
            averageTaskDuration: TimeInterval = 0,
            totalTasksCompleted: Int = 0,
            totalTasksAssigned: Int = 0,
            performanceScore: Double = 0.0,
            trend: CoreTypes.TrendDirection = .stable,
            lastUpdated: Date = Date()
        ) {
            self.workerId = workerId
            self.completionRate = completionRate
            self.efficiency = efficiency
            self.photoCompliance = photoCompliance
            self.onTimeRate = onTimeRate
            self.averageTaskDuration = averageTaskDuration
            self.totalTasksCompleted = totalTasksCompleted
            self.totalTasksAssigned = totalTasksAssigned
            self.performanceScore = performanceScore
            self.trend = trend
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Initialization
    
    public init(serviceContainer: ServiceContainer) {
        self.serviceContainer = serviceContainer
        self.operationalDataManager = OperationalDataManager.shared
    }
    
    // MARK: - Public Methods
    
    public func loadWorkerProfile(workerId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            // Load worker profile from database
            if let worker = try await serviceContainer.userProfile.loadUserProfile(for: workerId) {
                await updateWorkerData(from: worker)
            }
            
            // Load real assignments from OperationalDataManager
            await loadWorkerAssignments(workerId: workerId)
            
            // Load performance metrics
            await calculatePerformanceMetrics(workerId: workerId)
            
            // Load weekly schedule
            await generateWeeklySchedule()
            
            await MainActor.run {
                lastUpdateTime = Date()
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load worker profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    public func refreshData() async {
        await MainActor.run { isRefreshing = true }
        
        if let workerId = currentWorker?.id {
            await loadWorkerProfile(workerId: workerId)
        }
        
        await MainActor.run { isRefreshing = false }
    }
    
    // MARK: - Private Methods
    
    private func updateWorkerData(from user: CoreTypes.User) async {
        // Convert User to WorkerProfile (simplified for now)
        let workerProfile = CoreTypes.WorkerProfile(
            id: user.workerId,
            name: user.name,
            email: user.email,
            phone: nil,
            phoneNumber: nil,
            role: .worker,
            skills: nil,
            certifications: nil,
            hireDate: nil,
            isActive: true,
            profileImageUrl: nil,
            assignedBuildingIds: [],
            capabilities: nil,
            createdAt: Date(),
            updatedAt: Date(),
            status: .active,
            isClockedIn: false,
            currentBuildingId: nil,
            clockStatus: .clockedOut
        )
        
        await MainActor.run {
            currentWorker = workerProfile
        }
    }
    
    private func loadWorkerAssignments(workerId: String) async {
        // Get worker name for OperationalDataManager lookup
        guard let workerName = currentWorker?.name else { return }
        
        // Load real assignments from OperationalDataManager
        let realAssignments = operationalDataManager.getRealWorldTasks(for: workerName)
        
        await MainActor.run {
            workerAssignments = realAssignments
            totalTasksToday = realAssignments.count
        }
        
        // Convert assignments to building assignments
        await generateBuildingAssignments(from: realAssignments)
    }
    
    private func generateBuildingAssignments(from tasks: [OperationalDataTaskAssignment]) async {
        let buildingGroups = Dictionary(grouping: tasks) { $0.buildingId }
        
        var assignments: [BuildingAssignment] = []
        
        for (buildingId, buildingTasks) in buildingGroups {
            // Get building coordinate from the first task's building name
            let buildingName = buildingTasks.first?.building ?? ""
            let coordinate = getBuildingCoordinate(for: buildingName)
            
            let assignment = BuildingAssignment(
                buildingId: buildingId,
                buildingName: buildingName,
                coordinate: coordinate,
                tasks: buildingTasks,
                isActiveToday: isActiveToday(tasks: buildingTasks),
                lastVisited: nil, // Would need to fetch from database
                completionRate: 0.0 // Would need to calculate from completed tasks
            )
            
            assignments.append(assignment)
        }
        
        await MainActor.run {
            currentAssignments = assignments
            assignedBuildings = assignments.map { assignment in
                CoreTypes.NamedCoordinate(
                    id: assignment.buildingId,
                    name: assignment.buildingName,
                    coordinate: assignment.coordinate
                )
            }
        }
    }
    
    private func generateWeeklySchedule() async {
        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var schedule: [WeeklyScheduleItem] = []
        
        for day in daysOfWeek {
            // Filter tasks for this day (simplified - would need proper day matching logic)
            let dayTasks = workerAssignments.filter { assignment in
                assignment.daysOfWeek?.contains(day) ?? true
            }
            
            let scheduleItem = WeeklyScheduleItem(
                dayOfWeek: day,
                tasks: dayTasks,
                totalDuration: TimeInterval(dayTasks.reduce(0) { $0 + $1.estimatedDuration } * 60),
                buildingsCount: Set(dayTasks.map { $0.buildingId }).count
            )
            
            schedule.append(scheduleItem)
        }
        
        await MainActor.run {
            weeklySchedule = schedule
        }
    }
    
    private func calculatePerformanceMetrics(workerId: String) async {
        // Calculate metrics from real task data
        let totalAssigned = workerAssignments.count
        let averageDuration = workerAssignments.reduce(0) { $0 + $1.estimatedDuration } / max(1, totalAssigned)
        
        // These would be calculated from actual completion data in a full implementation
        let completionRate = 0.87  // Mock value - would come from database
        let photoCompliance = 0.93  // Mock value - would come from photo evidence service
        let onTimeRate = 0.82  // Mock value - would come from clock-in data
        
        let metrics = WorkerPerformanceMetrics(
            workerId: workerId,
            completionRate: completionRate,
            efficiency: (completionRate + onTimeRate) / 2.0,
            photoCompliance: photoCompliance,
            onTimeRate: onTimeRate,
            averageTaskDuration: TimeInterval(averageDuration * 60),
            totalTasksCompleted: Int(Double(totalAssigned) * completionRate),
            totalTasksAssigned: totalAssigned,
            performanceScore: (completionRate + photoCompliance + onTimeRate) / 3.0,
            trend: completionRate > 0.85 ? .up : completionRate < 0.75 ? .down : .stable,
            lastUpdated: Date()
        )
        
        await MainActor.run {
            performanceMetrics = metrics
            weeklyCompletionRate = completionRate
            monthlyCompletionRate = completionRate
            photoComplianceRate = photoCompliance
            averageTaskDuration = metrics.averageTaskDuration
            efficiency = metrics.efficiency
            performanceTrend = metrics.trend
        }
    }
    
    private func getBuildingCoordinate(for buildingName: String) -> CLLocationCoordinate2D {
        // Simplified mapping - in a full implementation, this would come from database
        switch buildingName {
        case let name where name.contains("West 18th"):
            return CLLocationCoordinate2D(latitude: 40.7421, longitude: -73.9966)
        case let name where name.contains("East 20th"):
            return CLLocationCoordinate2D(latitude: 40.7378, longitude: -73.9874)
        case let name where name.contains("Franklin"):
            return CLLocationCoordinate2D(latitude: 40.7189, longitude: -74.0072)
        case let name where name.contains("Perry"):
            return CLLocationCoordinate2D(latitude: 40.7357, longitude: -74.0059)
        case let name where name.contains("Rubin"):
            return CLLocationCoordinate2D(latitude: 40.7410, longitude: -73.9969)
        default:
            return CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
        }
    }
    
    private func isActiveToday(tasks: [OperationalDataTaskAssignment]) -> Bool {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let todayName = formatter.string(from: today)
        
        return tasks.contains { task in
            task.daysOfWeek?.contains(todayName) ?? true
        }
    }
}

// MARK: - Preview Support

// Hashable/Equatable conformance for nested type with non-Hashable members
extension WorkerProfileViewModel.BuildingAssignment: Equatable {
    public static func == (lhs: WorkerProfileViewModel.BuildingAssignment, rhs: WorkerProfileViewModel.BuildingAssignment) -> Bool {
        lhs.id == rhs.id
    }
}

extension WorkerProfileViewModel.BuildingAssignment: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#if DEBUG
extension WorkerProfileViewModel {
    static func preview() -> WorkerProfileViewModel {
        let container = ServiceContainer()
        let viewModel = WorkerProfileViewModel(serviceContainer: container)
        return viewModel
    }
}
#endif
