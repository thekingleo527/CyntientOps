//
//  NovaTypes.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: All Nova types in one place
//  ✅ SIMPLIFIED: Uses CoreTypes for all shared concepts
//  ✅ NO DUPLICATES: Only Nova-specific types defined here
//  ✅ CLEAN: No type conversion needed
//  ✅ ENHANCED: Includes data aggregation and prompt types
//  ✅ FIXED: NovaContext data field for proper dictionary storage
//  ✅ FIXED: Removed Sendable conformance where CoreTypes are non-Sendable
//

import Foundation
import SwiftUI

// MARK: - Nova-Specific Types

/// Nova context for AI operations
public struct NovaContext: Codable, Hashable, Identifiable {
    public let id: UUID
    public let data: [String: String]  // Changed from String to dictionary for structured data
    public let timestamp: Date
    public let insights: [String]
    public let metadata: [String: String]
    public let userRole: CoreTypes.UserRole?
    public let buildingContext: CoreTypes.BuildingID?
    public let taskContext: String?
    
    public init(
        id: UUID = UUID(),
        data: [String: String],  // Changed parameter type
        timestamp: Date = Date(),
        insights: [String] = [],
        metadata: [String: String] = [:],
        userRole: CoreTypes.UserRole? = nil,
        buildingContext: CoreTypes.BuildingID? = nil,
        taskContext: String? = nil
    ) {
        self.id = id
        self.data = data
        self.timestamp = timestamp
        self.insights = insights
        self.metadata = metadata
        self.userRole = userRole
        self.buildingContext = buildingContext
        self.taskContext = taskContext
    }
    
    // Convenience initializer for legacy string data
    public init(
        id: UUID = UUID(),
        stringData: String,
        timestamp: Date = Date(),
        insights: [String] = [],
        metadata: [String: String] = [:],
        userRole: CoreTypes.UserRole? = nil,
        buildingContext: CoreTypes.BuildingID? = nil,
        taskContext: String? = nil
    ) {
        self.id = id
        self.data = ["content": stringData]  // Convert string to dictionary
        self.timestamp = timestamp
        self.insights = insights
        self.metadata = metadata
        self.userRole = userRole
        self.buildingContext = buildingContext
        self.taskContext = taskContext
    }
}

/// Nova prompt structure
public struct NovaPrompt: Identifiable, Codable {
    public let id: UUID
    public let text: String
    public let priority: CoreTypes.AIPriority
    public let context: NovaContext?
    public let createdAt: Date
    public let expiresAt: Date?
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        text: String,
        priority: CoreTypes.AIPriority = .medium,
        context: NovaContext? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.text = text
        self.priority = priority
        self.context = context
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.metadata = metadata
    }
}

/// Nova response structure
public struct NovaResponse: Codable, Identifiable {
    public let id: UUID
    public let success: Bool
    public let message: String
    public let insights: [CoreTypes.IntelligenceInsight]
    public let actions: [NovaAction]
    public let confidence: Double
    public let timestamp: Date
    public let processingTime: TimeInterval?
    public let context: NovaContext?
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        success: Bool,
        message: String,
        insights: [CoreTypes.IntelligenceInsight] = [],
        actions: [NovaAction] = [],
        confidence: Double = 1.0,
        timestamp: Date = Date(),
        processingTime: TimeInterval? = nil,
        context: NovaContext? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.success = success
        self.message = message
        self.insights = insights
        self.actions = actions
        self.confidence = confidence
        self.timestamp = timestamp
        self.processingTime = processingTime
        self.context = context
        self.metadata = metadata
    }
}

/// Nova-specific action
public struct NovaAction: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let actionType: NovaActionType
    public let priority: CoreTypes.AIPriority?
    public let parameters: [String: String]
    public let estimatedDuration: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        actionType: NovaActionType,
        priority: CoreTypes.AIPriority? = nil,
        parameters: [String: String] = [:],
        estimatedDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.priority = priority
        self.parameters = parameters
        self.estimatedDuration = estimatedDuration
    }
}

/// Nova action types
public enum NovaActionType: String, Codable, CaseIterable, Sendable {
    case navigate = "navigate"
    case schedule = "schedule"
    case assign = "assign"
    case notify = "notify"
    case analysis = "analysis"
    case report = "report"
    case review = "review"
    case complete = "complete"
    
    public var icon: String {
        switch self {
        case .navigate: return "location.fill"
        case .schedule: return "calendar"
        case .assign: return "person.badge.plus"
        case .notify: return "bell.fill"
        case .analysis: return "chart.line.uptrend.xyaxis"
        case .report: return "doc.text.fill"
        case .review: return "magnifyingglass"
        case .complete: return "checkmark.circle"
        }
    }
}

/// Nova processing state
public enum NovaProcessingState: String, Codable, CaseIterable, Sendable {
    case idle = "idle"
    case processing = "processing"
    case generating = "generating"
    case completed = "completed"
    case error = "error"
}

// MARK: - Scenario Support Types

/// Nova scenario data for AI-driven scenarios
public struct NovaScenarioData: Identifiable, Codable {
    public let id: UUID
    public let scenario: CoreTypes.AIScenarioType
    public let message: String
    public let actionText: String
    public let createdAt: Date
    public let priority: CoreTypes.AIPriority
    public let context: [String: String]
    
    public init(
        id: UUID = UUID(),
        scenario: CoreTypes.AIScenarioType,
        message: String,
        actionText: String,
        createdAt: Date = Date(),
        priority: CoreTypes.AIPriority? = nil,
        context: [String: String] = [:]
    ) {
        self.id = id
        self.scenario = scenario
        self.message = message
        self.actionText = actionText
        self.createdAt = createdAt
        self.priority = priority ?? scenario.priority
        self.context = context
    }
    
    /// Check if scenario is high priority
    public var isHighPriority: Bool {
        return priority == .high || priority == .critical
    }
    
    /// Get scenario icon
    public var icon: String {
        return scenario.icon
    }
    
    /// Get scenario display title
    public var displayTitle: String {
        return scenario.displayTitle
    }
    
    /// Get scenario color
    public var color: Color {
        return scenario.color
    }
}

/// Emergency repair state for tracking repair progress
public struct NovaEmergencyRepairState: Sendable {
    public var isActive: Bool = false
    public var progress: Double = 0.0
    public var message: String = ""
    public var workerId: String?
    
    public init(
        isActive: Bool = false,
        progress: Double = 0.0,
        message: String = "",
        workerId: String? = nil
    ) {
        self.isActive = isActive
        self.progress = progress
        self.message = message
        self.workerId = workerId
    }
}

// MARK: - Data Aggregation Types (from NovaDataService)

/// Comprehensive structure holding aggregated metrics for Nova
public struct NovaAggregatedData: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let buildingCount: Int
    public let taskCount: Int
    public let workerCount: Int
    public let completedTaskCount: Int
    public let urgentTaskCount: Int
    public let overdueTaskCount: Int
    public let averageCompletionRate: Double
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        buildingCount: Int,
        taskCount: Int,
        workerCount: Int,
        completedTaskCount: Int = 0,
        urgentTaskCount: Int = 0,
        overdueTaskCount: Int = 0,
        averageCompletionRate: Double = 0.0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.buildingCount = buildingCount
        self.taskCount = taskCount
        self.workerCount = workerCount
        self.completedTaskCount = completedTaskCount
        self.urgentTaskCount = urgentTaskCount
        self.overdueTaskCount = overdueTaskCount
        self.averageCompletionRate = averageCompletionRate
        self.timestamp = timestamp
    }
    
    /// Check if the data is expired (older than 5 minutes)
    public var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 300
    }
    
    /// Calculate task completion percentage
    public var completionPercentage: Double {
        return taskCount > 0 ? (Double(completedTaskCount) / Double(taskCount)) * 100 : 0
    }
    
    /// Check if there are critical issues
    public var hasCriticalIssues: Bool {
        return urgentTaskCount > 0 || overdueTaskCount > 0
    }
}

// MARK: - Prompt Generation Types (from NovaPromptEngine)

/// Template for custom prompts
public struct PromptTemplate: Sendable {
    public let name: String
    public let baseText: String
    public let requiredParameters: [String]
    
    public init(name: String, baseText: String, requiredParameters: [String]) {
        self.name = name
        self.baseText = baseText
        self.requiredParameters = requiredParameters
    }
    
    // Predefined templates
    public static let dailyBriefing = PromptTemplate(
        name: "Daily Briefing",
        baseText: "Daily briefing for {date}: {taskCount} tasks across {buildingCount} buildings with {workerCount} active workers.",
        requiredParameters: ["date", "taskCount", "buildingCount", "workerCount"]
    )
    
    public static let workerAssignment = PromptTemplate(
        name: "Worker Assignment",
        baseText: "Assign {workerName} to {buildingName} for {taskType} tasks. Duration: {hours} hours.",
        requiredParameters: ["workerName", "buildingName", "taskType", "hours"]
    )
    
    public static let maintenanceAlert = PromptTemplate(
        name: "Maintenance Alert",
        baseText: "Maintenance required at {buildingName}: {issueType}. Priority: {priority}. Estimated time: {duration}.",
        requiredParameters: ["buildingName", "issueType", "priority", "duration"]
    )
    
    public static let complianceUpdate = PromptTemplate(
        name: "Compliance Update",
        baseText: "Compliance status for {buildingName}: {status}. Issues: {issueCount}. Next audit: {auditDate}.",
        requiredParameters: ["buildingName", "status", "issueCount", "auditDate"]
    )
    
    public static let emergencyResponse = PromptTemplate(
        name: "Emergency Response",
        baseText: "EMERGENCY at {buildingName}: {emergencyType}. Severity: {severity}. Response team: {responders}.",
        requiredParameters: ["buildingName", "emergencyType", "severity", "responders"]
    )
    
    /// Generate prompt from template with parameters
    public func generate(with parameters: [String: String]) -> String {
        var prompt = baseText
        for (key, value) in parameters {
            prompt = prompt.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return prompt
    }
}

/// Focus areas for prompt generation
public enum PromptFocus: String, Codable, CaseIterable, Sendable {
    case operations = "operations"
    case workforce = "workforce"
    case maintenance = "maintenance"
    case compliance = "compliance"
    case financial = "financial"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Nova context type for categorization
public enum NovaContextType: String, Codable, CaseIterable, Sendable {
    case portfolio = "portfolio"
    case building = "building"
    case worker = "worker"
    case task = "task"
    
    public var icon: String {
        switch self {
        case .portfolio: return "building.2.crop.circle"
        case .building: return "building.2"
        case .worker: return "person.fill"
        case .task: return "checklist"
        }
    }
}

// MARK: - Error Types

public enum NovaError: Error, LocalizedError {
    case invalidContext
    case promptTooLong(Int)
    case responseTimeout
    case rateLimitExceeded
    case serviceUnavailable
    case processingFailed(String)
    case dataAggregationFailed(String)
    case promptGenerationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidContext:
            return "Invalid context provided to Nova"
        case .promptTooLong(let length):
            return "Prompt too long: \(length) characters"
        case .responseTimeout:
            return "Nova response timed out"
        case .rateLimitExceeded:
            return "Nova rate limit exceeded"
        case .serviceUnavailable:
            return "Nova service temporarily unavailable"
        case .processingFailed(let reason):
            return "Nova processing failed: \(reason)"
        case .dataAggregationFailed(let reason):
            return "Data aggregation failed: \(reason)"
        case .promptGenerationFailed(let reason):
            return "Prompt generation failed: \(reason)"
        }
    }
}

// MARK: - Convenience Extensions

extension NovaContext {
    /// Check if context is expired (older than 5 minutes)
    public var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 300
    }
    
    /// Get context data as a single string (for backward compatibility)
    public var dataString: String {
        return data["content"] ?? data.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
    
    /// Add an insight to the context
    public func withInsight(_ insight: String) -> NovaContext {
        var newInsights = insights
        newInsights.append(insight)
        return NovaContext(
            id: id,
            data: data,
            timestamp: timestamp,
            insights: newInsights,
            metadata: metadata,
            userRole: userRole,
            buildingContext: buildingContext,
            taskContext: taskContext
        )
    }
    
    /// Add metadata to the context
    public func withMetadata(key: String, value: String) -> NovaContext {
        var newMetadata = metadata
        newMetadata[key] = value
        return NovaContext(
            id: id,
            data: data,
            timestamp: timestamp,
            insights: insights,
            metadata: newMetadata,
            userRole: userRole,
            buildingContext: buildingContext,
            taskContext: taskContext
        )
    }
    
    /// Add or update context data
    public func withData(key: String, value: String) -> NovaContext {
        var newData = data
        newData[key] = value
        return NovaContext(
            id: id,
            data: newData,
            timestamp: timestamp,
            insights: insights,
            metadata: metadata,
            userRole: userRole,
            buildingContext: buildingContext,
            taskContext: taskContext
        )
    }
}

extension NovaPrompt {
    /// Check if prompt has expired
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// Check if prompt is high priority
    public var isHighPriority: Bool {
        return priority == .high || priority == .critical
    }
}

extension NovaResponse {
    /// Check if response has critical insights
    public var hasCriticalInsights: Bool {
        return insights.contains { $0.priority == .critical }
    }
    
    /// Get insights by priority
    public func insights(withPriority priority: CoreTypes.AIPriority) -> [CoreTypes.IntelligenceInsight] {
        return insights.filter { $0.priority == priority }
    }
}

// MARK: - Type Aliases for Clarity

public typealias NovaInsight = CoreTypes.IntelligenceInsight
public typealias NovaSuggestion = CoreTypes.AISuggestion
public typealias NovaPriority = CoreTypes.AIPriority
public typealias NovaInsightType = CoreTypes.InsightCategory
public typealias NovaScenarioType = CoreTypes.AIScenarioType

// MARK: - Extension to AIScenarioType for UI Support

extension CoreTypes.AIScenarioType {
    public var icon: String {
        switch self {
        case .taskOptimization: return "list.bullet.clipboard.fill"
        case .routeOptimization: return "location.fill"
        case .inventoryManagement: return "shippingbox.fill"
        case .complianceAlert: return "exclamationmark.shield.fill"
        case .maintenancePrediction: return "wrench.and.screwdriver.fill"
        case .emergencyResponse: return "exclamationmark.triangle.fill"
        }
    }
    
    public var displayTitle: String {
        switch self {
        case .taskOptimization: return "Task Optimization"
        case .routeOptimization: return "Route Optimization"
        case .inventoryManagement: return "Inventory Management"
        case .complianceAlert: return "Compliance Alert"
        case .maintenancePrediction: return "Maintenance Prediction"
        case .emergencyResponse: return "Emergency Response"
        }
    }
    
    public var color: Color {
        switch self {
        case .taskOptimization: return .blue
        case .routeOptimization: return .green
        case .inventoryManagement: return .orange
        case .complianceAlert: return .red
        case .maintenancePrediction: return .yellow
        case .emergencyResponse: return .red
        }
    }
    
    public var priority: CoreTypes.AIPriority {
        switch self {
        case .taskOptimization: return .medium
        case .routeOptimization: return .medium
        case .inventoryManagement: return .high
        case .complianceAlert: return .critical
        case .maintenancePrediction: return .high
        case .emergencyResponse: return .critical
        }
    }
}
