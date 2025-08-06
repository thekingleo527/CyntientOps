//
//  ComplianceDataDTO.swift
//  CyntientOps
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ FIXED: Using CoreTypes.ComplianceStatus instead of duplicate enum
//  ✅ FIXED: Added public initializer and properties for BuildingIntelligenceDTO compatibility
//  ✅ Defines the data structure for building compliance information.
//

import Foundation

// MARK: - Compliance Data DTO
public struct ComplianceDataDTO: Codable, Hashable {
    public let buildingId: String
    public let hasValidPermits: Bool
    public let lastInspectionDate: Date
    public let outstandingViolations: Int
    
    // ✅ ADDED: Public initializer for external creation
    public init(
        buildingId: String,
        hasValidPermits: Bool,
        lastInspectionDate: Date,
        outstandingViolations: Int
    ) {
        self.buildingId = buildingId
        self.hasValidPermits = hasValidPermits
        self.lastInspectionDate = lastInspectionDate
        self.outstandingViolations = outstandingViolations
    }
    
    // A computed property to quickly assess compliance risk using CoreTypes.ComplianceStatus
    public var complianceStatus: CoreTypes.ComplianceStatus {
        if !hasValidPermits || outstandingViolations > 0 {
            return .atRisk
        }
        if let daysSinceInspection = Calendar.current.dateComponents([.day], from: lastInspectionDate, to: Date()).day, daysSinceInspection > 365 {
            return .needsReview
        }
        return .compliant
    }
    
    // Additional helper properties
    public var isCompliant: Bool {
        return complianceStatus == .compliant
    }
    
    public var requiresUrgentAction: Bool {
        return complianceStatus == .nonCompliant || complianceStatus == .atRisk
    }
    
    public var daysSinceLastInspection: Int {
        let days = Calendar.current.dateComponents([.day], from: lastInspectionDate, to: Date()).day ?? 0
        return days
    }
    
    // Helper computed properties for UI display
    public var statusDisplayName: String {
        switch complianceStatus {
        case .compliant: return "Compliant"
        case .needsReview: return "Needs Review"
        case .atRisk: return "At Risk"
        case .nonCompliant: return "Non-Compliant"
        case .warning: return "Warning"
        case .violation: return "Violation"
        default: return complianceStatus.rawValue
        }
    }
    
    public var statusColor: String {
        switch complianceStatus {
        case .compliant: return "green"
        case .needsReview: return "yellow"
        case .atRisk: return "orange"
        case .nonCompliant, .violation: return "red"
        case .warning: return "orange"
        default: return "gray"
        }
    }
    
    public var statusPriority: Int {
        switch complianceStatus {
        case .compliant: return 0
        case .needsReview: return 1
        case .warning: return 2
        case .atRisk: return 3
        case .nonCompliant, .violation: return 4
        default: return 5
        }
    }
}
