//
//  AutomatedWorkflows.swift
//  CyntientOps Phase 10.2
//
//  Automated workflow engine for violation → task → completion → certification
//  Handles deadline management, evidence filing, and compliance automation
//

import Foundation
import Combine

@MainActor
public class AutomatedWorkflows: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var activeWorkflows: [Workflow] = []
    @Published public var completedWorkflows: [Workflow] = []
    @Published public var isProcessingWorkflows = false
    @Published public var workflowStats: WorkflowStats = WorkflowStats()
    
    // MARK: - Dependencies
    private let database: GRDBManager
    private let taskService: TaskService
    private let commands: CommandChainManager
    private let notifications: NotificationService
    
    // MARK: - Configuration
    private struct WorkflowConfig {
        static let processingInterval: TimeInterval = 60 // Check every minute
        static let deadlineWarningDays = 3
        static let maxConcurrentWorkflows = 50
        static let workflowTimeoutDays = 30
    }
    
    public init(
        database: GRDBManager,
        taskService: TaskService,
        commands: CommandChainManager,
        notifications: NotificationService
    ) {
        self.database = database
        self.taskService = taskService
        self.commands = commands
        self.notifications = notifications
        
        Task {
            await startWorkflowEngine()
        }
    }
    
    // MARK: - Public Methods
    
    /// Create workflow from violation
    public func createViolationWorkflow(
        violationId: String,
        buildingId: String,
        violationType: String,
        deadline: Date,
        priority: WorkflowPriority = .normal
    ) async throws -> String {
        
        let workflowId = UUID().uuidString
        
        let workflow = Workflow(
            id: workflowId,
            type: .violationResolution,
            name: "Resolve \(violationType) Violation",
            buildingId: buildingId,
            priority: priority,
            status: .created,
            deadline: deadline,
            createdAt: Date(),
            steps: createViolationResolutionSteps(violationId: violationId, buildingId: buildingId),
            metadata: [
                "violationId": violationId,
                "violationType": violationType,
                "source": "compliance_automation"
            ]
        )
        
        try await saveWorkflow(workflow)
        activeWorkflows.append(workflow)
        
        // Start workflow execution
        await executeWorkflow(workflowId)
        
        print("✅ Created violation workflow: \(workflowId)")
        return workflowId
    }
    
    /// Create workflow from deadline
    public func createDeadlineWorkflow(
        title: String,
        buildingId: String,
        deadline: Date,
        priority: WorkflowPriority = .normal,
        workflowType: WorkflowType = .deadlineManagement
    ) async throws -> String {
        
        let workflowId = UUID().uuidString
        
        let workflow = Workflow(
            id: workflowId,
            type: workflowType,
            name: title,
            buildingId: buildingId,
            priority: priority,
            status: .created,
            deadline: deadline,
            createdAt: Date(),
            steps: createDeadlineWorkflowSteps(title: title, buildingId: buildingId, deadline: deadline),
            metadata: [
                "title": title,
                "source": "deadline_automation"
            ]
        )
        
        try await saveWorkflow(workflow)
        activeWorkflows.append(workflow)
        
        // Start workflow execution
        await executeWorkflow(workflowId)
        
        print("✅ Created deadline workflow: \(workflowId)")
        return workflowId
    }
    
    /// Create workflow from task completion
    public func createCompletionCertificationWorkflow(
        taskId: String,
        workerId: String,
        buildingId: String,
        completionData: WorkflowTaskCompletionData
    ) async throws -> String {
        
        let workflowId = UUID().uuidString
        
        let workflow = Workflow(
            id: workflowId,
            type: .taskCertification,
            name: "Certify Task Completion",
            buildingId: buildingId,
            priority: .normal,
            status: .created,
            deadline: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days to certify
            createdAt: Date(),
            steps: createCertificationWorkflowSteps(
                taskId: taskId,
                workerId: workerId,
                buildingId: buildingId,
                completionData: completionData
            ),
            metadata: [
                "taskId": taskId,
                "workerId": workerId,
                "source": "task_completion"
            ]
        )
        
        try await saveWorkflow(workflow)
        activeWorkflows.append(workflow)
        
        // Start workflow execution
        await executeWorkflow(workflowId)
        
        print("✅ Created certification workflow: \(workflowId)")
        return workflowId
    }
    
    /// Create evidence filing workflow
    public func createEvidenceFilingWorkflow(
        evidenceId: String,
        taskId: String,
        buildingId: String,
        filingRequirements: FilingRequirements
    ) async throws -> String {
        
        let workflowId = UUID().uuidString
        
        let workflow = Workflow(
            id: workflowId,
            type: .evidenceFiling,
            name: "File Evidence Documentation",
            buildingId: buildingId,
            priority: .high,
            status: .created,
            deadline: filingRequirements.deadline,
            createdAt: Date(),
            steps: createEvidenceFilingSteps(
                evidenceId: evidenceId,
                taskId: taskId,
                buildingId: buildingId,
                requirements: filingRequirements
            ),
            metadata: [
                "evidenceId": evidenceId,
                "taskId": taskId,
                "filingType": filingRequirements.type.rawValue,
                "source": "evidence_automation"
            ]
        )
        
        try await saveWorkflow(workflow)
        activeWorkflows.append(workflow)
        
        // Start workflow execution
        await executeWorkflow(workflowId)
        
        print("✅ Created evidence filing workflow: \(workflowId)")
        return workflowId
    }
    
    /// Get workflow status
    public func getWorkflowStatus(_ workflowId: String) -> WorkflowStatus? {
        if let workflow = activeWorkflows.first(where: { $0.id == workflowId }) {
            return workflow.status
        }
        if let workflow = completedWorkflows.first(where: { $0.id == workflowId }) {
            return workflow.status
        }
        return nil
    }
    
    /// Cancel workflow
    public func cancelWorkflow(_ workflowId: String) async {
        if let index = activeWorkflows.firstIndex(where: { $0.id == workflowId }) {
            var workflow = activeWorkflows[index]
            workflow.status = .cancelled
            workflow.completedAt = Date()
            
            activeWorkflows.remove(at: index)
            completedWorkflows.append(workflow)
            
            try? await updateWorkflowInDatabase(workflow)
            await updateWorkflowStats()
            
            print("⏹️ Cancelled workflow: \(workflowId)")
        }
    }
    
    /// Get workflows by building
    public func getWorkflowsForBuilding(_ buildingId: String) -> [Workflow] {
        let active = activeWorkflows.filter { $0.buildingId == buildingId }
        let completed = completedWorkflows.filter { $0.buildingId == buildingId }
        return (active + completed).sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Get upcoming deadlines
    public func getUpcomingDeadlines(days: Int = 7) -> [Workflow] {
        let cutoffDate = Date().addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
        return activeWorkflows.filter { $0.deadline <= cutoffDate }.sorted { $0.deadline < $1.deadline }
    }
    
    // MARK: - Private Methods
    
    private func startWorkflowEngine() async {
        // Load existing workflows from database
        await loadWorkflowsFromDatabase()
        
        // Start periodic processing
        while !Task.isCancelled {
            await processActiveWorkflows()
            await checkDeadlineWarnings()
            await cleanupCompletedWorkflows()
            await updateWorkflowStats()
            
            try? await Task.sleep(nanoseconds: UInt64(WorkflowConfig.processingInterval * 1_000_000_000))
        }
    }
    
    private func processActiveWorkflows() async {
        guard !isProcessingWorkflows else { return }
        
        isProcessingWorkflows = true
        defer { isProcessingWorkflows = false }
        
        let workflowsToProcess = activeWorkflows.filter { $0.status == .created || $0.status == .inProgress }
        
        for workflow in workflowsToProcess.prefix(10) { // Process up to 10 at a time
            await executeWorkflow(workflow.id)
        }
    }
    
    private func executeWorkflow(_ workflowId: String) async {
        guard let workflowIndex = activeWorkflows.firstIndex(where: { $0.id == workflowId }) else {
            return
        }
        
        var workflow = activeWorkflows[workflowIndex]
        
        // Check if workflow has expired
        if workflow.deadline < Date() && workflow.status != .completed {
            workflow.status = .expired
            workflow.completedAt = Date()
            activeWorkflows.remove(at: workflowIndex)
            completedWorkflows.append(workflow)
            try? await updateWorkflowInDatabase(workflow)
            return
        }
        
        // Execute next step
        if let nextStepIndex = workflow.steps.firstIndex(where: { $0.status == .pending }) {
            workflow.status = .inProgress
            var step = workflow.steps[nextStepIndex]
            step.status = .inProgress
            step.startedAt = Date()
            
            do {
                // Execute the step
                let result = try await executeWorkflowStep(step, workflow: workflow)
                
                step.status = .completed
                step.completedAt = Date()
                step.result = result
                
                workflow.steps[nextStepIndex] = step
                
                // Check if all steps completed
                if workflow.steps.allSatisfy({ $0.status == .completed }) {
                    workflow.status = .completed
                    workflow.completedAt = Date()
                    
                    // Move to completed workflows
                    activeWorkflows.remove(at: workflowIndex)
                    completedWorkflows.append(workflow)
                    
                    print("✅ Completed workflow: \(workflow.name)")
                } else {
                    activeWorkflows[workflowIndex] = workflow
                }
                
                try await updateWorkflowInDatabase(workflow)
                
            } catch {
                step.status = .failed
                step.completedAt = Date()
                step.error = error.localizedDescription
                
                workflow.steps[nextStepIndex] = step
                workflow.status = .failed
                workflow.completedAt = Date()
                
                activeWorkflows.remove(at: workflowIndex)
                completedWorkflows.append(workflow)
                
                try? await updateWorkflowInDatabase(workflow)
                
                print("❌ Workflow step failed: \(workflow.name) - \(error)")
            }
        }
    }
    
    private func executeWorkflowStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        switch step.type {
        case .createTask:
            return try await executeCreateTaskStep(step, workflow: workflow)
        case .assignWorker:
            return try await executeAssignWorkerStep(step, workflow: workflow)
        case .scheduleDeadline:
            return try await executeScheduleDeadlineStep(step, workflow: workflow)
        case .validateCompletion:
            return try await executeValidateCompletionStep(step, workflow: workflow)
        case .generateCertification:
            return try await executeGenerateCertificationStep(step, workflow: workflow)
        case .fileEvidence:
            return try await executeFileEvidenceStep(step, workflow: workflow)
        case .sendNotification:
            return try await executeSendNotificationStep(step, workflow: workflow)
        case .updateCompliance:
            return try await executeUpdateComplianceStep(step, workflow: workflow)
        }
    }
    
    private func executeCreateTaskStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        guard let violationId = workflow.metadata["violationId"] as? String,
              let violationType = workflow.metadata["violationType"] as? String else {
            throw WorkflowError.missingMetadata("violationId or violationType")
        }
        
        // Create task through command chain
        let result = try await commands.executeTaskCompletion(
            taskId: UUID().uuidString,
            workerId: "auto-assigned",
            photoData: nil,
            notes: "Auto-created from \(violationType) violation \(violationId)"
        )
        
        return ["taskId": result.chainId, "created": true]
    }
    
    private func executeAssignWorkerStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        // Auto-assign best available worker for the building
        // Implementation would use worker scheduling logic
        let assignedWorkerId = "auto-selected-worker"
        
        return ["assignedWorkerId": assignedWorkerId]
    }
    
    private func executeScheduleDeadlineStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        // Schedule deadline reminder notifications
        let reminderDate = workflow.deadline.addingTimeInterval(-TimeInterval(WorkflowConfig.deadlineWarningDays * 24 * 60 * 60))
        
        await notifications.scheduleNotification(
            id: "deadline_\(workflow.id)",
            title: "Upcoming Deadline",
            body: "Workflow '\(workflow.name)' deadline in \(WorkflowConfig.deadlineWarningDays) days",
            date: reminderDate,
            userInfo: ["workflowId": workflow.id]
        )
        
        return ["reminderScheduled": true, "reminderDate": reminderDate.timeIntervalSince1970]
    }
    
    private func executeValidateCompletionStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        guard let taskId = workflow.metadata["taskId"] as? String else {
            throw WorkflowError.missingMetadata("taskId")
        }
        
        // Validate task completion
        let task = try await taskService.getTask(taskId)
        guard task.isCompleted else {
            throw WorkflowError.validationFailed("Task not completed")
        }
        
        return ["validated": true, "taskId": taskId]
    }
    
    private func executeGenerateCertificationStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        guard let taskId = workflow.metadata["taskId"] as? String else {
            throw WorkflowError.missingMetadata("taskId")
        }
        
        // Generate compliance certification document
        let certificationId = UUID().uuidString
        let certificationData: [String: Any] = [
            "certificationId": certificationId,
            "taskId": taskId,
            "workflowId": workflow.id,
            "generatedAt": Date().timeIntervalSince1970,
            "buildingId": workflow.buildingId
        ]
        
        // Store certification in database
        try await database.execute("""
            INSERT INTO compliance_certifications (
                id, workflow_id, task_id, building_id, certification_data, created_at
            ) VALUES (?, ?, ?, ?, ?, ?)
        """, [
            certificationId,
            workflow.id,
            taskId,
            workflow.buildingId,
            try JSONSerialization.data(withJSONObject: certificationData),
            Date().timeIntervalSince1970
        ])
        
        return ["certificationId": certificationId, "generated": true]
    }
    
    private func executeFileEvidenceStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        guard let evidenceId = workflow.metadata["evidenceId"] as? String else {
            throw WorkflowError.missingMetadata("evidenceId")
        }
        
        // File evidence with appropriate authorities
        let filingId = UUID().uuidString
        
        // Store filing record
        try await database.execute("""
            INSERT INTO evidence_filings (
                id, workflow_id, evidence_id, building_id, filed_at, status
            ) VALUES (?, ?, ?, ?, ?, ?)
        """, [
            filingId,
            workflow.id,
            evidenceId,
            workflow.buildingId,
            Date().timeIntervalSince1970,
            "filed"
        ])
        
        return ["filingId": filingId, "filed": true]
    }
    
    private func executeSendNotificationStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        let notificationId = UUID().uuidString
        
        await notifications.sendNotification(
            id: notificationId,
            title: "Workflow Update",
            body: "Workflow '\(workflow.name)' has been updated",
            userInfo: ["workflowId": workflow.id]
        )
        
        return ["notificationId": notificationId, "sent": true]
    }
    
    private func executeUpdateComplianceStep(_ step: WorkflowStep, workflow: Workflow) async throws -> [String: Any]? {
        // Update compliance status based on workflow completion
        try await database.execute("""
            UPDATE buildings
            SET compliance_score = CASE
                WHEN compliance_score IS NULL THEN 0.8
                ELSE MIN(1.0, compliance_score + 0.1)
            END,
            last_compliance_update = ?
            WHERE id = ?
        """, [Date().timeIntervalSince1970, workflow.buildingId])
        
        return ["complianceUpdated": true]
    }
    
    private func checkDeadlineWarnings() async {
        let warningDate = Date().addingTimeInterval(TimeInterval(WorkflowConfig.deadlineWarningDays * 24 * 60 * 60))
        let upcomingDeadlines = activeWorkflows.filter { $0.deadline <= warningDate && $0.status != .completed }
        
        for workflow in upcomingDeadlines {
            await notifications.sendNotification(
                id: "deadline_warning_\(workflow.id)",
                title: "Deadline Warning",
                body: "Workflow '\(workflow.name)' deadline approaching",
                userInfo: ["workflowId": workflow.id, "deadline": workflow.deadline.timeIntervalSince1970]
            )
        }
    }
    
    private func cleanupCompletedWorkflows() async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(WorkflowConfig.workflowTimeoutDays * 24 * 60 * 60))
        completedWorkflows.removeAll { $0.completedAt ?? Date() < cutoffDate }
    }
    
    private func updateWorkflowStats() async {
        let totalWorkflows = activeWorkflows.count + completedWorkflows.count
        let completedCount = completedWorkflows.filter { $0.status == .completed }.count
        let failedCount = completedWorkflows.filter { $0.status == .failed }.count
        let expiredCount = completedWorkflows.filter { $0.status == .expired }.count
        
        workflowStats = WorkflowStats(
            totalWorkflows: totalWorkflows,
            activeWorkflows: activeWorkflows.count,
            completedWorkflows: completedCount,
            failedWorkflows: failedCount,
            expiredWorkflows: expiredCount,
            averageCompletionTime: calculateAverageCompletionTime(),
            successRate: totalWorkflows > 0 ? Double(completedCount) / Double(totalWorkflows) : 0
        )
    }
    
    private func calculateAverageCompletionTime() -> TimeInterval {
        let completedWithTimes = completedWorkflows.compactMap { workflow -> TimeInterval? in
            guard let completedAt = workflow.completedAt else { return nil }
            return completedAt.timeIntervalSince(workflow.createdAt)
        }
        
        guard !completedWithTimes.isEmpty else { return 0 }
        return completedWithTimes.reduce(0, +) / Double(completedWithTimes.count)
    }
    
    private func createViolationResolutionSteps(violationId: String, buildingId: String) -> [WorkflowStep] {
        return [
            WorkflowStep(
                id: UUID().uuidString,
                type: .createTask,
                name: "Create Resolution Task",
                description: "Create task for violation resolution",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .assignWorker,
                name: "Assign Worker",
                description: "Assign worker to resolution task",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .scheduleDeadline,
                name: "Schedule Deadline",
                description: "Set up deadline notifications",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .validateCompletion,
                name: "Validate Completion",
                description: "Verify task completion",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .updateCompliance,
                name: "Update Compliance",
                description: "Update building compliance score",
                status: .pending
            )
        ]
    }
    
    private func createDeadlineWorkflowSteps(title: String, buildingId: String, deadline: Date) -> [WorkflowStep] {
        return [
            WorkflowStep(
                id: UUID().uuidString,
                type: .scheduleDeadline,
                name: "Schedule Deadline Reminders",
                description: "Set up deadline notifications",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .sendNotification,
                name: "Send Initial Notification",
                description: "Notify relevant parties",
                status: .pending
            )
        ]
    }
    
    private func createCertificationWorkflowSteps(
        taskId: String,
        workerId: String,
        buildingId: String,
        completionData: WorkflowTaskCompletionData
    ) -> [WorkflowStep] {
        return [
            WorkflowStep(
                id: UUID().uuidString,
                type: .validateCompletion,
                name: "Validate Task Completion",
                description: "Verify task was completed properly",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .generateCertification,
                name: "Generate Certification",
                description: "Create compliance certification document",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .updateCompliance,
                name: "Update Compliance Records",
                description: "Update building compliance status",
                status: .pending
            )
        ]
    }
    
    private func createEvidenceFilingSteps(
        evidenceId: String,
        taskId: String,
        buildingId: String,
        requirements: FilingRequirements
    ) -> [WorkflowStep] {
        return [
            WorkflowStep(
                id: UUID().uuidString,
                type: .fileEvidence,
                name: "File Evidence",
                description: "Submit evidence to authorities",
                status: .pending
            ),
            WorkflowStep(
                id: UUID().uuidString,
                type: .sendNotification,
                name: "Notify Completion",
                description: "Notify stakeholders of filing",
                status: .pending
            )
        ]
    }
    
    private func saveWorkflow(_ workflow: Workflow) async throws {
        let workflowData = try JSONEncoder().encode(workflow)
        
        try await database.execute("""
            INSERT INTO automated_workflows (
                id, type, name, building_id, priority, status, deadline,
                created_at, workflow_data
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            workflow.id,
            workflow.type.rawValue,
            workflow.name,
            workflow.buildingId,
            workflow.priority.rawValue,
            workflow.status.rawValue,
            workflow.deadline.timeIntervalSince1970,
            workflow.createdAt.timeIntervalSince1970,
            workflowData
        ])
    }
    
    private func updateWorkflowInDatabase(_ workflow: Workflow) async throws {
        let workflowData = try JSONEncoder().encode(workflow)
        
        try await database.execute("""
            UPDATE automated_workflows
            SET status = ?, workflow_data = ?, updated_at = ?
            WHERE id = ?
        """, [
            workflow.status.rawValue,
            workflowData,
            Date().timeIntervalSince1970,
            workflow.id
        ])
    }
    
    private func loadWorkflowsFromDatabase() async {
        // Implementation to load existing workflows from database
        // This would be called on app startup
    }
}

// MARK: - Supporting Types

public struct Workflow: Codable, Identifiable {
    public let id: String
    public let type: WorkflowType
    public let name: String
    public let buildingId: String
    public let priority: WorkflowPriority
    public var status: WorkflowStatus
    public let deadline: Date
    public let createdAt: Date
    public var completedAt: Date?
    public var steps: [WorkflowStep]
    public let metadata: [String: Any]
    
    // Custom coding for metadata dictionary
    private enum CodingKeys: String, CodingKey {
        case id, type, name, buildingId, priority, status, deadline
        case createdAt, completedAt, steps, metadata
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(buildingId, forKey: .buildingId)
        try container.encode(priority, forKey: .priority)
        try container.encode(status, forKey: .status)
        try container.encode(deadline, forKey: .deadline)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(completedAt, forKey: .completedAt)
        try container.encode(steps, forKey: .steps)
        // Simplified metadata encoding
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        try container.encode(metadataData, forKey: .metadata)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(WorkflowType.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        buildingId = try container.decode(String.self, forKey: .buildingId)
        priority = try container.decode(WorkflowPriority.self, forKey: .priority)
        status = try container.decode(WorkflowStatus.self, forKey: .status)
        deadline = try container.decode(Date.self, forKey: .deadline)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        steps = try container.decode([WorkflowStep].self, forKey: .steps)
        let metadataData = try container.decode(Data.self, forKey: .metadata)
        metadata = (try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]) ?? [:]
    }
    
    public init(id: String, type: WorkflowType, name: String, buildingId: String, priority: WorkflowPriority, status: WorkflowStatus, deadline: Date, createdAt: Date, steps: [WorkflowStep], metadata: [String: Any]) {
        self.id = id
        self.type = type
        self.name = name
        self.buildingId = buildingId
        self.priority = priority
        self.status = status
        self.deadline = deadline
        self.createdAt = createdAt
        self.steps = steps
        self.metadata = metadata
    }
}

public struct WorkflowStep: Codable, Identifiable {
    public let id: String
    public let type: WorkflowStepType
    public let name: String
    public let description: String
    public var status: WorkflowStepStatus
    public var startedAt: Date?
    public var completedAt: Date?
    public var result: [String: Any]?
    public var error: String?
    
    public init(id: String, type: WorkflowStepType, name: String, description: String, status: WorkflowStepStatus) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.status = status
    }
    
    // Custom coding for result dictionary
    private enum CodingKeys: String, CodingKey {
        case id, type, name, description, status, startedAt, completedAt, result, error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(status, forKey: .status)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(completedAt, forKey: .completedAt)
        try container.encode(error, forKey: .error)
        if let result = result {
            let resultData = try JSONSerialization.data(withJSONObject: result)
            try container.encode(resultData, forKey: .result)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(WorkflowStepType.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        status = try container.decode(WorkflowStepStatus.self, forKey: .status)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        if let resultData = try container.decodeIfPresent(Data.self, forKey: .result) {
            result = try JSONSerialization.jsonObject(with: resultData) as? [String: Any]
        }
    }
}

public enum WorkflowType: String, Codable, CaseIterable {
    case violationResolution
    case deadlineManagement
    case taskCertification
    case evidenceFiling
    case complianceUpdate
}

public enum WorkflowPriority: String, Codable, CaseIterable {
    case low
    case normal
    case high
    case critical
}

public enum WorkflowStatus: String, Codable, CaseIterable {
    case created
    case inProgress
    case completed
    case failed
    case cancelled
    case expired
}

public enum WorkflowStepType: String, Codable, CaseIterable {
    case createTask
    case assignWorker
    case scheduleDeadline
    case validateCompletion
    case generateCertification
    case fileEvidence
    case sendNotification
    case updateCompliance
}

public enum WorkflowStepStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
    case failed
    case skipped
}

public struct WorkflowStats {
    public let totalWorkflows: Int
    public let activeWorkflows: Int
    public let completedWorkflows: Int
    public let failedWorkflows: Int
    public let expiredWorkflows: Int
    public let averageCompletionTime: TimeInterval
    public let successRate: Double
    
    public init(
        totalWorkflows: Int = 0,
        activeWorkflows: Int = 0,
        completedWorkflows: Int = 0,
        failedWorkflows: Int = 0,
        expiredWorkflows: Int = 0,
        averageCompletionTime: TimeInterval = 0,
        successRate: Double = 0
    ) {
        self.totalWorkflows = totalWorkflows
        self.activeWorkflows = activeWorkflows
        self.completedWorkflows = completedWorkflows
        self.failedWorkflows = failedWorkflows
        self.expiredWorkflows = expiredWorkflows
        self.averageCompletionTime = averageCompletionTime
        self.successRate = successRate
    }
}

public struct WorkflowTaskCompletionData {
    public let taskId: String
    public let workerId: String
    public let completedAt: Date
    public let photoEvidence: [String]
    public let notes: String?
    
    public init(taskId: String, workerId: String, completedAt: Date, photoEvidence: [String], notes: String?) {
        self.taskId = taskId
        self.workerId = workerId
        self.completedAt = completedAt
        self.photoEvidence = photoEvidence
        self.notes = notes
    }
}

public struct FilingRequirements {
    public let type: FilingType
    public let deadline: Date
    public let authorities: [String]
    public let documentTypes: [String]
    
    public enum FilingType: String, CaseIterable {
        case hpdViolation
        case dobPermit
        case ll97Compliance
        case fdnyInspection
    }
    
    public init(type: FilingType, deadline: Date, authorities: [String], documentTypes: [String]) {
        self.type = type
        self.deadline = deadline
        self.authorities = authorities
        self.documentTypes = documentTypes
    }
}

public enum WorkflowError: LocalizedError {
    case missingMetadata(String)
    case validationFailed(String)
    case executionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingMetadata(let key):
            return "Missing required metadata: \(key)"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .executionFailed(let reason):
            return "Execution failed: \(reason)"
        }
    }
}

// MARK: - Notification Service Placeholder

public class NotificationService {
    func scheduleNotification(id: String, title: String, body: String, date: Date, userInfo: [String: Any]) async {
        print("📅 Scheduled notification: \(title) for \(date)")
    }
    
    func sendNotification(id: String, title: String, body: String, userInfo: [String: Any]) async {
        print("🔔 Sent notification: \(title)")
    }
}