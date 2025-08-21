//
//  AdminOperationalIntelligence.swift
//  CyntientOps
//
//  🎯 ENHANCED ADMIN OPERATIONAL INTELLIGENCE
//  ✅ Routine completion tracking (bins, cleaning, maintenance)
//  ✅ Building vendor/inspector repository system
//  ✅ Worker access logging for 3rd party interactions
//  ✅ Real-time sync integration for operational updates
//  ✅ Recurring task reminder system

import Foundation
import SwiftUI
import Combine

// MARK: - Admin Operational Intelligence Protocol
public protocol AdminOperationalIntelligenceProtocol: ObservableObject {
    func addWorkerNote(workerId: String, buildingId: String, noteText: String, category: String, photoEvidence: String?, location: String?) async
    func logSupplyRequest(workerId: String, buildingId: String, requestNumber: String, items: String, priority: String, notes: String) async
}

// MARK: - Admin Operational Intelligence Service

@MainActor
public class AdminOperationalIntelligence: ObservableObject, AdminOperationalIntelligenceProtocol {
    public static var shared: AdminOperationalIntelligence?
    
    // MARK: - Published State
    @Published public var routineCompletions: [String: RoutineCompletionStatus] = [:]
    @Published public var buildingVendorRepositories: [String: BuildingVendorRepository] = [:]
    @Published public var pendingReminders: [RecurringTaskReminder] = []
    @Published public var recentVendorAccess: [VendorAccessLog] = []
    @Published public var criticalRoutineAlerts: [RoutineAlert] = []
    
    // MARK: - Private Properties
    private let container: ServiceContainer
    private let dashboardSync: DashboardSyncService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(container: ServiceContainer, dashboardSync: DashboardSyncService) {
        self.container = container
        self.dashboardSync = dashboardSync
        setupRealTimeTracking()
        
        // Set as shared instance
        AdminOperationalIntelligence.shared = self
    }
    
    // MARK: - Routine Completion Intelligence
    
    /// Track bin placement/retrieval completion
    public func trackBinPlacementCompletion(
        workerId: String,
        buildingId: String,
        binType: BinType,
        action: BinAction,
        location: BinLocation,
        timestamp: Date = Date(),
        photoEvidence: String? = nil
    ) async {
        let completion = BinPlacementCompletion(
            id: UUID().uuidString,
            workerId: workerId,
            buildingId: buildingId,
            binType: binType,
            action: action,
            location: location,
            timestamp: timestamp,
            photoEvidence: photoEvidence
        )
        
        // Update routine completion status
        await updateRoutineCompletion(for: buildingId, completion: completion)
        
        // Broadcast to admin dashboard
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .routineCompleted,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "completionType": "bin_placement",
                "binType": binType.rawValue,
                "action": action.rawValue,
                "location": location.rawValue,
                "timestamp": ISO8601DateFormatter().string(from: timestamp),
                "hasPhotoEvidence": photoEvidence != nil ? "true" : "false"
            ]
        )
        
        dashboardSync.broadcastWorkerUpdate(update)
        
        // Check for completion of full routine
        await checkRoutineFullCompletion(buildingId: buildingId, workerId: workerId)
    }
    
    /// Track cleaning routine completion
    public func trackCleaningRoutineCompletion(
        workerId: String,
        buildingId: String,
        cleaningType: CleaningType,
        areas: [String],
        completionStatus: CompletionStatus,
        timestamp: Date = Date(),
        photoEvidence: [String] = []
    ) async {
        let completion = CleaningRoutineCompletion(
            id: UUID().uuidString,
            workerId: workerId,
            buildingId: buildingId,
            cleaningType: cleaningType,
            areas: areas,
            completionStatus: completionStatus,
            timestamp: timestamp,
            photoEvidence: photoEvidence
        )
        
        await updateRoutineCompletion(for: buildingId, completion: completion)
        
        // Broadcast update
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .routineCompleted,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "completionType": "cleaning_routine",
                "cleaningType": cleaningType.rawValue,
                "areasCompleted": areas.joined(separator: ","),
                "completionStatus": completionStatus.rawValue,
                "photoCount": "\(photoEvidence.count)"
            ]
        )
        
        dashboardSync.broadcastWorkerUpdate(update)
    }
    
    // MARK: - Building Vendor Repository System
    
    /// Register vendor access by worker
    public func logVendorAccess(
        workerId: String,
        buildingId: String,
        vendorInfo: VendorInfo,
        accessType: VendorAccessType,
        accessDetails: String,
        timestamp: Date = Date(),
        photoEvidence: String? = nil
    ) async {
        let accessLog = VendorAccessLog(
            id: UUID().uuidString,
            workerId: workerId,
            buildingId: buildingId,
            vendorInfo: vendorInfo,
            accessType: accessType,
            accessDetails: accessDetails,
            timestamp: timestamp,
            photoEvidence: photoEvidence
        )
        
        // Add to recent access logs
        recentVendorAccess.insert(accessLog, at: 0)
        if recentVendorAccess.count > 50 {
            recentVendorAccess.removeLast()
        }
        
        // Update building vendor repository
        await updateBuildingVendorRepository(buildingId: buildingId, accessLog: accessLog)
        
        // Broadcast to admin dashboard
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .vendorAccess,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "vendorName": vendorInfo.name,
                "vendorType": vendorInfo.type.rawValue,
                "accessType": accessType.rawValue,
                "accessDetails": accessDetails,
                "timestamp": ISO8601DateFormatter().string(from: timestamp),
                "hasPhotoEvidence": photoEvidence != nil ? "true" : "false"
            ]
        )
        
        dashboardSync.broadcastWorkerUpdate(update)
        
        // Check if this completes any pending vendor requirements
        await checkVendorAccessRequirements(buildingId: buildingId, vendorInfo: vendorInfo)
    }
    
    /// Get building vendor repository
    public func getBuildingVendorRepository(buildingId: String) -> BuildingVendorRepository? {
        return buildingVendorRepositories[buildingId]
    }
    
    /// Add expected vendor/inspector to building
    public func addExpectedVendor(
        buildingId: String,
        vendorInfo: VendorInfo,
        expectedDate: Date,
        accessRequirements: [String],
        notes: String = ""
    ) async {
        var repository = buildingVendorRepositories[buildingId] ?? BuildingVendorRepository(
            buildingId: buildingId,
            expectedVendors: [],
            accessHistory: [],
            recurringVendors: []
        )
        
        let expectedVendor = ExpectedVendor(
            id: UUID().uuidString,
            vendorInfo: vendorInfo,
            expectedDate: expectedDate,
            accessRequirements: accessRequirements,
            status: .pending,
            notes: notes
        )
        
        repository.expectedVendors.append(expectedVendor)
        buildingVendorRepositories[buildingId] = repository
        
        // Create reminder for admin
        let reminder = RecurringTaskReminder(
            id: UUID().uuidString,
            buildingId: buildingId,
            reminderType: .vendorExpected,
            title: "Vendor Expected: \(vendorInfo.name)",
            description: "Prepare access for \(vendorInfo.type.rawValue)",
            dueDate: expectedDate,
            isActive: true,
            metadata: ["vendorId": vendorInfo.id]
        )
        
        pendingReminders.append(reminder)
    }
    
    // MARK: - Recurring Task Reminder System
    
    /// Generate recurring task reminders
    public func generateRecurringTaskReminders() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Check for weekly tasks due
        await generateWeeklyTaskReminders(for: today)
        
        // Check for monthly tasks due
        await generateMonthlyTaskReminders(for: today)
        
        // Check for seasonal tasks due
        await generateSeasonalTaskReminders(for: today)
        
        // Sort reminders by priority and due date
        pendingReminders.sort { reminder1, reminder2 in
            if reminder1.dueDate != reminder2.dueDate {
                return reminder1.dueDate < reminder2.dueDate
            }
            return reminder1.reminderType.priority > reminder2.reminderType.priority
        }
    }
    
    // MARK: - Worker Integration Methods
    
    /// Add a worker note to operational intelligence
    public func addWorkerNote(
        workerId: String,
        buildingId: String,
        noteText: String,
        category: String,
        photoEvidence: String? = nil,
        location: String? = nil
    ) async {
        // Store worker note and sync to dashboard
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerNote,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "noteText": noteText,
                "category": category,
                "location": location ?? "",
                "hasPhoto": photoEvidence != nil ? "true" : "false"
            ]
        )
        
        dashboardSync.broadcastWorkerUpdate(update)
        logInfo("✅ Worker note added to operational intelligence: \(category)")
    }
    
    /// Log a supply request from workers
    public func logSupplyRequest(
        workerId: String,
        buildingId: String,
        requestNumber: String,
        items: String,
        priority: String,
        notes: String
    ) async {
        // Store supply request and notify admin
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .inventoryUpdated,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "requestNumber": requestNumber,
                "items": items,
                "priority": priority,
                "notes": notes,
                "action": "supply_request_created"
            ]
        )
        
        dashboardSync.broadcastWorkerUpdate(update)
        logInfo("✅ Supply request logged: \(requestNumber)")
    }
    
    private func generateWeeklyTaskReminders(for date: Date) async {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Get all buildings
        let buildings = try? await container.buildings.getAllBuildings()
        
        for building in buildings ?? [] {
            // Weekly deep cleaning reminders
            if weekday == 2 { // Monday
                let reminder = RecurringTaskReminder(
                    id: UUID().uuidString,
                    buildingId: building.id,
                    reminderType: .weeklyDeepClean,
                    title: "Weekly Deep Clean Due",
                    description: "Trash areas and common spaces deep cleaning",
                    dueDate: date,
                    isActive: true,
                    metadata: ["building": building.name]
                )
                pendingReminders.append(reminder)
            }
            
            // DSNY bin positioning reminders (Sunday/Tuesday/Thursday)
            if [1, 3, 5].contains(weekday) {
                let reminder = RecurringTaskReminder(
                    id: UUID().uuidString,
                    buildingId: building.id,
                    reminderType: .dsnyBinReminder,
                    title: "DSNY Bin Placement Due",
                    description: "Place bins curbside after 8 PM",
                    dueDate: Calendar.current.date(byAdding: .hour, value: 20, to: date) ?? date,
                    isActive: true,
                    metadata: ["building": building.name, "collection_day": "true"]
                )
                pendingReminders.append(reminder)
            }
        }
    }
    
    private func generateMonthlyTaskReminders(for date: Date) async {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        
        // First of month - compliance reviews
        if day == 1 {
            let buildings = try? await container.buildings.getAllBuildings()
            
            for building in buildings ?? [] {
                let reminder = RecurringTaskReminder(
                    id: UUID().uuidString,
                    buildingId: building.id,
                    reminderType: .monthlyCompliance,
                    title: "Monthly Compliance Review",
                    description: "Review building compliance status and violations",
                    dueDate: date,
                    isActive: true,
                    metadata: ["building": building.name, "month": DateFormatter().monthSymbols[calendar.component(.month, from: date) - 1]]
                )
                pendingReminders.append(reminder)
            }
        }
    }
    
    private func generateSeasonalTaskReminders(for date: Date) async {
        // Seasonal task generation logic would go here
        // Winter: heating system checks, snow removal prep
        // Spring: exterior cleaning, landscaping
        // Summer: AC maintenance, pest control
        // Fall: leaf removal, heating prep
    }
    
    // MARK: - Private Helper Methods
    
    private func updateRoutineCompletion(for buildingId: String, completion: Any) async {
        // Update routine completion status for building
        var status = routineCompletions[buildingId] ?? RoutineCompletionStatus(
            buildingId: buildingId,
            lastUpdated: Date(),
            binPlacements: [],
            cleaningCompletions: [],
            maintenanceCompletions: [],
            overallCompletionRate: 0.0
        )
        
        if let binCompletion = completion as? BinPlacementCompletion {
            status.binPlacements.append(binCompletion)
        } else if let cleaningCompletion = completion as? CleaningRoutineCompletion {
            status.cleaningCompletions.append(cleaningCompletion)
        }
        
        status.lastUpdated = Date()
        status.overallCompletionRate = calculateCompletionRate(for: status)
        
        routineCompletions[buildingId] = status
    }
    
    private func checkRoutineFullCompletion(buildingId: String, workerId: String) async {
        guard let status = routineCompletions[buildingId] else { return }
        
        // Check if all routine tasks are completed for the day
        let today = Calendar.current.startOfDay(for: Date())
        let todayCompletions = status.getTodaysCompletions()
        
        if todayCompletions.isFullyComplete {
            // Broadcast routine completion alert
            let update = CoreTypes.DashboardUpdate(
                source: .worker,
                type: .routineFullyCompleted,
                buildingId: buildingId,
                workerId: workerId,
                data: [
                    "completionTime": ISO8601DateFormatter().string(from: Date()),
                    "totalTasks": "\(todayCompletions.totalTasks)",
                    "completionRate": "\(Int(status.overallCompletionRate * 100))%"
                ]
            )
            
            dashboardSync.broadcastWorkerUpdate(update)
        }
    }
    
    private func updateBuildingVendorRepository(buildingId: String, accessLog: VendorAccessLog) async {
        var repository = buildingVendorRepositories[buildingId] ?? BuildingVendorRepository(
            buildingId: buildingId,
            expectedVendors: [],
            accessHistory: [],
            recurringVendors: []
        )
        
        repository.accessHistory.append(accessLog)
        
        // Keep only last 100 access logs per building
        if repository.accessHistory.count > 100 {
            repository.accessHistory.removeFirst(repository.accessHistory.count - 100)
        }
        
        buildingVendorRepositories[buildingId] = repository
    }
    
    private func checkVendorAccessRequirements(buildingId: String, vendorInfo: VendorInfo) async {
        guard var repository = buildingVendorRepositories[buildingId] else { return }
        
        // Update expected vendor status if access was provided
        for i in 0..<repository.expectedVendors.count {
            if repository.expectedVendors[i].vendorInfo.id == vendorInfo.id &&
               repository.expectedVendors[i].status == .pending {
                repository.expectedVendors[i].status = .accessProvided
                repository.expectedVendors[i].accessProvidedAt = Date()
                
                // Remove corresponding reminder
                pendingReminders.removeAll { reminder in
                    reminder.reminderType == .vendorExpected &&
                    reminder.metadata["vendorId"] == vendorInfo.id
                }
                
                break
            }
        }
        
        buildingVendorRepositories[buildingId] = repository
    }
    
    private func calculateCompletionRate(for status: RoutineCompletionStatus) -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        let todayCompletions = status.getTodaysCompletions()
        
        return todayCompletions.totalTasks > 0 ? 
            Double(todayCompletions.completedTasks) / Double(todayCompletions.totalTasks) : 0.0
    }
    
    private func setupRealTimeTracking() {
        // Subscribe to cross-dashboard updates for routine tracking
        dashboardSync.crossDashboardUpdates
            .sink { [weak self] update in
                Task { @MainActor in
                    await self?.processRealTimeUpdate(update)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processRealTimeUpdate(_ update: CoreTypes.DashboardUpdate) async {
        switch update.type {
        case .routineStarted:
            // Track routine start for completion monitoring
            break
        case .taskCompleted:
            // Check if task completion affects routine status
            if let buildingId = update.buildingId {
                await checkRoutineFullCompletion(buildingId: buildingId, workerId: update.workerId ?? "")
            }
            break
        default:
            break
        }
    }
}

// MARK: - Supporting Data Structures

public enum BinType: String, CaseIterable, Codable {
    case trash = "trash"
    case recycling = "recycling"
    case organics = "organics"
    case cardboard = "cardboard"
}

public enum BinAction: String, CaseIterable, Codable {
    case placedCurbside = "placed_curbside"
    case retrievedInside = "retrieved_inside"
    case emptied = "emptied"
    case cleaned = "cleaned"
}

public enum BinLocation: String, CaseIterable, Codable {
    case curbside = "curbside"
    case trashRoom = "trash_room"
    case basement = "basement"
    case courtyard = "courtyard"
}

public enum CleaningType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case deep = "deep"
    case maintenance = "maintenance"
}

public enum CompletionStatus: String, CaseIterable, Codable {
    case completed = "completed"
    case partial = "partial"
    case skipped = "skipped"
    case delayed = "delayed"
}

public enum VendorAccessType: String, CaseIterable, Codable {
    case scheduled = "scheduled"
    case emergency = "emergency"
    case routine = "routine"
    case inspection = "inspection"
}

public enum VendorType: String, CaseIterable, Codable {
    case inspector = "inspector"
    case maintenance = "maintenance"
    case contractor = "contractor"
    case utility = "utility"
    case pest_control = "pest_control"
    case hvac = "hvac"
    case plumbing = "plumbing"
    case electrical = "electrical"
    case other = "other"
}

public struct BinPlacementCompletion: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let buildingId: String
    public let binType: BinType
    public let action: BinAction
    public let location: BinLocation
    public let timestamp: Date
    public let photoEvidence: String?
}

public struct CleaningRoutineCompletion: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let buildingId: String
    public let cleaningType: CleaningType
    public let areas: [String]
    public let completionStatus: CompletionStatus
    public let timestamp: Date
    public let photoEvidence: [String]
}

public struct VendorInfo: Identifiable, Codable {
    public let id: String
    public let name: String
    public let type: VendorType
    public let company: String
    public let contactInfo: String
    public let certifications: [String]
}

public struct VendorAccessLog: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let buildingId: String
    public let vendorInfo: VendorInfo
    public let accessType: VendorAccessType
    public let accessDetails: String
    public let timestamp: Date
    public let photoEvidence: String?
}

public struct ExpectedVendor: Identifiable, Codable {
    public let id: String
    public let vendorInfo: VendorInfo
    public let expectedDate: Date
    public let accessRequirements: [String]
    public var status: ExpectedVendorStatus
    public let notes: String
    public var accessProvidedAt: Date?
    
    public enum ExpectedVendorStatus: String, Codable {
        case pending = "pending"
        case accessProvided = "access_provided"
        case completed = "completed"
        case missed = "missed"
    }
}

public struct BuildingVendorRepository: Codable {
    public let buildingId: String
    public var expectedVendors: [ExpectedVendor]
    public var accessHistory: [VendorAccessLog]
    public var recurringVendors: [VendorInfo]
}

public struct RecurringTaskReminder: Identifiable, Codable {
    public let id: String
    public let buildingId: String
    public let reminderType: ReminderType
    public let title: String
    public let description: String
    public let dueDate: Date
    public var isActive: Bool
    public let metadata: [String: String]
    
    public enum ReminderType: String, CaseIterable, Codable {
        case weeklyDeepClean = "weekly_deep_clean"
        case monthlyCompliance = "monthly_compliance"
        case dsnyBinReminder = "dsny_bin_reminder"
        case vendorExpected = "vendor_expected"
        case maintenanceCheck = "maintenance_check"
        case seasonalTask = "seasonal_task"
        
        var priority: Int {
            switch self {
            case .vendorExpected: return 5
            case .dsnyBinReminder: return 4
            case .monthlyCompliance: return 3
            case .weeklyDeepClean: return 2
            case .maintenanceCheck: return 2
            case .seasonalTask: return 1
            }
        }
    }
}

public struct RoutineCompletionStatus: Codable {
    public let buildingId: String
    public var lastUpdated: Date
    public var binPlacements: [BinPlacementCompletion]
    public var cleaningCompletions: [CleaningRoutineCompletion]
    public var maintenanceCompletions: [Any] // Would be typed properly
    public var overallCompletionRate: Double
    
    public func getTodaysCompletions() -> (totalTasks: Int, completedTasks: Int, isFullyComplete: Bool) {
        let today = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current
        
        let todayBins = binPlacements.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        let todayCleaning = cleaningCompletions.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        
        let totalTasks = 10 // Mock - would calculate expected daily tasks
        let completedTasks = todayBins.count + todayCleaning.count
        
        return (totalTasks: totalTasks, completedTasks: completedTasks, isFullyComplete: completedTasks >= totalTasks)
    }
}

public struct RoutineAlert: Identifiable {
    public let id: String
    public let buildingId: String
    public let alertType: AlertType
    public let message: String
    public let timestamp: Date
    public let severity: Severity
    
    public enum AlertType: String, CaseIterable {
        case routineBehindSchedule = "routine_behind_schedule"
        case vendorMissed = "vendor_missed"
        case binNotRetrieved = "bin_not_retrieved"
        case cleaningOverdue = "cleaning_overdue"
    }
    
    public enum Severity: String, CaseIterable {
        case low, medium, high, critical
    }
}

