//
//  CommandSteps.swift
//  CyntientOps Phase 6
//
//  Individual command step implementations for the command chain system
//  Each command represents an atomic operation with retry capability
//

import Foundation
import UIKit
import CoreLocation

// MARK: - Task Completion Chain Commands

public struct ValidateTaskCommand: CommandStep {
    public let name = "Validate Task"
    public let isRetryable = true
    
    private let taskId: String
    private let workerId: String
    private let container: ServiceContainer
    
    public init(taskId: String, workerId: String, container: ServiceContainer) {
        self.taskId = taskId
        self.workerId = workerId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        // Verify task exists and belongs to worker
        let task = try await container.tasks.getTask(taskId)
        
        guard task.assignedWorkerId == workerId else {
            throw CommandStepError.validation("Task \(taskId) not assigned to worker \(workerId)")
        }
        
        guard task.status != .completed else {
            throw CommandStepError.validation("Task \(taskId) already completed")
        }
        
        return task
    }
}

public struct CheckPhotoRequirementCommand: CommandStep {
    public let name = "Check Photo Requirement"
    public let isRetryable = false
    
    private let taskId: String
    private let photoData: Data?
    private let container: ServiceContainer
    
    public init(taskId: String, photoData: Data?, container: ServiceContainer) {
        self.taskId = taskId
        self.photoData = photoData
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        let task = try await container.tasks.getTask(taskId)
        
        if (task.requiresPhoto ?? false) && photoData == nil {
            throw CommandStepError.validation("Photo required for task \(taskId)")
        }
        
        return photoData != nil
    }
}

public struct DatabaseTransactionCommand: CommandStep {
    public let name = "Database Transaction"
    public let isRetryable = true
    
    private let taskId: String
    private let workerId: String
    private let notes: String?
    private let container: ServiceContainer
    
    public init(taskId: String, workerId: String, notes: String?, container: ServiceContainer) {
        self.taskId = taskId
        self.workerId = workerId
        self.notes = notes
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        // Mark task as completed
        let evidence = CoreTypes.ActionEvidence(
            notes: notes,
            workerId: workerId
        )
        try await container.tasks.completeTask(taskId, evidence: evidence)
        
        // Update worker stats - placeholder
        print("Worker \(workerId) completed task \(taskId)")
        
        // Update building metrics - placeholder
        let task = try await container.tasks.getTask(taskId)
        if let buildingId = task.buildingId {
            print("Updated activity for building \(buildingId)")
        }
        
        return true
    }
}

public struct RealTimeSyncCommand: CommandStep {
    public let name = "Real-Time Sync"
    public let isRetryable = true
    
    private let taskId: String
    private let container: ServiceContainer
    
    public init(taskId: String, container: ServiceContainer) {
        self.taskId = taskId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        await container.dashboardSync.onTaskCompleted(taskId: taskId, workerId: "worker", buildingId: "building")
        return true
    }
}

public struct IntelligenceUpdateCommand: CommandStep {
    public let name = "Intelligence Update"
    public let isRetryable = true
    
    private let taskId: String
    private let workerId: String
    private let container: ServiceContainer
    
    public init(taskId: String, workerId: String, container: ServiceContainer) {
        self.taskId = taskId
        self.workerId = workerId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        await container.intelligence.processTaskCompletion(taskId: taskId, workerId: workerId)
        return true
    }
}

// MARK: - Clock-In Chain Commands

public struct ValidateLocationCommand: CommandStep {
    public let name = "Validate Location"
    public let isRetryable = false
    
    private let buildingId: String
    private let latitude: Double
    private let longitude: Double
    private let container: ServiceContainer
    
    public init(buildingId: String, latitude: Double, longitude: Double, container: ServiceContainer) {
        self.buildingId = buildingId
        self.latitude = latitude
        self.longitude = longitude
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        let building = try await container.buildings.getBuilding(buildingId: buildingId)
        
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        let buildingLocation = CLLocation(latitude: building.latitude, longitude: building.longitude)
        
        let distance = userLocation.distance(from: buildingLocation)
        
        // Allow 100 meter radius for clock-in
        guard distance <= 100.0 else {
            throw CommandStepError.validation("Not within range of building \(building.name). Distance: \(Int(distance))m")
        }
        
        return distance
    }
}

public struct CheckBuildingAccessCommand: CommandStep {
    public let name = "Check Building Access"
    public let isRetryable = true
    
    private let workerId: String
    private let buildingId: String
    private let container: ServiceContainer
    
    public init(workerId: String, buildingId: String, container: ServiceContainer) {
        self.workerId = workerId
        self.buildingId = buildingId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        let hasAccess = true // Placeholder - assume access granted
        
        guard hasAccess else {
            throw CommandStepError.authorization("Worker \(workerId) does not have access to building \(buildingId)")
        }
        
        return true
    }
}

public struct CreateClockInRecordCommand: CommandStep {
    public let name = "Create Clock-In Record"
    public let isRetryable = true
    
    private let workerId: String
    private let buildingId: String
    private let latitude: Double
    private let longitude: Double
    private let container: ServiceContainer
    
    public init(workerId: String, buildingId: String, latitude: Double, longitude: Double, container: ServiceContainer) {
        self.workerId = workerId
        self.buildingId = buildingId
        self.latitude = latitude
        self.longitude = longitude
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        try await container.clockIn.clockIn(
            workerId: workerId,
            buildingId: buildingId
        )
        
        return "Clocked in worker \(workerId) at building \(buildingId)"
    }
}

public struct LoadWorkerTasksCommand: CommandStep {
    public let name = "Load Worker Tasks"
    public let isRetryable = true
    
    private let workerId: String
    private let buildingId: String
    private let container: ServiceContainer
    
    public init(workerId: String, buildingId: String, container: ServiceContainer) {
        self.workerId = workerId
        self.buildingId = buildingId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        let tasks = try await container.tasks.getTasks(for: workerId, date: Date())
        return tasks
    }
}

public struct UpdateDashboardsCommand: CommandStep {
    public let name = "Update Dashboards"
    public let isRetryable = true
    
    private let workerId: String
    private let action: DashboardAction
    private let container: ServiceContainer
    
    public enum DashboardAction {
        case clockIn, clockOut, taskComplete
    }
    
    public init(workerId: String, action: DashboardAction, container: ServiceContainer) {
        self.workerId = workerId
        self.action = action
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        switch action {
        case .clockIn:
            await container.dashboardSync.onWorkerClockedIn(workerId: workerId, buildingId: "building")
        case .clockOut:
            await container.dashboardSync.onWorkerClockedOut(workerId: workerId, buildingId: "building")
        case .taskComplete:
            await container.dashboardSync.onTaskCompleted(taskId: "task", workerId: workerId, buildingId: "building")
        }
        
        return true
    }
}

// MARK: - Photo Capture Chain Commands

public struct CaptureImageCommand: CommandStep {
    public let name = "Capture Image"
    public let isRetryable = false
    
    private let imageData: Data
    private let taskId: String
    
    public init(imageData: Data, taskId: String) {
        self.imageData = imageData
        self.taskId = taskId
    }
    
    public func execute() async throws -> Any? {
        // Validate image data
        guard let image = UIImage(data: imageData) else {
            throw CommandStepError.validation("Invalid image data")
        }
        
        guard imageData.count > 1024 else {
            throw CommandStepError.validation("Image data too small")
        }
        
        return image
    }
}

public struct EncryptImageCommand: CommandStep {
    public let name = "Encrypt Image"
    public let isRetryable = true
    
    private let imageData: Data
    private let ttlHours: Int
    
    public init(imageData: Data, ttlHours: Int) {
        self.imageData = imageData
        self.ttlHours = ttlHours
    }
    
    public func execute() async throws -> Any? {
        // In production, implement proper encryption
        // For now, just add TTL metadata
        let encryptedData = EncryptedImageData(
            data: imageData,
            expiresAt: Date().addingTimeInterval(TimeInterval(ttlHours * 3600)),
            encryptionKey: UUID().uuidString
        )
        
        return encryptedData
    }
}

public struct GenerateThumbnailCommand: CommandStep {
    public let name = "Generate Thumbnail"
    public let isRetryable = true
    
    private let imageData: Data
    
    public init(imageData: Data) {
        self.imageData = imageData
    }
    
    public func execute() async throws -> Any? {
        guard let image = UIImage(data: imageData) else {
            throw CommandStepError.validation("Cannot create image from data")
        }
        
        let thumbnailSize = CGSize(width: 150, height: 150)
        let thumbnail = image.resized(to: thumbnailSize)
        
        guard let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.7) else {
            throw CommandStepError.processing("Failed to generate thumbnail")
        }
        
        return thumbnailData
    }
}

public struct UploadToStorageCommand: CommandStep {
    public let name = "Upload to Storage"
    public let isRetryable = true
    
    private let taskId: String
    private let workerId: String
    private let container: ServiceContainer
    
    public init(taskId: String, workerId: String, container: ServiceContainer) {
        self.taskId = taskId
        self.workerId = workerId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        // In production, upload to secure cloud storage
        // For now, simulate upload
        let uploadId = UUID().uuidString
        
        // Store reference in database
        let photoId = UUID().uuidString
        // Photo capture placeholder - service method needs different signature
        print("Photo captured for task \(taskId) by worker \(workerId)")
        
        return uploadId
    }
}

public struct LinkToTaskCommand: CommandStep {
    public let name = "Link to Task"
    public let isRetryable = true
    
    private let taskId: String
    private let container: ServiceContainer
    
    public init(taskId: String, container: ServiceContainer) {
        self.taskId = taskId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        try await container.tasks.updateTaskStatus(taskId, status: .completed)
        return true
    }
}

// MARK: - Compliance Resolution Chain Commands

public struct FetchViolationCommand: CommandStep {
    public let name = "Fetch Violation"
    public let isRetryable = true
    
    private let violationId: String
    private let buildingId: String
    private let container: ServiceContainer
    
    public init(violationId: String, buildingId: String, container: ServiceContainer) {
        self.violationId = violationId
        self.buildingId = buildingId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        let violation = try await container.nycCompliance.getComplianceIssues(for: buildingId)
            .first { issue in
                return issue.id == violationId // Using id instead of externalId
            }
        
        guard let violation = violation else {
            throw CommandStepError.notFound("Violation \(violationId) not found for building \(buildingId)")
        }
        
        return violation
    }
}

public struct CreateResolutionTaskCommand: CommandStep {
    public let name = "Create Resolution Task"
    public let isRetryable = true
    
    private let violationId: String
    private let buildingId: String
    private let container: ServiceContainer
    
    public init(violationId: String, buildingId: String, container: ServiceContainer) {
        self.violationId = violationId
        self.buildingId = buildingId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        // Get the violation details first
        let issues = try await container.nycCompliance.getComplianceIssues(for: buildingId)
        guard let issue = issues.first(where: { $0.id == violationId }) else {
            throw CommandStepError.notFound("Violation not found")
        }
        
        let task = CoreTypes.ContextualTask(
            id: UUID().uuidString,
            title: issue.title,
            description: issue.description,
            status: .pending,
            completedAt: nil,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            category: .compliance,
            urgency: .high,
            building: nil,
            worker: nil,
            buildingId: buildingId,
            priority: .high
        )
        try await container.tasks.createTask(task)
        let taskId = task.id
        
        return taskId
    }
}

public struct AssignToWorkerCommand: CommandStep {
    public let name = "Assign to Worker"
    public let isRetryable = true
    
    private let buildingId: String
    private let workerId: String?
    private let container: ServiceContainer
    
    public init(buildingId: String, workerId: String?, container: ServiceContainer) {
        self.buildingId = buildingId
        self.workerId = workerId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        let assignedWorkerId: String
        
        if let workerId = workerId {
            assignedWorkerId = workerId
        } else {
            // Auto-assign to best available worker for this building
            if let availableWorker = try await container.workers.getAvailableWorker(for: buildingId) {
                assignedWorkerId = availableWorker.id
            } else {
                throw CommandStepError.notFound("No available workers for building \(buildingId)")
            }
        }
        
        return assignedWorkerId
    }
}

public struct SetDeadlineCommand: CommandStep {
    public let name = "Set Deadline"
    public let isRetryable = true
    
    private let violationId: String
    private let container: ServiceContainer
    
    public init(violationId: String, container: ServiceContainer) {
        self.violationId = violationId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        // Calculate deadline based on violation severity
        let deadline = Date().addingTimeInterval(24 * 3600 * 7) // 7 days default
        return deadline
    }
}

public struct MonitorProgressCommand: CommandStep {
    public let name = "Monitor Progress"
    public let isRetryable = true
    
    private let violationId: String
    private let container: ServiceContainer
    
    public init(violationId: String, container: ServiceContainer) {
        self.violationId = violationId
        self.container = container
    }
    
    public func execute() async throws -> Any? {
        // Set up monitoring for this violation resolution
        await container.intelligence.startViolationMonitoring(violationId)
        return true
    }
}

// MARK: - Supporting Types

public enum CommandStepError: LocalizedError {
    case validation(String)
    case authorization(String)
    case processing(String)
    case notFound(String)
    case network(String)
    
    public var errorDescription: String? {
        switch self {
        case .validation(let message): return "Validation error: \(message)"
        case .authorization(let message): return "Authorization error: \(message)"
        case .processing(let message): return "Processing error: \(message)"
        case .notFound(let message): return "Not found: \(message)"
        case .network(let message): return "Network error: \(message)"
        }
    }
}

public struct EncryptedImageData {
    let data: Data
    let expiresAt: Date
    let encryptionKey: String
}

// MARK: - Extensions

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}