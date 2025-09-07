//
//  ComplianceIssue.swift
//  CyntientOps v6.0
//
//  ✅ UNIFIED: Resolves all ComplianceIssue type conflicts
//  ✅ ALIGNED: With actual CoreTypes definitions
//  ✅ FIXED: All compilation errors resolved
//  ✅ EXTENDS: CoreTypes.ComplianceIssue with convenience methods
//  ✅ INTEGRATED: Uses CyntientOpsDesign for all colors
//

import Foundation
import SwiftUI

// MARK: - Unified ComplianceIssue Extensions

extension CoreTypes.ComplianceIssue {
    
    // MARK: - Convenience Initializers
    
    /// Initializer with issue type
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        issueType: CoreTypes.ComplianceIssueType,
        severity: CoreTypes.ComplianceSeverity,
        buildingId: String,
        assignedTo: String? = nil,
        dueDate: Date? = nil
    ) {
        self.init(
            id: id,
            title: title,
            description: description,
            severity: severity,
            buildingId: buildingId,
            status: .open,
            dueDate: dueDate,
            assignedTo: assignedTo,
            createdAt: Date(),
            type: issueType
        )
    }
    
    // MARK: - Computed Properties
    
    /// Priority value for sorting
    var priorityValue: Int {
        severity.priorityValue
    }
    
    /// Color for UI display
    var severityColor: Color {
        severity.color
    }
    
    /// Icon for severity level
    var severityIcon: String {
        severity.iconName
    }
    
    /// Badge text for severity
    var severityBadge: String {
        severity.badgeText
    }
    
    /// Days until due date
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: dueDate).day
        return days
    }
    
    /// Is issue overdue?
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return Date() > dueDate && status != .compliant && status != .resolved
    }
    
    /// Status color for UI
    var statusColor: Color {
        if isOverdue { return .red }
        return status.color
    }
    
    // MARK: - Factory Methods
    
    /// Create a safety compliance issue
    static func safetyIssue(
        title: String,
        description: String,
        buildingId: String,
        severity: CoreTypes.ComplianceSeverity = .high,
        dueDate: Date? = nil
    ) -> CoreTypes.ComplianceIssue {
        return CoreTypes.ComplianceIssue(
            title: title,
            description: description,
            severity: severity,
            buildingId: buildingId,
            status: .warning,
            dueDate: dueDate ?? Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            type: .safety
        )
    }
    
    /// Create a maintenance compliance issue
    static func maintenanceIssue(
        title: String,
        description: String,
        buildingId: String,
        severity: CoreTypes.ComplianceSeverity = .medium,
        dueDate: Date? = nil
    ) -> CoreTypes.ComplianceIssue {
        return CoreTypes.ComplianceIssue(
            title: title,
            description: description,
            severity: severity,
            buildingId: buildingId,
            status: .warning,
            dueDate: dueDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            type: .operational
        )
    }
    
    /// Create a documentation compliance issue
    static func documentationIssue(
        title: String,
        description: String,
        buildingId: String,
        severity: CoreTypes.ComplianceSeverity = .low,
        dueDate: Date? = nil
    ) -> CoreTypes.ComplianceIssue {
        return CoreTypes.ComplianceIssue(
            title: title,
            description: description,
            severity: severity,
            buildingId: buildingId,
            status: .pending,
            dueDate: dueDate ?? Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            type: .documentation
        )
    }
    
    /// Create an environmental compliance issue
    static func environmentalIssue(
        title: String,
        description: String,
        buildingId: String,
        severity: CoreTypes.ComplianceSeverity = .high,
        dueDate: Date? = nil
    ) -> CoreTypes.ComplianceIssue {
        return CoreTypes.ComplianceIssue(
            title: title,
            description: description,
            severity: severity,
            buildingId: buildingId,
            status: .violation,
            dueDate: dueDate ?? Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            type: .environmental
        )
    }
    
    // MARK: - Mock Data for Testing
    
    /// Generate sample compliance issues for testing
    static func mockIssues(for buildingId: String, buildingName: String = "Sample Building") -> [CoreTypes.ComplianceIssue] {
        return [
            safetyIssue(
                title: "Fire Exit Blocked",
                description: "Emergency exit on 2nd floor has storage blocking access",
                buildingId: buildingId,
                severity: .critical
            ),
            maintenanceIssue(
                title: "HVAC Filter Overdue",
                description: "Air filter replacement is 2 weeks overdue",
                buildingId: buildingId,
                severity: .medium
            ),
            documentationIssue(
                title: "Missing Safety Inspection Certificate",
                description: "Annual safety inspection certificate not on file",
                buildingId: buildingId,
                severity: .low
            ),
            environmentalIssue(
                title: "Water Leak Detected",
                description: "Small water leak detected in basement utility room",
                buildingId: buildingId,
                severity: .high
            )
        ]
    }
}

// MARK: - ComplianceSeverity Extensions

extension CoreTypes.ComplianceSeverity {
    
    /// Priority value for sorting (highest priority = highest number)
    var priorityValue: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    /// Color for UI display - uses CyntientOpsDesign
    var color: Color {
        return CyntientOpsDesign.EnumColors.complianceSeverity(self)
    }
    
    /// SFSymbol icon name
    var iconName: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.circle"
        case .low: return "info.circle"
        }
    }
    
    /// Display badge text
    var badgeText: String {
        return rawValue.uppercased()
    }
    
    /// Default due date offset from creation
    var defaultDueDateOffset: Int {
        switch self {
        case .critical: return 1  // 1 day
        case .high: return 3      // 3 days
        case .medium: return 7    // 1 week
        case .low: return 14      // 2 weeks
        }
    }
}

// MARK: - ComplianceStatus Extensions

extension CoreTypes.ComplianceStatus {
    
    /// Color for UI display - uses CyntientOpsDesign
    var color: Color {
        return CyntientOpsDesign.EnumColors.complianceStatus(self)
    }
    
    /// SFSymbol icon name
    var iconName: String {
        switch self {
        case .compliant, .resolved: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .violation, .nonCompliant: return "xmark.circle.fill"
        case .pending, .needsReview: return "clock.circle.fill"
        case .open: return "circle"
        case .inProgress: return "circle.dotted"
        case .atRisk: return "exclamationmark.shield.fill"
        }
    }
    
    /// Progress value (0.0 to 1.0)
    var progressValue: Double {
        switch self {
        case .compliant, .resolved: return 1.0
        case .warning: return 0.7
        case .violation, .nonCompliant: return 0.3
        case .pending: return 0.5
        case .open: return 0.2
        case .inProgress: return 0.6
        case .atRisk: return 0.4
        case .needsReview: return 0.5
        }
    }
}

// MARK: - ComplianceIssueType Extensions

extension CoreTypes.ComplianceIssueType {
    
    /// SFSymbol icon name
    var iconName: String {
        switch self {
        case .safety: return "shield.fill"
        case .environmental: return "leaf.fill"
        case .regulatory: return "doc.badge.gearshape"
        case .financial: return "dollarsign.circle.fill"
        case .operational: return "gearshape.fill"
        case .documentation: return "doc.text.fill"
        }
    }
    
    /// Color for UI display - uses CyntientOpsDesign
    var color: Color {
        return CyntientOpsDesign.EnumColors.complianceIssueType(self)
    }
    
    /// Default severity for this issue type
    var defaultSeverity: CoreTypes.ComplianceSeverity {
        switch self {
        case .safety: return .critical
        case .environmental: return .high
        case .regulatory: return .high
        case .financial: return .medium
        case .operational: return .medium
        case .documentation: return .low
        }
    }
}

// MARK: - Sorting and Filtering Helpers

extension Array where Element == CoreTypes.ComplianceIssue {
    
    /// Sort by priority (critical first)
    func sortedByPriority() -> [CoreTypes.ComplianceIssue] {
        return sorted { $0.priorityValue > $1.priorityValue }
    }
    
    /// Sort by due date (most urgent first)
    func sortedByDueDate() -> [CoreTypes.ComplianceIssue] {
        return sorted { issue1, issue2 in
            guard let date1 = issue1.dueDate, let date2 = issue2.dueDate else {
                return issue1.dueDate != nil
            }
            return date1 < date2
        }
    }
    
    /// Filter by severity level
    func filtered(by severity: CoreTypes.ComplianceSeverity) -> [CoreTypes.ComplianceIssue] {
        return filter { $0.severity == severity }
    }
    
    /// Filter by status
    func filtered(by status: CoreTypes.ComplianceStatus) -> [CoreTypes.ComplianceIssue] {
        return filter { $0.status == status }
    }
    
    /// Filter overdue issues
    var overdue: [CoreTypes.ComplianceIssue] {
        return filter { $0.isOverdue }
    }
    
    /// Filter critical issues
    var critical: [CoreTypes.ComplianceIssue] {
        return filter { $0.severity == .critical }
    }
    
    /// Get compliance summary statistics  
    var localComplianceSummary: LocalComplianceSummary {
        let total = count
        let compliant = filter { $0.status == .compliant }.count
        let overdue = self.overdue.count
        let critical = self.critical.count
        
        return LocalComplianceSummary(
            total: total,
            compliant: compliant,
            overdue: overdue,
            critical: critical,
            complianceRate: total > 0 ? Double(compliant) / Double(total) : 1.0
        )
    }
}

// MARK: - Compliance Summary Helper

internal struct LocalComplianceSummary {
    let total: Int
    let compliant: Int
    let overdue: Int
    let critical: Int
    let complianceRate: Double
    
    var compliancePercentage: Int {
        Int(complianceRate * 100)
    }
    
    var hasIssues: Bool {
        return overdue > 0 || critical > 0
    }
    
    var statusColor: Color {
        if critical > 0 { return .red }
        if overdue > 0 { return .orange }
        if complianceRate >= 0.9 { return .green }
        return .yellow
    }
}
