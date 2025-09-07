//
//  BuildingUnitValidator.swift
//  CyntientOps
//
//  Validates building unit counts against NYC APIs and user-provided data
//  Ensures DSNY compliance requirements are accurate
//

import Foundation
// Note: DSNYCompliance enum is now in DSNYCollectionSchedule.swift

// MARK: - Building Unit Validation Service

public struct BuildingUnitValidator {
    
    // MARK: - User-Provided Unit Counts (Ground Truth)
    
    /// User-provided RESIDENTIAL unit counts - these are the definitive source 
    /// DSNY compliance based on residential units only (commercial units excluded)
    public static let verifiedUnitCounts: [String: Int] = [
        // Spring Street - 4 residential + 1 commercial = 4 residential units for DSNY
        CanonicalIDs.Buildings.springStreet178: 4, // 4 residential, 1 commercial
        
        // Perry Street - all residential
        CanonicalIDs.Buildings.perry68: 6, // 6 residential units
        
        // First Avenue - 3 residential + 1 commercial = 3 residential units for DSNY  
        CanonicalIDs.Buildings.firstAvenue123: 3, // 3 residential, 1 commercial
        
        // 17th Street Buildings
        CanonicalIDs.Buildings.westSeventeenth136: 7, // Floors 2,3,4,5,6,7/8 penthouse,9/10 penthouse (ground commercial)
        CanonicalIDs.Buildings.westSeventeenth138: 8, // Floors 3-10 residential (2nd floor + ground = museum/offices)
        
        // Chambers Street
        CanonicalIDs.Buildings.chambers148: 7, // Confirmed by user
        
        // Additional buildings may need verification
        CanonicalIDs.Buildings.perry131: 3,
        CanonicalIDs.Buildings.westEighteenth112: 6,
        CanonicalIDs.Buildings.westSeventeenth117: 8
    ]
    
    // MARK: - DSNY Compliance Check
    
    /// Check if building requires individual bins based on unit count
    public static func requiresIndividualBins(buildingId: String) -> Bool {
        guard let unitCount = verifiedUnitCounts[buildingId] else {
            print("⚠️ BuildingUnitValidator: No unit count data for \(buildingId)")
            return false
        }
        
        // DSNY: Buildings with ≤9 units must use individual bins
        return unitCount <= DSNYCollectionSchedule.individualBinMaxUnits
    }
    
    /// Check if building can choose between bins and Empire containers
    public static func canChooseContainerType(buildingId: String) -> Bool {
        guard let unitCount = verifiedUnitCounts[buildingId] else { return false }
        
        // DSNY: Buildings with 10-30 units can choose
        return unitCount >= 10 && unitCount <= 30
    }
    
    /// Check if building must use Empire containers
    public static func requiresEmpireContainers(buildingId: String) -> Bool {
        guard let unitCount = verifiedUnitCounts[buildingId] else { return false }
        
        // DSNY: Buildings with 31+ units must use Empire containers
        return unitCount >= DSNYCollectionSchedule.empireContainerMinUnits
    }
    
    // MARK: - API Validation (Future Enhancement)
    
    /// Cross-reference user data with NYC Building API
    /// This will help identify discrepancies for manual review
    public static func validateAgainstNYCAPI(buildingId: String) async -> ValidationResult {
        // TODO: Implement actual NYC Building API calls
        // For now, return user data as authoritative
        
        guard let userUnitCount = verifiedUnitCounts[buildingId] else {
            return .noData(message: "No unit count available for building \(buildingId)")
        }
        
        // Placeholder for API validation
        // In production, would call:
        // - NYC Department of Buildings API
        // - PLUTO dataset
        // - Property records
        
        return .validated(
            buildingId: buildingId,
            userProvidedUnits: userUnitCount,
            apiUnits: nil, // Would be populated from API
            discrepancy: nil,
            dsnyCompliance: getDSNYCompliance(unitCount: userUnitCount)
        )
    }
    
    /// Get DSNY compliance requirements for unit count
    private static func getDSNYCompliance(unitCount: Int) -> DSNYCompliance {
        if unitCount <= 9 {
            return .individualBinsRequired
        } else if unitCount <= 30 {
            return .choiceBetweenBinsAndEmpire
        } else {
            return .empireContainersRequired
        }
    }
    
    // MARK: - Bulk Building Analysis
    
    /// Analyze all buildings for DSNY compliance
    public static func analyzeAllBuildings() -> [BuildingDSNYAnalysis] {
        return verifiedUnitCounts.map { (buildingId, unitCount) in
            BuildingDSNYAnalysis(
                buildingId: buildingId,
                unitCount: unitCount,
                dsnyCompliance: getDSNYCompliance(unitCount: unitCount),
                requiresBinManagement: requiresIndividualBins(buildingId: buildingId)
            )
        }
    }
    
    /// Get buildings that need bin management for routes
    public static func getBuildingsRequiringBinManagement() -> [String] {
        return verifiedUnitCounts.compactMap { (buildingId, _) in
            requiresIndividualBins(buildingId: buildingId) ? buildingId : nil
        }
    }
}

// MARK: - Supporting Types

public struct ValidationResult {
    public static func noData(message: String) -> ValidationResult {
        return ValidationResult(
            status: .noData,
            buildingId: "",
            userProvidedUnits: nil,
            apiUnits: nil,
            discrepancy: nil,
            dsnyCompliance: nil,
            message: message
        )
    }
    
    public static func validated(
        buildingId: String,
        userProvidedUnits: Int,
        apiUnits: Int?,
        discrepancy: Int?,
        dsnyCompliance: DSNYCompliance
    ) -> ValidationResult {
        return ValidationResult(
            status: .validated,
            buildingId: buildingId,
            userProvidedUnits: userProvidedUnits,
            apiUnits: apiUnits,
            discrepancy: discrepancy,
            dsnyCompliance: dsnyCompliance,
            message: nil
        )
    }
    
    public let status: ValidationStatus
    public let buildingId: String
    public let userProvidedUnits: Int?
    public let apiUnits: Int?
    public let discrepancy: Int?
    public let dsnyCompliance: DSNYCompliance?
    public let message: String?
    
    public enum ValidationStatus {
        case validated
        case discrepancy
        case noData
        case apiError
    }
}

// DSNYCompliance enum moved to DSNYCollectionSchedule.swift to avoid duplication

public struct BuildingDSNYAnalysis {
    public let buildingId: String
    public let unitCount: Int
    public let dsnyCompliance: DSNYCompliance
    public let requiresBinManagement: Bool
    
    public var summary: String {
        return "\(unitCount) units - \(dsnyCompliance.rawValue)"
    }
}

// MARK: - Integration with DSNYCollectionSchedule

extension DSNYCollectionSchedule {
    
    /// Get buildings requiring bin management based on validated unit counts
    public static func getValidatedBuildingsRequiringBins() -> [String] {
        return BuildingUnitValidator.getBuildingsRequiringBinManagement()
    }
    
    /// Check if building needs bin management using validated data
    public static func needsBinManagementValidated(buildingId: String) -> Bool {
        return BuildingUnitValidator.requiresIndividualBins(buildingId: buildingId)
    }
}