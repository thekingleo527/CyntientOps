//
//  NYCDataModels.swift
//  CyntientOps Phase 5
//
//  NYC API Response Data Models for compliance monitoring
//  Based on actual NYC OpenData API schemas
//

import Foundation

// MARK: - HPD Violations

public struct HPDViolation: Codable, Identifiable {
    public let id = UUID()
    public let violationId: String
    public let buildingId: String
    public let bin: String
    public let apartmentNumber: String?
    public let story: String?
    public let inspectionDate: String
    public let approvedDate: String?
    public let originalCertifyByDate: String?
    public let originalCorrectByDate: String?
    public let newCertifyByDate: String?
    public let newCorrectByDate: String?
    public let certifiedDate: String?
    public let currentStatusId: String
    public let currentStatus: String
    public let currentStatusDate: String?
    public let novDescription: String
    public let novIssued: String
    public let orderNumber: String
    public let violationStatus: String
    
    private enum CodingKeys: String, CodingKey {
        case violationId = "violationid"
        case buildingId = "buildingid"
        case bin
        case apartmentNumber = "apartment"
        case story
        case inspectionDate = "inspectiondate"
        case approvedDate = "approveddate"
        case originalCertifyByDate = "originalcertifybydate"
        case originalCorrectByDate = "originalcorrectbydate"
        case newCertifyByDate = "newcertifybydate"
        case newCorrectByDate = "newcorrectbydate"
        case certifiedDate = "certifieddate"
        case currentStatusId = "currentstatusid"
        case currentStatus = "currentstatus"
        case currentStatusDate = "currentstatusdate"
        case novDescription = "novdescription"
        case novIssued = "novissuedate"
        case orderNumber = "ordernumber"
        case violationStatus = "violationstatus"
    }
    
    public var severity: CoreTypes.ComplianceSeverity {
        let description = novDescription.lowercased()
        if description.contains("immediately hazardous") || description.contains("lead") {
            return .critical
        } else if description.contains("hazardous") {
            return .high
        } else {
            return .medium
        }
    }
    
    public var isActive: Bool {
        return currentStatusDate == nil && violationStatus.lowercased() != "close"
    }
}

// MARK: - DOB Permits

public struct DOBPermit: Codable, Identifiable {
    public let id = UUID()
    public let bin: String
    public let jobNumber: String
    public let docNumber: String?
    public let borough: String
    public let jobType: String
    public let workType: String
    public let permitStatus: String
    public let filingDate: String
    public let issuanceDate: String?
    public let expirationDate: String?
    public let jobStartDate: String?
    public let permitType: String?
    public let workOnFloor: String?
    public let description: String?
    public let ownerName: String
    public let ownerPhone: String?
    public let fees: String?
    
    private enum CodingKeys: String, CodingKey {
        case bin
        case jobNumber = "job__"
        case docNumber = "doc__"
        case borough
        case jobType = "job_type"
        case workType = "work_type"
        case permitStatus = "permit_status"
        case filingDate = "filing_date"
        case issuanceDate = "issuance_date"
        case expirationDate = "expiration_date"
        case jobStartDate = "job_start_date"
        case permitType = "permit_type"
        case workOnFloor = "work_on_floor"
        case description = "job_description"
        case ownerName = "owner_name"
        case ownerPhone = "owner_phone"
        case fees = "fees"
    }
    
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        guard let expiry = formatter.date(from: expirationDate) else { return false }
        return expiry < Date()
    }
    
    public var priority: CoreTypes.TaskUrgency {
        if isExpired { return .critical }
        if permitStatus.lowercased().contains("pending") { return .medium }
        return .low
    }
}

// MARK: - DSNY Routes

public struct DSNYRoute: Codable, Identifiable {
    public let id = UUID()
    public let communityDistrict: String
    public let section: String
    public let route: String
    public let dayOfWeek: String
    public let time: String
    public let serviceType: String
    public let borough: String
    
    private enum CodingKeys: String, CodingKey {
        case communityDistrict = "community_district"
        case section
        case route
        case dayOfWeek = "day_of_week"
        case time
        case serviceType = "service_type"
        case borough
    }
    
    public var isToday: Bool {
        let today = DateFormatter().weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]
        return dayOfWeek.lowercased().contains(today.lowercased())
    }
}

// MARK: - LL97 Emissions

public struct LL97Emission: Codable, Identifiable {
    public let id = UUID()
    public let bbl: String
    public let propertyName: String
    public let primaryPropertyType: String
    public let reportedAddress: String
    public let borough: String
    public let reportingYear: String
    public let totalGHGEmissions: Double
    public let totalGHGEmissionsIntensity: Double
    public let emissionsLimit: Double
    public let emissionsOverLimit: Double?
    public let potentialFine: Double?
    public let energyUseIntensity: Double
    
    private enum CodingKeys: String, CodingKey {
        case bbl
        case propertyName = "property_name"
        case primaryPropertyType = "primary_property_type"
        case reportedAddress = "reported_address"
        case borough
        case reportingYear = "reporting_year"
        case totalGHGEmissions = "total_ghg_emissions_metric_tons_co2e"
        case totalGHGEmissionsIntensity = "total_ghg_emissions_intensity_kgco2e_ft2"
        case emissionsLimit = "emissions_limit_metric_tons_co2e"
        case emissionsOverLimit = "emissions_over_limit_metric_tons_co2e"
        case potentialFine = "potential_fine"
        case energyUseIntensity = "site_energy_use_intensity_kbtu_ft2"
    }
    
    public var isCompliant: Bool {
        return (emissionsOverLimit ?? 0) <= 0
    }
    
    public var complianceStatus: String {
        if isCompliant {
            return "Compliant"
        } else {
            return "Over Limit by \(String(format: "%.1f", emissionsOverLimit ?? 0)) tons"
        }
    }
}

// MARK: - DEP Water Usage

public struct DEPWaterUsage: Codable, Identifiable {
    public let id = UUID()
    public let developmentName: String
    public let borough: String
    public let accountNumber: String
    public let currentCharges: Double?
    public let newCharges: Double?
    public let consumptionHcf: Double?
    public let serviceStartDate: String?
    public let serviceEndDate: String?
    public let numberOfDays: Int?
    public let meterNumber: String?
    
    private enum CodingKeys: String, CodingKey {
        case developmentName = "development_name"
        case borough
        case accountNumber = "account_number"
        case currentCharges = "current_charges"
        case newCharges = "new_charges"
        case consumptionHcf = "consumption_hcf"
        case serviceStartDate = "service_start_date"
        case serviceEndDate = "service_end_date"
        case numberOfDays = "number_of_days"
        case meterNumber = "meter_number"
    }
}

// MARK: - FDNY Inspections

public struct FDNYInspection: Codable, Identifiable {
    public let id = UUID()
    public let bin: String
    public let inspectionDate: String
    public let inspectionType: String
    public let result: String
    public let violationNumber: String?
    public let violationDetails: String?
    public let borough: String
    public let certificateNumber: String?
    public let expirationDate: String?
    
    private enum CodingKeys: String, CodingKey {
        case bin
        case inspectionDate = "inspection_date"
        case inspectionType = "inspection_type"
        case result
        case violationNumber = "violation_number"
        case violationDetails = "violation_details"
        case borough
        case certificateNumber = "certificate_number"
        case expirationDate = "expiration_date"
    }
    
    public var passed: Bool {
        return result.lowercased().contains("passed") || result.lowercased().contains("satisfactory")
    }
    
    public var hasViolations: Bool {
        return violationNumber != nil && !violationNumber!.isEmpty
    }
}

// MARK: - 311 Complaints

public struct Complaint311: Codable, Identifiable {
    public let id = UUID()
    public let uniqueKey: String
    public let createdDate: String
    public let closedDate: String?
    public let agency: String
    public let complaintType: String
    public let descriptor: String?
    public let incidentAddress: String?
    public let borough: String
    public let status: String
    public let resolution: String?
    public let bin: String?
    
    private enum CodingKeys: String, CodingKey {
        case uniqueKey = "unique_key"
        case createdDate = "created_date"
        case closedDate = "closed_date"
        case agency
        case complaintType = "complaint_type"
        case descriptor
        case incidentAddress = "incident_address"
        case borough
        case status
        case resolution = "resolution_description"
        case bin
    }
    
    public var isActive: Bool {
        return closedDate == nil && status.lowercased() != "closed"
    }
    
    public var priority: CoreTypes.TaskUrgency {
        let type = complaintType.lowercased()
        if type.contains("heat") || type.contains("hot water") || type.contains("emergency") {
            return .critical
        } else if type.contains("plumbing") || type.contains("electric") {
            return .high
        } else {
            return .medium
        }
    }
}

// MARK: - Consolidated Compliance Data

public struct NYCBuildingCompliance: Codable {
    public let bin: String
    public let bbl: String
    public let lastUpdated: Date
    
    // Compliance Data
    public let hpdViolations: [HPDViolation]
    public let dobPermits: [DOBPermit]
    public let fdnyInspections: [FDNYInspection]
    public let ll97Data: [LL97Emission]
    public let complaints311: [Complaint311]
    public let depWaterData: [DEPWaterUsage]
    
    // Computed Properties
    public var totalActiveViolations: Int {
        hpdViolations.filter { $0.isActive }.count +
        complaints311.filter { $0.isActive }.count +
        fdnyInspections.filter { $0.hasViolations }.count
    }
    
    public var overallComplianceScore: Double {
        let maxPossibleViolations = 100.0
        let actualViolations = Double(totalActiveViolations)
        return max(0.0, (maxPossibleViolations - actualViolations) / maxPossibleViolations)
    }
    
    public var criticalIssues: [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // HPD Critical Violations
        for violation in hpdViolations.filter({ $0.severity == .critical && $0.isActive }) {
            issues.append(ComplianceIssue(
                type: .hpdViolation,
                severity: .critical,
                description: violation.novDescription,
                source: "HPD",
                date: violation.inspectionDate,
                deadline: violation.newCorrectByDate,
                fine: nil // HPD violations may not always have fines
            ))
        }
        
        // LL97 Over Limit
        for emission in ll97Data.filter({ !$0.isCompliant }) {
            issues.append(ComplianceIssue(
                type: .ll97Violation,
                severity: .critical,
                description: "Emissions over LL97 limit",
                source: "LL97",
                date: Date().iso8601String,
                deadline: nil,
                fine: emission.potentialFine
            ))
        }
        
        // Expired DOB Permits
        for permit in dobPermits.filter({ $0.isExpired }) {
            issues.append(ComplianceIssue(
                type: .expiredPermit,
                severity: .high,
                description: "Expired \(permit.workType) permit",
                source: "DOB",
                date: permit.expirationDate ?? "",
                deadline: nil,
                fine: nil // Permits don't typically have fines until violations occur
            ))
        }
        
        return issues
    }
    
    public var ll97ComplianceStatus: String {
        guard let latest = ll97Data.sorted(by: { $0.reportingYear > $1.reportingYear }).first else {
            return "No LL97 data available"
        }
        
        return latest.complianceStatus
    }
    
    public var nextRequiredActions: [RequiredAction] {
        var actions: [RequiredAction] = []
        
        // HPD Violation Corrections
        for violation in hpdViolations.filter({ $0.isActive }) {
            if let deadline = violation.newCorrectByDate {
                actions.append(RequiredAction(
                    type: .correctViolation,
                    description: "Correct HPD violation: \(violation.novDescription)",
                    deadline: deadline,
                    priority: violation.severity
                ))
            }
        }
        
        // DOB Permit Renewals
        for permit in dobPermits.filter({ $0.isExpired }) {
            actions.append(RequiredAction(
                type: .renewPermit,
                description: "Renew \(permit.workType) permit",
                deadline: permit.expirationDate ?? "",
                priority: .high
            ))
        }
        
        return actions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Supporting Types

public struct ComplianceIssue {
    public let type: ComplianceIssueType
    public let severity: CoreTypes.ComplianceSeverity
    public let description: String
    public let source: String
    public let date: String
    public let deadline: String?
    public let fine: Double?
    
    public enum ComplianceIssueType {
        case hpdViolation
        case ll97Violation
        case expiredPermit
        case fdnyViolation
        case complaint311
    }
}

public struct RequiredAction {
    public let type: ActionType
    public let description: String
    public let deadline: String
    public let priority: CoreTypes.ComplianceSeverity
    
    public enum ActionType {
        case correctViolation
        case renewPermit
        case scheduleInspection
        case submitDocuments
        case payFines
    }
}

// MARK: - Extensions

// Date extension is in OperationalDataManager.swift

// ComplianceSeverity extensions moved to ComplianceIssue.swift to avoid duplicates