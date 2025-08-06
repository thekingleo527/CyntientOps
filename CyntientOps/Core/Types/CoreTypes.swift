//
//  CoreTypes.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: All types consolidated with no redeclarations
//  ✅ FIXED: NamedCoordinate included
//  ✅ FIXED: All missing types added
//  ✅ ORGANIZED: Clear structure and namespacing
//

import Foundation
import CoreLocation
import Combine
import SwiftUI
import AVFoundation
import UIKit

// MARK: - CoreTypes Namespace
public struct CoreTypes {
    
    // MARK: - Core ID Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - User & Worker Types
    
    public enum UserRole: String, Codable, CaseIterable {
        case admin = "admin"
        case manager = "manager"
        case worker = "worker"
        case client = "client"
        
        public var displayName: String {
            switch self {
            case .admin: return "Admin"
            case .manager: return "Manager"
            case .worker: return "Worker"
            case .client: return "Client"
            }
        }
    }
    
    public struct User: Codable, Hashable, Identifiable {
        public let id: String
        public let workerId: WorkerID
        public let name: String
        public let email: String
        public let role: String
        
        public init(id: String = UUID().uuidString, workerId: WorkerID, name: String, email: String, role: String) {
            self.id = id
            self.workerId = workerId
            self.name = name
            self.email = email
            self.role = role
        }
        
        public var isAdmin: Bool { role == "admin" }
        public var isWorker: Bool { role == "worker" }
        public var displayName: String { name }
    }
    
    public struct WorkerProfile: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let email: String
        public let phone: String?
        public let phoneNumber: String?
        public let role: UserRole
        public let skills: [String]?
        public let certifications: [String]?
        public let hireDate: Date?
        public let isActive: Bool
        public let profileImageUrl: URL?
        public let assignedBuildingIds: [String]
        public let capabilities: WorkerCapabilities?
        public let createdAt: Date
        public let updatedAt: Date
        public let status: WorkerStatus
        public let isClockedIn: Bool
        public let currentBuildingId: String?
        public let clockStatus: ClockStatus?
        
        // Additional computed properties for compatibility
        public var isOnBreak: Bool { clockStatus == .onBreak }
        public var clockInTime: Date? { nil } // Would need to fetch from clock-in records
        public var currentBuilding: NamedCoordinate? { nil } // Would need to fetch from building service
        public var completedTasks: Int { 0 } // Would need to fetch from task service
        public var totalTasks: Int { 0 } // Would need to fetch from task service
        public var completionRate: Double { totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0 }
        public var photoCompliance: Double { 0.9 } // Mock value
        public var efficiency: Double { 0.85 } // Mock value
        public var isTopPerformer: Bool { efficiency > 0.9 }
        
        public init(
            id: String,
            name: String,
            email: String,
            phone: String? = nil,
            phoneNumber: String? = nil,
            role: UserRole,
            skills: [String]? = nil,
            certifications: [String]? = nil,
            hireDate: Date? = nil,
            isActive: Bool = true,
            profileImageUrl: URL? = nil,
            assignedBuildingIds: [String] = [],
            capabilities: WorkerCapabilities? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date(),
            status: WorkerStatus = .offline,
            isClockedIn: Bool = false,
            currentBuildingId: String? = nil,
            clockStatus: ClockStatus? = nil
        ) {
            self.id = id
            self.name = name
            self.email = email
            self.phone = phone
            self.phoneNumber = phoneNumber ?? phone
            self.role = role
            self.skills = skills
            self.certifications = certifications
            self.hireDate = hireDate
            self.isActive = isActive
            self.profileImageUrl = profileImageUrl
            self.assignedBuildingIds = assignedBuildingIds
            self.capabilities = capabilities
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.status = status
            self.isClockedIn = isClockedIn
            self.currentBuildingId = currentBuildingId
            self.clockStatus = clockStatus
        }
        
        public var displayName: String { name }
        public var isAdmin: Bool { role == .admin }
        public var isWorker: Bool { role == .worker }
        public var isManager: Bool { role == .manager }
        public var isClient: Bool { role == .client }
    }
    
    public struct WorkerCapabilities: Codable, Hashable {
        public let canUploadPhotos: Bool
        public let canAddNotes: Bool
        public let canViewMap: Bool
        public let canAddEmergencyTasks: Bool
        public let requiresPhotoForSanitation: Bool
        public let simplifiedInterface: Bool
        
        public init(
            canUploadPhotos: Bool = true,
            canAddNotes: Bool = true,
            canViewMap: Bool = true,
            canAddEmergencyTasks: Bool = false,
            requiresPhotoForSanitation: Bool = true,
            simplifiedInterface: Bool = false
        ) {
            self.canUploadPhotos = canUploadPhotos
            self.canAddNotes = canAddNotes
            self.canViewMap = canViewMap
            self.canAddEmergencyTasks = canAddEmergencyTasks
            self.requiresPhotoForSanitation = requiresPhotoForSanitation
            self.simplifiedInterface = simplifiedInterface
        }
    }
    
    public enum WorkerStatus: String, Codable, CaseIterable {
        case available = "Available"
        case clockedIn = "Clocked In"
        case onBreak = "On Break"
        case offline = "Offline"
    }
    
    public enum ClockStatus: String, Codable {
        case clockedIn = "clockedIn"
        case clockedOut = "clockedOut"
        case onBreak = "onBreak"
    }
    
    // MARK: - Location & Building Types
    
    public struct NamedCoordinate: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let address: String
        public let latitude: Double
        public let longitude: Double
        public let type: BuildingType?
        
        public init(id: String, name: String, address: String, latitude: Double, longitude: Double, type: BuildingType? = nil, buildingName: String? = nil) {
            self.id = id
            self.name = buildingName ?? name
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.type = type
        }
        
        public init(id: String, name: String, latitude: Double, longitude: Double) {
            self.id = id
            self.name = name
            self.address = ""
            self.latitude = latitude
            self.longitude = longitude
            self.type = nil
        }
        
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public var location: CLLocation {
            CLLocation(latitude: latitude, longitude: longitude)
        }
        
        public func distance(from other: NamedCoordinate) -> Double {
            let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
            let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
            return location1.distance(from: location2)
        }
        
        // Note: shortName is defined in Building.swift extension
    }
    
    public enum BuildingType: String, Codable, CaseIterable {
        case office = "Office"
        case residential = "Residential"
        case retail = "Retail"
        case industrial = "Industrial"
        case warehouse = "Warehouse"
        case medical = "Medical"
        case educational = "Educational"
        case mixed = "Mixed Use"
    }
    
    public struct BuildingMetrics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let completionRate: Double
        public let averageTaskTime: TimeInterval
        public let overdueTasks: Int
        public let totalTasks: Int
        public let activeWorkers: Int
        public let isCompliant: Bool
        public let overallScore: Double
        public let lastUpdated: Date
        public let pendingTasks: Int
        public let urgentTasksCount: Int
        public let hasWorkerOnSite: Bool
        public let maintenanceEfficiency: Double
        public let weeklyCompletionTrend: Double
        public let criticalIssues: Int
        
        // Additional properties for compatibility
        public var serviceLevel: Double { completionRate }
        public var complianceScore: Double { isCompliant ? 1.0 : 0.5 }
        public var costVariance: Double { 0.05 } // Mock value
        public var leadWorker: String? { nil }
        public var taskCount: Int { totalTasks }
        public var hasComplianceIssues: Bool { !isCompliant }
        public var complianceIssueCount: Int { isCompliant ? 0 : 1 }
        public var nextComplianceDeadline: Date? { nil }
        public var lastInspectionDate: Date? { nil }
        public var inspectionPassed: Bool { true }
        public var hasIssues: Bool { overdueTasks > 0 || criticalIssues > 0 }
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            completionRate: Double,
            averageTaskTime: TimeInterval = 3600,
            overdueTasks: Int,
            totalTasks: Int,
            activeWorkers: Int,
            isCompliant: Bool = true,
            overallScore: Double,
            lastUpdated: Date = Date(),
            pendingTasks: Int,
            urgentTasksCount: Int,
            hasWorkerOnSite: Bool = false,
            maintenanceEfficiency: Double = 0.85,
            weeklyCompletionTrend: Double = 0.0,
            criticalIssues: Int = 0
        ) {
            self.id = id
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.averageTaskTime = averageTaskTime
            self.overdueTasks = overdueTasks
            self.totalTasks = totalTasks
            self.activeWorkers = activeWorkers
            self.isCompliant = isCompliant
            self.overallScore = overallScore
            self.lastUpdated = lastUpdated
            self.pendingTasks = pendingTasks
            self.urgentTasksCount = urgentTasksCount
            self.hasWorkerOnSite = hasWorkerOnSite
            self.maintenanceEfficiency = maintenanceEfficiency
            self.weeklyCompletionTrend = weeklyCompletionTrend
            self.criticalIssues = criticalIssues
        }
        
        public static let empty = BuildingMetrics(
            buildingId: "",
            completionRate: 0.0,
            overdueTasks: 0,
            totalTasks: 0,
            activeWorkers: 0,
            overallScore: 0.0,
            pendingTasks: 0,
            urgentTasksCount: 0
        )
    }
    
    // MARK: - Task Types
    
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "cleaning"
        case maintenance = "maintenance"
        case security = "security"
        case inspection = "inspection"
        case administrative = "administrative"
        case repair = "repair"
        case installation = "installation"
        case utilities = "utilities"
        case emergency = "emergency"
        case renovation = "renovation"
        case compliance = "compliance"
        case landscaping = "landscaping"
        case sanitation = "sanitation"
        
        public var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .maintenance: return "wrench.and.screwdriver"
            case .security: return "shield"
            case .inspection: return "magnifyingglass"
            case .administrative: return "folder"
            case .repair: return "hammer"
            case .installation: return "plus.square"
            case .utilities: return "bolt"
            case .emergency: return "exclamationmark.triangle.fill"
            case .renovation: return "building.2"
            case .landscaping: return "leaf"
            case .sanitation: return "sparkles"
            case .compliance: return "checkmark.shield"
            }
        }
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
        case urgent = "urgent"
        case emergency = "emergency"
        
        public var urgencyLevel: Int {
            switch self {
            case .low: return 1
            case .medium, .normal: return 2
            case .high: return 3
            case .urgent: return 4
            case .critical: return 5
            case .emergency: return 6
            }
        }
        
        public var sortOrder: Int { urgencyLevel }
    }
    
    public enum TaskStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case overdue = "Overdue"
        case cancelled = "Cancelled"
        case paused = "Paused"
        case waiting = "Waiting"
    }
    
    public enum TaskFrequency: String, Codable, CaseIterable {
        case daily
        case weekly
        case biweekly = "bi-weekly"
        case monthly
        case quarterly
        case annual
        case onDemand = "on-demand"
    }
    
    public struct ContextualTask: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String?
        public var status: TaskStatus
        public var completedAt: Date?
        public var completedDate: Date? { completedAt }
        public var scheduledDate: Date?
        public var dueDate: Date?
        public var category: TaskCategory?
        public var urgency: TaskUrgency?
        public var building: NamedCoordinate?
        public var worker: WorkerProfile?
        public var buildingId: String?
        public var buildingName: String?
        public var assignedWorkerId: String?
        public var priority: TaskUrgency?
        public var frequency: TaskFrequency?
        public var requiresPhoto: Bool?
        public var estimatedDuration: TimeInterval?
        public var createdAt: Date
        public var updatedAt: Date
        
        public var isCompleted: Bool {
            get { status == .completed }
            set { status = newValue ? .completed : .pending }
        }
        
        public var isOverdue: Bool {
            guard let dueDate = dueDate else { return false }
            return Date() > dueDate && status != .completed
        }
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String? = nil,
            status: TaskStatus = .pending,
            completedAt: Date? = nil,
            scheduledDate: Date? = nil,
            dueDate: Date? = nil,
            category: TaskCategory? = nil,
            urgency: TaskUrgency? = nil,
            building: NamedCoordinate? = nil,
            worker: WorkerProfile? = nil,
            buildingId: String? = nil,
            buildingName: String? = nil,
            assignedWorkerId: String? = nil,
            priority: TaskUrgency? = nil,
            frequency: TaskFrequency? = nil,
            requiresPhoto: Bool? = false,
            estimatedDuration: TimeInterval? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.status = status
            self.completedAt = completedAt
            self.scheduledDate = scheduledDate
            self.dueDate = dueDate
            self.category = category
            self.urgency = urgency
            self.building = building
            self.worker = worker
            self.buildingId = buildingId ?? building?.id
            self.buildingName = buildingName ?? building?.name
            self.assignedWorkerId = assignedWorkerId ?? worker?.id
            self.priority = priority ?? urgency
            self.frequency = frequency
            self.requiresPhoto = requiresPhoto
            self.estimatedDuration = estimatedDuration
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
    
    public struct TaskProgress: Codable, Identifiable {
        public let id: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let lastUpdated: Date
        
        // Additional properties for worker dashboard
        public var percentage: Double {
            totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        }
        public var nextTask: (title: String, dueTime: Date)? { nil }
        public var nextDeadline: Date { Date().addingTimeInterval(3600) }
        public var onTimePercentage: Int { 85 }
        public var urgentCount: Int { 0 }
        
        public init(
            id: String = UUID().uuidString,
            totalTasks: Int,
            completedTasks: Int,
            lastUpdated: Date = Date()
        ) {
            self.id = id
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.lastUpdated = lastUpdated
        }
        
        public var completionPercentage: Double {
            totalTasks > 0 ? (Double(completedTasks) / Double(totalTasks)) * 100 : 0
        }
        
        public var progressPercentage: Double { completionPercentage }
    }
    
    // MARK: - Maintenance Types
    
    public struct MaintenanceTask: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let status: TaskStatus
        public let buildingId: String
        public let assignedWorkerId: String?
        public let estimatedDuration: TimeInterval
        public let createdDate: Date
        public let dueDate: Date?
        public let completedDate: Date?
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: TaskCategory,
            urgency: TaskUrgency,
            status: TaskStatus = .pending,
            buildingId: String,
            assignedWorkerId: String? = nil,
            estimatedDuration: TimeInterval = 3600,
            createdDate: Date = Date(),
            dueDate: Date? = nil,
            completedDate: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.status = status
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.estimatedDuration = estimatedDuration
            self.createdDate = createdDate
            self.dueDate = dueDate
            self.completedDate = completedDate
        }
    }
    
    public struct MaintenanceRecord: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let taskId: String
        public let workerId: String
        public let category: TaskCategory
        public let description: String
        public let completedAt: Date
        public let duration: TimeInterval
        public let cost: Double?
        public let notes: String?
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            taskId: String,
            workerId: String,
            category: TaskCategory,
            description: String,
            completedAt: Date = Date(),
            duration: TimeInterval,
            cost: Double? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.buildingId = buildingId
            self.taskId = taskId
            self.workerId = workerId
            self.category = category
            self.description = description
            self.completedAt = completedAt
            self.duration = duration
            self.cost = cost
            self.notes = notes
        }
    }
    
    // MARK: - Dashboard & Sync Types
    
    public enum DashboardSyncStatus: String, Codable, CaseIterable {
        case syncing = "Syncing"
        case synced = "Synced"
        case failed = "Failed"
        case offline = "Offline"
        case error = "Error"
    }
    
    public struct DashboardUpdate: Codable, Identifiable {
        public enum Source: String, Codable, RawRepresentable {
            case admin = "admin"
            case worker = "worker"
            case client = "client"
            case system = "system"
        }
        
        public enum UpdateType: String, Codable, RawRepresentable {
            case taskStarted = "taskStarted"
            case taskCompleted = "taskCompleted"
            case taskUpdated = "taskUpdated"
            case workerClockedIn = "workerClockedIn"
            case workerClockedOut = "workerClockedOut"
            case buildingMetricsChanged = "buildingMetricsChanged"
            case inventoryUpdated = "inventoryUpdated"
            case complianceStatusChanged = "complianceStatusChanged"
            case criticalUpdate = "criticalUpdate"
            case buildingUpdate = "buildingUpdate"
            case complianceUpdate = "complianceUpdate"
            case routineStatusChanged = "routineStatusChanged"
            case monthlyMetricsUpdated = "monthlyMetricsUpdated"
            case activeWorkersChanged = "activeWorkersChanged"
            case criticalAlert = "criticalAlert"
            case intelligenceGenerated = "intelligenceGenerated"
            case portfolioMetricsChanged = "portfolioMetricsChanged"
        }
        
        public let id: String
        public let source: Source
        public let type: UpdateType
        public let buildingId: String
        public let workerId: String
        public let data: [String: String]
        public let timestamp: Date
        public let description: String?
        
        public init(
            id: String = UUID().uuidString,
            source: Source,
            type: UpdateType,
            buildingId: String,
            workerId: String,
            data: [String: String] = [:],
            timestamp: Date = Date(),
            description: String? = nil
        ) {
            self.id = id
            self.source = source
            self.type = type
            self.buildingId = buildingId
            self.workerId = workerId
            self.data = data
            self.timestamp = timestamp
            self.description = description
        }
    }
    
    public struct CrossDashboardUpdate: Codable {
        public let updateType: String
        public let data: [String: String]
        public let timestamp: Date
        
        public init(updateType: String, data: [String: String] = [:], timestamp: Date = Date()) {
            self.updateType = updateType
            self.data = data
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Client Dashboard Types
    
    public struct RealtimeRoutineMetrics: Codable {
        public var overallCompletion: Double
        public var activeWorkerCount: Int
        public var behindScheduleCount: Int
        public var buildingStatuses: [String: BuildingRoutineStatus]
        
        public var hasActiveIssues: Bool {
            behindScheduleCount > 0 || buildingStatuses.contains { $0.value.hasIssue }
        }
        
        public init(
            overallCompletion: Double = 0.0,
            activeWorkerCount: Int = 0,
            behindScheduleCount: Int = 0,
            buildingStatuses: [String: BuildingRoutineStatus] = [:]
        ) {
            self.overallCompletion = overallCompletion
            self.activeWorkerCount = activeWorkerCount
            self.behindScheduleCount = behindScheduleCount
            self.buildingStatuses = buildingStatuses
        }
    }
    
    public struct BuildingRoutineStatus: Codable {
        public let buildingId: String
        public let buildingName: String
        public let completionRate: Double
        public let timeBlock: TimeBlock
        public let activeWorkerCount: Int
        public let isOnSchedule: Bool
        public let estimatedCompletion: Date?
        public let hasIssue: Bool
        
        public let workerDetails: [WorkerInfo]?
        public let taskBreakdown: [TaskInfo]?
        
        public var isBehindSchedule: Bool {
            !isOnSchedule && completionRate < expectedCompletionForTime()
        }
        
        private func expectedCompletionForTime() -> Double {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 7..<11: return 0.3
            case 11..<15: return 0.6
            case 15..<19: return 0.9
            default: return 1.0
            }
        }
        
        public enum TimeBlock: String, Codable {
            case morning = "morning"
            case afternoon = "afternoon"
            case evening = "evening"
            case overnight = "overnight"
            
            public static var current: TimeBlock {
                let hour = Calendar.current.component(.hour, from: Date())
                switch hour {
                case 6..<12: return .morning
                case 12..<17: return .afternoon
                case 17..<22: return .evening
                default: return .overnight
                }
            }
        }
        
        public init(
            buildingId: String,
            buildingName: String,
            completionRate: Double,
            activeWorkerCount: Int,
            isOnSchedule: Bool,
            estimatedCompletion: Date? = nil,
            hasIssue: Bool = false,
            workerDetails: [WorkerInfo]? = nil,
            taskBreakdown: [TaskInfo]? = nil
        ) {
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.completionRate = completionRate
            self.timeBlock = TimeBlock.current
            self.activeWorkerCount = activeWorkerCount
            self.isOnSchedule = isOnSchedule
            self.estimatedCompletion = estimatedCompletion
            self.hasIssue = hasIssue
            self.workerDetails = workerDetails
            self.taskBreakdown = taskBreakdown
        }
    }
    
    public struct WorkerInfo: Codable {
        public let id: String
        public let name: String
        public let role: String
        
        public init(id: String, name: String, role: String) {
            self.id = id
            self.name = name
            self.role = role
        }
    }
    
    public struct TaskInfo: Codable {
        public let id: String
        public let title: String
        public let status: String
        
        public init(id: String, title: String, status: String) {
            self.id = id
            self.title = title
            self.status = status
        }
    }
    
    public struct ActiveWorkerStatus: Codable {
        public let totalActive: Int
        public let byBuilding: [String: Int]
        public let utilizationRate: Double
        public let avgTasksPerWorker: Double?
        public let completionRate: Double?
        
        public init(
            totalActive: Int,
            byBuilding: [String: Int] = [:],
            utilizationRate: Double,
            avgTasksPerWorker: Double? = nil,
            completionRate: Double? = nil
        ) {
            self.totalActive = totalActive
            self.byBuilding = byBuilding
            self.utilizationRate = utilizationRate
            self.avgTasksPerWorker = avgTasksPerWorker
            self.completionRate = completionRate
        }
    }
    
    public struct MonthlyMetrics: Codable {
        public let currentSpend: Double
        public let monthlyBudget: Double
        public let projectedSpend: Double
        public let daysRemaining: Int
        
        public var budgetUtilization: Double {
            monthlyBudget > 0 ? currentSpend / monthlyBudget : 0
        }
        
        public var isOverBudget: Bool {
            projectedSpend > monthlyBudget
        }
        
        public var dailyBurnRate: Double {
            let daysInMonth = 30
            let daysPassed = daysInMonth - daysRemaining
            return daysPassed > 0 ? currentSpend / Double(daysPassed) : 0
        }
        
        public init(
            currentSpend: Double,
            monthlyBudget: Double,
            projectedSpend: Double,
            daysRemaining: Int
        ) {
            self.currentSpend = currentSpend
            self.monthlyBudget = monthlyBudget
            self.projectedSpend = projectedSpend
            self.daysRemaining = daysRemaining
        }
    }
    
    // MARK: - Compliance Types
    
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
        case compliant = "Compliant"
        case warning = "Warning"
        case violation = "Violation"
        case pending = "Pending"
        case nonCompliant = "Non-Compliant"
        case atRisk = "At Risk"
        case needsReview = "Needs Review"
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case environmental = "Environmental"
        case regulatory = "Regulatory"
        case financial = "Financial"
        case operational = "Operational"
        case documentation = "Documentation"
    }
    
    public struct ComplianceIssue: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let severity: ComplianceSeverity
        public let buildingId: String?
        public let buildingName: String?
        public let status: ComplianceStatus
        public let dueDate: Date?
        public let assignedTo: String?
        public let createdAt: Date
        public let reportedDate: Date
        public let type: ComplianceIssueType
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            severity: ComplianceSeverity,
            buildingId: String? = nil,
            buildingName: String? = nil,
            status: ComplianceStatus = .open,
            dueDate: Date? = nil,
            assignedTo: String? = nil,
            createdAt: Date = Date(),
            reportedDate: Date = Date(),
            type: ComplianceIssueType
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.severity = severity
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.status = status
            self.dueDate = dueDate
            self.assignedTo = assignedTo
            self.createdAt = createdAt
            self.reportedDate = reportedDate
            self.type = type
        }
    }
    
    public struct ComplianceOverview: Codable, Identifiable {
        public let id: String
        public let overallScore: Double
        public let criticalViolations: Int
        public let pendingInspections: Int
        public let lastUpdated: Date
        public let buildingCompliance: [String: ComplianceStatus]
        public let upcomingDeadlines: [ComplianceDeadline]
        
        public init(
            id: String = UUID().uuidString,
            overallScore: Double,
            criticalViolations: Int = 0,
            pendingInspections: Int = 0,
            lastUpdated: Date = Date(),
            buildingCompliance: [String: ComplianceStatus] = [:],
            upcomingDeadlines: [ComplianceDeadline] = []
        ) {
            self.id = id
            self.overallScore = overallScore
            self.criticalViolations = criticalViolations
            self.pendingInspections = pendingInspections
            self.lastUpdated = lastUpdated
            self.buildingCompliance = buildingCompliance
            self.upcomingDeadlines = upcomingDeadlines
        }
    }
    
    public struct ComplianceDeadline: Codable, Identifiable {
        public let id: String
        public let title: String
        public let dueDate: Date
        public let buildingId: String
        public let priority: AIPriority
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            dueDate: Date,
            buildingId: String,
            priority: AIPriority
        ) {
            self.id = id
            self.title = title
            self.dueDate = dueDate
            self.buildingId = buildingId
            self.priority = priority
        }
    }
    
    // MARK: - Intelligence & AI Types
    
    public enum AIPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    public enum InsightCategory: String, Codable, CaseIterable {
        case efficiency = "Efficiency"
        case cost = "Cost"
        case safety = "Safety"
        case compliance = "Compliance"
        case quality = "Quality"
        case operations = "Operations"
        case maintenance = "Maintenance"
        case routing = "Routing"
        case weather = "Weather"
        case performance = "Performance"
        
        public var icon: String {
            switch self {
            case .efficiency: return "speedometer"
            case .cost: return "dollarsign.circle"
            case .safety: return "shield.fill"
            case .compliance: return "checkmark.shield"
            case .quality: return "star.fill"
            case .operations: return "gearshape.fill"
            case .maintenance: return "wrench.and.screwdriver"
            case .routing: return "location.fill"
            case .weather: return "cloud.fill"
            case .performance: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    public typealias InsightType = InsightCategory
    
    public struct IntelligenceInsight: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightCategory
        public let priority: AIPriority
        public let actionRequired: Bool
        public let recommendedAction: String?
        public let affectedBuildings: [String]
        public let estimatedImpact: String?
        public let generatedAt: Date
        public let category: InsightCategory
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightCategory,
            priority: AIPriority,
            actionRequired: Bool = false,
            recommendedAction: String? = nil,
            affectedBuildings: [String] = [],
            estimatedImpact: String? = nil,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionRequired = actionRequired
            self.recommendedAction = recommendedAction
            self.affectedBuildings = affectedBuildings
            self.estimatedImpact = estimatedImpact
            self.generatedAt = generatedAt
            self.category = type
        }
    }
    
    public struct AISuggestion: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: InsightCategory
        public let priority: AIPriority
        public let confidence: Double
        public let actionItems: [String]
        public let estimatedImpact: String?
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: InsightCategory,
            priority: AIPriority,
            confidence: Double = 0.8,
            actionItems: [String] = [],
            estimatedImpact: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.priority = priority
            self.confidence = confidence
            self.actionItems = actionItems
            self.estimatedImpact = estimatedImpact
        }
    }
    
    public enum AIScenarioType: String, Codable, CaseIterable {
        case taskOptimization = "task_optimization"
        case routeOptimization = "route_optimization"
        case inventoryManagement = "inventory_management"
        case complianceAlert = "compliance_alert"
        case maintenancePrediction = "maintenance_prediction"
        case emergencyResponse = "emergency_response"
    }
    
    public struct AIScenario: Codable, Identifiable {
        public let id: String
        public let type: AIScenarioType
        public let title: String
        public let description: String
        public let suggestions: [AISuggestion]
        public let requiredAction: Bool
        public let createdAt: Date
        
        public init(
            id: String = UUID().uuidString,
            type: AIScenarioType,
            title: String,
            description: String,
            suggestions: [AISuggestion] = [],
            requiredAction: Bool = false,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.type = type
            self.title = title
            self.description = description
            self.suggestions = suggestions
            self.requiredAction = requiredAction
            self.createdAt = createdAt
        }
    }
    
    // MARK: - Portfolio & Executive Types
    
    public struct PortfolioMetrics: Codable, Identifiable {
        public let id: String
        public let totalBuildings: Int
        public let totalWorkers: Int
        public let activeWorkers: Int
        public let overallCompletionRate: Double
        public let criticalIssues: Int
        public let totalTasks: Int
        public let completedTasks: Int
        public let pendingTasks: Int
        public let overdueTasks: Int
        public let complianceScore: Double
        public let lastUpdated: Date
        
        public init(
            id: String = UUID().uuidString,
            totalBuildings: Int,
            totalWorkers: Int = 0,
            activeWorkers: Int,
            overallCompletionRate: Double,
            criticalIssues: Int,
            totalTasks: Int = 0,
            completedTasks: Int = 0,
            pendingTasks: Int = 0,
            overdueTasks: Int = 0,
            complianceScore: Double,
            lastUpdated: Date = Date()
        ) {
            self.id = id
            self.totalBuildings = totalBuildings
            self.totalWorkers = totalWorkers
            self.activeWorkers = activeWorkers
            self.overallCompletionRate = overallCompletionRate
            self.criticalIssues = criticalIssues
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.pendingTasks = pendingTasks
            self.overdueTasks = overdueTasks
            self.complianceScore = complianceScore
            self.lastUpdated = lastUpdated
        }
    }
    
    public struct PortfolioHealth: Codable {
        public let overallScore: Double
        public let totalBuildings: Int
        public let activeBuildings: Int
        public let criticalIssues: Int
        public let trend: TrendDirection
        public let lastUpdated: Date
        
        public init(
            overallScore: Double,
            totalBuildings: Int,
            activeBuildings: Int,
            criticalIssues: Int,
            trend: TrendDirection,
            lastUpdated: Date
        ) {
            self.overallScore = overallScore
            self.totalBuildings = totalBuildings
            self.activeBuildings = activeBuildings
            self.criticalIssues = criticalIssues
            self.trend = trend
            self.lastUpdated = lastUpdated
        }
    }
    
    public struct PortfolioIntelligence: Codable, Identifiable {
        public let id: String
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completionRate: Double
        public let criticalIssues: Int
        public let monthlyTrend: TrendDirection
        public let complianceScore: Double
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            totalBuildings: Int,
            activeWorkers: Int,
            completionRate: Double,
            criticalIssues: Int,
            monthlyTrend: TrendDirection,
            complianceScore: Double,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.completionRate = completionRate
            self.criticalIssues = criticalIssues
            self.monthlyTrend = monthlyTrend
            self.complianceScore = complianceScore
            self.generatedAt = generatedAt
        }
    }
    
    public struct ExecutiveSummary: Codable, Identifiable {
        public let id: String
        public let totalBuildings: Int
        public let totalWorkers: Int
        public let portfolioHealth: Double
        public let monthlyPerformance: String
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            totalBuildings: Int,
            totalWorkers: Int,
            portfolioHealth: Double,
            monthlyPerformance: String,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.totalBuildings = totalBuildings
            self.totalWorkers = totalWorkers
            self.portfolioHealth = portfolioHealth
            self.monthlyPerformance = monthlyPerformance
            self.generatedAt = generatedAt
        }
    }
    
    public struct ExecutiveIntelligence: Codable, Identifiable {
        public let id: String
        public let summary: String
        public let keyMetrics: [String: Double]
        public let insights: [IntelligenceInsight]
        public let recommendations: [StrategicRecommendation]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            summary: String,
            keyMetrics: [String: Double] = [:],
            insights: [IntelligenceInsight] = [],
            recommendations: [StrategicRecommendation] = [],
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.summary = summary
            self.keyMetrics = keyMetrics
            self.insights = insights
            self.recommendations = recommendations
            self.generatedAt = generatedAt
        }
    }
    
    public struct StrategicRecommendation: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: InsightCategory
        public let priority: AIPriority
        public let timeframe: String
        public let estimatedImpact: String
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: InsightCategory = .operations,
            priority: AIPriority,
            timeframe: String,
            estimatedImpact: String
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.priority = priority
            self.timeframe = timeframe
            self.estimatedImpact = estimatedImpact
        }
    }
    
    public struct ClientPortfolioIntelligence: Codable, Identifiable {
        public let id: String
        public let portfolioHealth: PortfolioHealth
        public let executiveSummary: ExecutiveSummary
        public let benchmarks: [PortfolioBenchmark]
        public let strategicRecommendations: [StrategicRecommendation]
        public let performanceTrends: [Double]
        public let generatedAt: Date
        
        // Legacy compatibility properties
        public let totalProperties: Int
        public let serviceLevel: Double
        public let complianceScore: Int
        public let complianceIssues: Int
        public let monthlyTrend: TrendDirection
        public let coveragePercentage: Double
        public let monthlySpend: Double
        public let monthlyBudget: Double
        public let showCostData: Bool
        
        public init(
            id: String = UUID().uuidString,
            portfolioHealth: PortfolioHealth,
            executiveSummary: ExecutiveSummary,
            benchmarks: [PortfolioBenchmark] = [],
            strategicRecommendations: [StrategicRecommendation] = [],
            performanceTrends: [Double] = [],
            generatedAt: Date = Date(),
            totalProperties: Int? = nil,
            serviceLevel: Double? = nil,
            complianceScore: Int? = nil,
            complianceIssues: Int? = nil,
            monthlyTrend: TrendDirection? = nil,
            coveragePercentage: Double? = nil,
            monthlySpend: Double? = nil,
            monthlyBudget: Double? = nil,
            showCostData: Bool = true
        ) {
            self.id = id
            self.portfolioHealth = portfolioHealth
            self.executiveSummary = executiveSummary
            self.benchmarks = benchmarks
            self.strategicRecommendations = strategicRecommendations
            self.performanceTrends = performanceTrends
            self.generatedAt = generatedAt
            
            // Set legacy properties
            self.totalProperties = totalProperties ?? portfolioHealth.totalBuildings
            self.serviceLevel = serviceLevel ?? portfolioHealth.overallScore
            self.complianceScore = complianceScore ?? Int(portfolioHealth.overallScore * 100)
            self.complianceIssues = complianceIssues ?? portfolioHealth.criticalIssues
            self.monthlyTrend = monthlyTrend ?? portfolioHealth.trend
            self.coveragePercentage = coveragePercentage ?? portfolioHealth.overallScore
            self.monthlySpend = monthlySpend ?? 0
            self.monthlyBudget = monthlyBudget ?? 0
            self.showCostData = showCostData
        }
        
        // Convenience properties
        public var overallScore: Double { portfolioHealth.overallScore }
        public var hasCriticalIssues: Bool { portfolioHealth.criticalIssues > 0 }
        public var hasActiveIssues: Bool { hasCriticalIssues }
        public var hasBehindScheduleBuildings: Bool { performanceTrends.last ?? 1.0 < 0.8 }
        public var hasComplianceIssues: Bool { complianceIssues > 0 }
        public var buildingsWithComplianceIssues: [String] { [] }
        public func buildingName(for id: String) -> String? { nil }
    }
    
    public struct PortfolioBenchmark: Codable, Identifiable {
        public let id: String
        public let metric: String
        public let value: Double
        public let benchmark: Double
        public let trend: String
        public let period: String
        
        public init(
            id: String = UUID().uuidString,
            metric: String,
            value: Double,
            benchmark: Double,
            trend: String,
            period: String
        ) {
            self.id = id
            self.metric = metric
            self.value = value
            self.benchmark = benchmark
            self.trend = trend
            self.period = period
        }
    }
    
    // MARK: - Admin Types
    
    public struct AdminAlert: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let urgency: AIPriority
        public let type: AlertType
        public let affectedBuilding: String?
        public let timestamp: Date
        public let metadata: [String: String]
        
        public enum AlertType: String, Codable {
            case compliance = "compliance"
            case worker = "worker"
            case building = "building"
            case task = "task"
            case system = "system"
        }
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            urgency: AIPriority,
            type: AlertType,
            affectedBuilding: String? = nil,
            timestamp: Date = Date(),
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.urgency = urgency
            self.type = type
            self.affectedBuilding = affectedBuilding
            self.timestamp = timestamp
            self.metadata = metadata
        }
    }
    
    // MARK: - Supporting Types
    
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "Up"
        case down = "Down"
        case stable = "Stable"
        case improving = "Improving"
        case declining = "Declining"
        case unknown = "Unknown"
        
        public var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .unknown: return "questionmark"
            }
        }
    }
    
    public enum UrgencyLevel: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
        case critical = "critical"
        case emergency = "emergency"
        
        public var priority: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .urgent: return 4
            case .critical: return 5
            case .emergency: return 6
            }
        }
    }
    
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "clear"
        case cloudy = "cloudy"
        case rain = "rain"
        case snow = "snow"
        case storm = "storm"
        case fog = "fog"
        case windy = "windy"
        
        public var icon: String {
            switch self {
            case .clear: return "sun.max"
            case .cloudy: return "cloud"
            case .rain: return "cloud.rain"
            case .snow: return "snowflake"
            case .storm: return "cloud.bolt"
            case .fog: return "cloud.fog"
            case .windy: return "wind"
            }
        }
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case moderate = "Moderate"
        case high = "High"
        case extreme = "Extreme"
    }
    
    public struct WeatherData: Codable, Identifiable {
        public let id: String
        public let temperature: Double
        public let condition: WeatherCondition
        public let humidity: Double
        public let windSpeed: Double
        public let outdoorWorkRisk: OutdoorWorkRisk
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            temperature: Double,
            condition: WeatherCondition,
            humidity: Double,
            windSpeed: Double,
            outdoorWorkRisk: OutdoorWorkRisk = .low,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.temperature = temperature
            self.condition = condition
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.outdoorWorkRisk = outdoorWorkRisk
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Performance & Metrics Types
    
    public struct PerformanceMetrics: Codable, Identifiable {
        public let id: String
        public let workerId: String?
        public let buildingId: String?
        public let period: String
        public let completionRate: Double
        public let avgTaskTime: TimeInterval
        public let efficiency: Double
        public let qualityScore: Double
        public let punctualityScore: Double
        public let totalTasks: Int
        public let completedTasks: Int
        
        // Additional properties for compatibility
        public var averageTime: TimeInterval { avgTaskTime }
        public var tasksCompleted: Int { completedTasks }
        public var lastUpdate: Date { Date() }
        public var performanceGrade: String {
            let score = (efficiency + qualityScore + punctualityScore) / 3
            if score >= 0.9 { return "A+" }
            if score >= 0.8 { return "A" }
            if score >= 0.7 { return "B" }
            if score >= 0.6 { return "C" }
            return "D"
        }
        
        public init(
            id: String = UUID().uuidString,
            workerId: String? = nil,
            buildingId: String? = nil,
            period: String = "daily",
            completionRate: Double = 0,
            avgTaskTime: TimeInterval = 0,
            efficiency: Double = 0,
            qualityScore: Double = 0,
            punctualityScore: Double = 0,
            totalTasks: Int = 0,
            completedTasks: Int = 0
        ) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.period = period
            self.completionRate = completionRate
            self.avgTaskTime = avgTaskTime
            self.efficiency = efficiency
            self.qualityScore = qualityScore
            self.punctualityScore = punctualityScore
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
        }
    }
    
    // MARK: - Inventory Types
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
    }
    
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case tools = "Tools"
        case safety = "Safety"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case general = "General"
        case office = "Office"
        case maintenance = "Maintenance"
        case supplies = "Supplies"
        case equipment = "Equipment"
        case materials = "Materials"
        case building = "Building"
        case sanitation = "Sanitation"
        case seasonal = "Seasonal"
        case other = "Other"
    }
    
    public struct InventoryItem: Codable, Identifiable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let maxStock: Int
        public let unit: String
        public let cost: Double
        public let supplier: String?
        public let location: String?
        public let lastRestocked: Date?
        public let status: RestockStatus
        
        public var quantity: Int { currentStock }
        public var minThreshold: Int { minimumStock }
        public var restockStatus: RestockStatus { status }
        
        public init(
            id: String = UUID().uuidString,
            name: String,
            category: InventoryCategory,
            currentStock: Int,
            minimumStock: Int,
            maxStock: Int,
            unit: String,
            cost: Double = 0.0,
            supplier: String? = nil,
            location: String? = nil,
            lastRestocked: Date? = nil,
            status: RestockStatus? = nil
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.currentStock = currentStock
            self.minimumStock = minimumStock
            self.maxStock = maxStock
            self.unit = unit
            self.cost = cost
            self.supplier = supplier
            self.location = location
            self.lastRestocked = lastRestocked
            
            // Compute status if not provided
            if let providedStatus = status {
                self.status = providedStatus
            } else if currentStock <= 0 {
                self.status = .outOfStock
            } else if currentStock <= minimumStock {
                self.status = .lowStock
            } else {
                self.status = .inStock
            }
        }
    }
    
    // MARK: - Photo Evidence Types
    
    public struct ActionEvidence: Codable, Identifiable {
        public let id: String
        public let photoUrl: String?
        public let description: String?
        public let photoURLs: [String]?
        public let notes: String?
        public let timestamp: Date
        public let location: CLLocationCoordinate2D?
        public let taskId: String?
        public let workerId: String?
        
        public init(
            id: String = UUID().uuidString,
            photoUrl: String? = nil,
            description: String? = nil,
            photoURLs: [String]? = nil,
            notes: String? = nil,
            timestamp: Date = Date(),
            location: CLLocationCoordinate2D? = nil,
            taskId: String? = nil,
            workerId: String? = nil
        ) {
            self.id = id
            self.photoUrl = photoUrl
            self.description = description
            self.photoURLs = photoURLs
            self.notes = notes
            self.timestamp = timestamp
            self.location = location
            self.taskId = taskId
            self.workerId = workerId
        }
        
        public init(photoUrls: [String] = [], notes: String = "", location: CLLocation?) {
            self.id = UUID().uuidString
            self.photoUrl = photoUrls.first
            self.description = notes
            self.photoURLs = photoUrls
            self.notes = notes
            self.timestamp = Date()
            self.location = location?.coordinate
            self.taskId = nil
            self.workerId = nil
        }
    }
    
    public enum FrancoPhotoCategory: String, Codable, CaseIterable {
        case beforeWork = "before_work"
        case duringWork = "during_work"
        case afterWork = "after_work"
        case issue = "issue"
        case inventory = "inventory"
        case compliance = "compliance"
        case emergency = "emergency"
        case utilities = "utilities"
    }
    
    // MARK: - Building Report Types
    
    public struct BuildingReport: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let buildingName: String
        public let completionRate: Double
        public let complianceStatus: ComplianceStatus
        public let activeWorkers: Int
        public let tasksCompleted: Int
        public let issues: [String]
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            buildingName: String,
            completionRate: Double,
            complianceStatus: ComplianceStatus,
            activeWorkers: Int,
            tasksCompleted: Int,
            issues: [String] = []
        ) {
            self.id = id
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.completionRate = completionRate
            self.complianceStatus = complianceStatus
            self.activeWorkers = activeWorkers
            self.tasksCompleted = tasksCompleted
            self.issues = issues
        }
    }
    
    public struct BuildingStatistics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let period: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let maintenanceHours: Double
        public let inventorySpend: Double
        public let complianceScore: Double
        public let workerHours: Double
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            period: String = "monthly",
            totalTasks: Int = 0,
            completedTasks: Int = 0,
            maintenanceHours: Double = 0,
            inventorySpend: Double = 0,
            complianceScore: Double = 1.0,
            workerHours: Double = 0
        ) {
            self.id = id
            self.buildingId = buildingId
            self.period = period
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.maintenanceHours = maintenanceHours
            self.inventorySpend = inventorySpend
            self.complianceScore = complianceScore
            self.workerHours = workerHours
        }
    }
    
    public struct BuildingIntelligence: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let insights: [IntelligenceInsight]
        public let recommendations: [String]
        public let riskAssessment: String
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            insights: [IntelligenceInsight] = [],
            recommendations: [String] = [],
            riskAssessment: String = "low",
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.insights = insights
            self.recommendations = recommendations
            self.riskAssessment = riskAssessment
            self.generatedAt = generatedAt
        }
    }
    
    public struct BuildingAnalytics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let metrics: BuildingMetrics
        public let trends: [Double]
        public let forecasts: [Double]
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            metrics: BuildingMetrics,
            trends: [Double] = [],
            forecasts: [Double] = []
        ) {
            self.id = id
            self.buildingId = buildingId
            self.metrics = metrics
            self.trends = trends
            self.forecasts = forecasts
        }
    }
    
    // MARK: - Worker Route Types
    
    public struct WorkerDailyRoute: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let stops: [RouteStop]
        public let buildings: [NamedCoordinate]?
        public let optimization: RouteOptimization?
        public let estimatedDuration: TimeInterval
        public let actualDuration: TimeInterval?
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            date: Date = Date(),
            stops: [RouteStop] = [],
            buildings: [NamedCoordinate]? = nil,
            optimization: RouteOptimization? = nil,
            estimatedDuration: TimeInterval = 0,
            actualDuration: TimeInterval? = nil
        ) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.stops = stops
            self.buildings = buildings
            self.optimization = optimization
            self.estimatedDuration = estimatedDuration
            self.actualDuration = actualDuration
        }
    }
    
    public struct RouteStop: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let name: String
        public let address: String
        public let latitude: Double
        public let longitude: Double
        public let sequenceNumber: Int
        public let tasks: [String]
        public let estimatedArrival: Date?
        public let actualArrival: Date?
        public let estimatedDuration: TimeInterval
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            name: String,
            address: String,
            latitude: Double,
            longitude: Double,
            sequenceNumber: Int,
            tasks: [String] = [],
            estimatedArrival: Date? = nil,
            actualArrival: Date? = nil,
            estimatedDuration: TimeInterval = 1800
        ) {
            self.id = id
            self.buildingId = buildingId
            self.name = name
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.sequenceNumber = sequenceNumber
            self.tasks = tasks
            self.estimatedArrival = estimatedArrival
            self.actualArrival = actualArrival
            self.estimatedDuration = estimatedDuration
        }
    }
    
    public struct RouteOptimization: Codable {
        public let algorithm: String
        public let distanceSaved: Double
        public let timeSaved: TimeInterval
        public let fuelSaved: Double?
        public let optimizedAt: Date
        
        public init(
            algorithm: String = "nearest_neighbor",
            distanceSaved: Double = 0,
            timeSaved: TimeInterval = 0,
            fuelSaved: Double? = nil,
            optimizedAt: Date = Date()
        ) {
            self.algorithm = algorithm
            self.distanceSaved = distanceSaved
            self.timeSaved = timeSaved
            self.fuelSaved = fuelSaved
            self.optimizedAt = optimizedAt
        }
    }
    
    public struct WorkerRoutineSummary: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let totalTasks: Int
        public let completedTasks: Int
        public let buildingsVisited: Int
        public let totalDistance: Double?
        public let efficiency: Double
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            date: Date = Date(),
            totalTasks: Int = 0,
            completedTasks: Int = 0,
            buildingsVisited: Int = 0,
            totalDistance: Double? = nil,
            efficiency: Double = 0
        ) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.buildingsVisited = buildingsVisited
            self.totalDistance = totalDistance
            self.efficiency = efficiency
        }
    }
    
    public struct WorkerAssignment: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let taskIds: [String]
        public let startTime: Date
        public let endTime: Date?
        public let status: String
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            buildingId: String,
            taskIds: [String] = [],
            startTime: Date = Date(),
            endTime: Date? = nil,
            status: String = "active"
        ) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.taskIds = taskIds
            self.startTime = startTime
            self.endTime = endTime
            self.status = status
        }
    }
    
    public typealias FrancoWorkerAssignment = WorkerAssignment
    
    // MARK: - Verification Types
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case verified = "verified"
        case rejected = "rejected"
        case needsReview = "needs_review"
        case notRequired = "not_required"
    }
    
    public struct TaskCompletionRecord: Codable, Identifiable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let verificationStatus: VerificationStatus
        public let evidence: ActionEvidence?
        
        public init(
            id: String = UUID().uuidString,
            taskId: String,
            workerId: String,
            completedAt: Date = Date(),
            verificationStatus: VerificationStatus = .pending,
            evidence: ActionEvidence? = nil
        ) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.verificationStatus = verificationStatus
            self.evidence = evidence
        }
    }
    
    // MARK: - Client Activity Types
    
    public struct ClientActivity: Codable, Identifiable {
        public let id: String
        public let type: CoreTypes.RealtimeActivity.ActivityType
        public let description: String
        public let buildingId: String?
        public let workerId: String?
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            type: CoreTypes.RealtimeActivity.ActivityType,
            description: String,
            buildingId: String? = nil,
            workerId: String? = nil,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.type = type
            self.description = description
            self.buildingId = buildingId
            self.workerId = workerId
            self.timestamp = timestamp
        }
    }
    
    public struct RealtimeActivity: Codable, Identifiable {
        public enum ActivityType: String, Codable {
            case taskStarted = "task_started"
            case taskCompleted = "task_completed"
            case workerClockedIn = "worker_clocked_in"
            case workerClockedOut = "worker_clocked_out"
            case buildingUpdated = "building_updated"
            case alertCreated = "alert_created"
            case complianceChanged = "compliance_changed"
        }
        
        public let id: String
        public let type: ActivityType
        public let description: String
        public let buildingId: String?
        public let workerId: String?
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            type: ActivityType,
            description: String,
            buildingId: String? = nil,
            workerId: String? = nil,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.type = type
            self.description = description
            self.buildingId = buildingId
            self.workerId = workerId
            self.timestamp = timestamp
        }
    }
    
    public struct ClientAlert: Codable, Identifiable {
        public let id: String
        public let title: String
        public let message: String
        public let severity: AIPriority
        public let buildingId: String?
        public let timestamp: Date
        public let requiresAction: Bool
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            message: String,
            severity: AIPriority,
            buildingId: String? = nil,
            timestamp: Date = Date(),
            requiresAction: Bool = false
        ) {
            self.id = id
            self.title = title
            self.message = message
            self.severity = severity
            self.buildingId = buildingId
            self.timestamp = timestamp
            self.requiresAction = requiresAction
        }
    }
    
    public struct CostInsight: Codable, Identifiable {
        public let id: String
        public let category: String
        public let currentSpend: Double
        public let previousSpend: Double
        public let variance: Double
        public let recommendation: String?
        
        public init(
            id: String = UUID().uuidString,
            category: String,
            currentSpend: Double,
            previousSpend: Double,
            variance: Double,
            recommendation: String? = nil
        ) {
            self.id = id
            self.category = category
            self.currentSpend = currentSpend
            self.previousSpend = previousSpend
            self.variance = variance
            self.recommendation = recommendation
        }
    }
    
    public struct WorkerProductivityInsight: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let productivity: Double
        public let trend: TrendDirection
        public let highlights: [String]
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            productivity: Double,
            trend: TrendDirection,
            highlights: [String] = []
        ) {
            self.id = id
            self.workerId = workerId
            self.productivity = productivity
            self.trend = trend
            self.highlights = highlights
        }
    }
    
    public struct ClientPortfolioReport: Codable, Identifiable {
        public let id: String
        public let generatedAt: Date
        public let reportPeriod: String
        public let portfolioMetrics: PortfolioMetrics
        public let buildingReports: [BuildingReport]
        public let executiveSummary: String
        public let recommendations: [String]
        public let monthlySpend: Double?
        public let monthlyBudget: Double?
        
        public init(
            id: String = UUID().uuidString,
            generatedAt: Date = Date(),
            reportPeriod: String,
            portfolioMetrics: PortfolioMetrics,
            buildingReports: [BuildingReport] = [],
            executiveSummary: String,
            recommendations: [String] = [],
            monthlySpend: Double? = nil,
            monthlyBudget: Double? = nil
        ) {
            self.id = id
            self.generatedAt = generatedAt
            self.reportPeriod = reportPeriod
            self.portfolioMetrics = portfolioMetrics
            self.buildingReports = buildingReports
            self.executiveSummary = executiveSummary
            self.recommendations = recommendations
            self.monthlySpend = monthlySpend
            self.monthlyBudget = monthlyBudget
        }
    }
    
    public typealias RealtimePortfolioMetrics = PortfolioMetrics
    
    // MARK: - Camera Model
    
    public class FrancoCameraModel: NSObject, ObservableObject {
        @Published public var photo: UIImage?
        @Published public var showAlertError = false
        @Published public var isFlashOn = false
        @Published public var isTaken = false
        @Published public var session = AVCaptureSession()
        @Published public var alert = false
        @Published public var output = AVCapturePhotoOutput()
        @Published public var preview: AVCaptureVideoPreviewLayer!
        
        public override init() {
            super.init()
        }
    }
    
    // MARK: - Misc Types
    
    public enum SkillLevel: String, Codable, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
    }
    
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "healthy"
        case warning = "warning"
        case critical = "critical"
        case error = "error"
        case unknown = "unknown"
    }
    
    // MARK: - Realtime Metrics Types
    
    public struct RealtimeMetrics: Codable, Identifiable {
        public let id: String
        public let lastUpdateTime: Date
        public let activeAlerts: Int
        public let pendingActions: Int
        public let systemHealth: DataHealthStatus
        public let responseTime: TimeInterval
        
        public init(
            id: String = UUID().uuidString,
            lastUpdateTime: Date = Date(),
            activeAlerts: Int = 0,
            pendingActions: Int = 0,
            systemHealth: DataHealthStatus = .healthy,
            responseTime: TimeInterval = 0.0
        ) {
            self.id = id
            self.lastUpdateTime = lastUpdateTime
            self.activeAlerts = activeAlerts
            self.pendingActions = pendingActions
            self.systemHealth = systemHealth
            self.responseTime = responseTime
        }
    }
    
} // END of CoreTypes namespace

// MARK: - Global Type Aliases for Direct Access

// Essential Worker Types
public typealias WorkerProfile = CoreTypes.WorkerProfile
public typealias WorkerCapabilities = CoreTypes.WorkerCapabilities
public typealias WorkerStatus = CoreTypes.WorkerStatus
public typealias ClockStatus = CoreTypes.ClockStatus

// Essential Task Types
public typealias ContextualTask = CoreTypes.ContextualTask
public typealias TaskStatus = CoreTypes.TaskStatus
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias TaskFrequency = CoreTypes.TaskFrequency
public typealias TaskProgress = CoreTypes.TaskProgress
public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias MaintenanceRecord = CoreTypes.MaintenanceRecord

// Location & Building Types
public typealias NamedCoordinate = CoreTypes.NamedCoordinate
public typealias BuildingType = CoreTypes.BuildingType
public typealias BuildingMetrics = CoreTypes.BuildingMetrics

// Dashboard Types
public typealias DashboardUpdate = CoreTypes.DashboardUpdate
public typealias DashboardSyncStatus = CoreTypes.DashboardSyncStatus
public typealias CrossDashboardUpdate = CoreTypes.CrossDashboardUpdate

// Client-specific Types
public typealias RealtimeRoutineMetrics = CoreTypes.RealtimeRoutineMetrics
public typealias BuildingRoutineStatus = CoreTypes.BuildingRoutineStatus
public typealias ActiveWorkerStatus = CoreTypes.ActiveWorkerStatus
public typealias MonthlyMetrics = CoreTypes.MonthlyMetrics
public typealias ComplianceStatus = CoreTypes.ComplianceStatus
public typealias ComplianceOverview = CoreTypes.ComplianceOverview
public typealias ComplianceSeverity = CoreTypes.ComplianceSeverity
public typealias ComplianceIssueType = CoreTypes.ComplianceIssueType

// Intelligence Types
public typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
public typealias InsightCategory = CoreTypes.InsightCategory
public typealias AIPriority = CoreTypes.AIPriority
public typealias AIScenario = CoreTypes.AIScenario
public typealias AIScenarioType = CoreTypes.AIScenarioType
public typealias AISuggestion = CoreTypes.AISuggestion

// Photo Types
public typealias ActionEvidence = CoreTypes.ActionEvidence
// Note: Removed duplicate typealiases to prevent compilation errors
// Use CoreTypes.TypeName for all type references

// Misc Types
public typealias SkillLevel = CoreTypes.SkillLevel
public typealias DataHealthStatus = CoreTypes.DataHealthStatus
public typealias RealtimeMetrics = CoreTypes.RealtimeMetrics
