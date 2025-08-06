//
//  ViolationPredictor.swift
//  CyntientOps Phase 10
//
//  Violation Prediction Engine using historical pattern analysis
//  Provides building risk scoring and preventive suggestions with ROI calculations
//

import Foundation
import CoreML

@MainActor
public class ViolationPredictor: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var predictions: [ViolationPrediction] = []
    @Published public var riskScores: [String: BuildingRiskScore] = [:]
    @Published public var isAnalyzing = false
    @Published public var lastAnalysisTime: Date?
    
    // MARK: - Dependencies
    private let database: GRDBManager
    private let nycCompliance: NYCComplianceService
    private let analytics: PredictiveAnalytics
    
    // MARK: - Configuration
    private struct PredictionConfig {
        static let analysisInterval: TimeInterval = 24 * 60 * 60 // Daily
        static let predictionHorizonDays = 90 // 3 months ahead
        static let minHistoricalDataPoints = 10
        static let riskThresholds = (low: 0.3, medium: 0.6, high: 0.8)
    }
    
    public init(database: GRDBManager, nycCompliance: NYCComplianceService, analytics: PredictiveAnalytics) {
        self.database = database
        self.nycCompliance = nycCompliance
        self.analytics = analytics
        
        // Start periodic analysis
        Task {
            await performInitialAnalysis()
            await startPeriodicAnalysis()
        }
    }
    
    // MARK: - Public Methods
    
    /// Generate violation predictions for all buildings
    public func generatePredictions() async {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        defer { 
            isAnalyzing = false
            lastAnalysisTime = Date()
        }
        
        print("🔮 Starting violation prediction analysis...")
        
        do {
            // Get all active buildings
            let buildings = try await getAllBuildings()
            
            var newPredictions: [ViolationPrediction] = []
            var newRiskScores: [String: BuildingRiskScore] = [:]
            
            for building in buildings {
                // Analyze historical patterns
                let riskScore = try await calculateBuildingRiskScore(building)
                newRiskScores[building.id] = riskScore
                
                // Generate predictions based on risk
                let buildingPredictions = try await generateBuildingPredictions(building, riskScore: riskScore)
                newPredictions.append(contentsOf: buildingPredictions)
            }
            
            // Update published properties
            predictions = newPredictions.sorted { $0.riskScore > $1.riskScore }
            riskScores = newRiskScores
            
            print("✅ Violation prediction analysis completed: \(newPredictions.count) predictions generated")
            
        } catch {
            print("❌ Violation prediction analysis failed: \(error)")
        }
    }
    
    /// Get risk score for specific building
    public func getBuildingRiskScore(_ buildingId: String) -> BuildingRiskScore? {
        return riskScores[buildingId]
    }
    
    /// Get predictions for specific building
    public func getBuildingPredictions(_ buildingId: String) -> [ViolationPrediction] {
        return predictions.filter { $0.buildingId == buildingId }
    }
    
    /// Get high-risk buildings
    public func getHighRiskBuildings() -> [(String, BuildingRiskScore)] {
        return riskScores.compactMap { (buildingId, score) in
            score.overallRisk >= PredictionConfig.riskThresholds.high ? (buildingId, score) : nil
        }.sorted { $0.1.overallRisk > $1.1.overallRisk }
    }
    
    /// Get preventive action recommendations
    public func getPreventiveRecommendations(_ buildingId: String) -> [PreventiveRecommendation] {
        guard let riskScore = riskScores[buildingId] else { return [] }
        
        var recommendations: [PreventiveRecommendation] = []
        
        // HPD Violation Prevention
        if riskScore.hpdRisk >= PredictionConfig.riskThresholds.medium {
            recommendations.append(PreventiveRecommendation(
                type: .inspection,
                title: "Preventive HPD Inspection",
                description: "Schedule comprehensive inspection to identify potential violations early",
                estimatedCost: 500,
                potentialSavings: calculateViolationAvoidanceSavings(.hpd),
                priority: .high,
                timeframe: "Within 30 days",
                roiRatio: calculateViolationAvoidanceSavings(.hpd) / 500
            ))
        }
        
        // DOB Permit Management
        if riskScore.dobRisk >= PredictionConfig.riskThresholds.medium {
            recommendations.append(PreventiveRecommendation(
                type: .maintenance,
                title: "DOB Permit Audit",
                description: "Review all permits and upcoming expirations",
                estimatedCost: 300,
                potentialSavings: calculateViolationAvoidanceSavings(.dob),
                priority: .medium,
                timeframe: "Within 60 days",
                roiRatio: calculateViolationAvoidanceSavings(.dob) / 300
            ))
        }
        
        // LL97 Compliance
        if riskScore.ll97Risk >= PredictionConfig.riskThresholds.high {
            recommendations.append(PreventiveRecommendation(
                type: .upgrade,
                title: "Energy Efficiency Improvements",
                description: "Implement energy-saving measures to reduce LL97 emissions",
                estimatedCost: 15000,
                potentialSavings: calculateViolationAvoidanceSavings(.ll97),
                priority: .critical,
                timeframe: "Within 90 days",
                roiRatio: calculateViolationAvoidanceSavings(.ll97) / 15000
            ))
        }
        
        return recommendations.sorted { $0.roiRatio > $1.roiRatio }
    }
    
    /// Calculate ROI for preventive actions
    public func calculatePreventiveROI(_ buildingId: String) -> PreventiveROIAnalysis {
        let recommendations = getPreventiveRecommendations(buildingId)
        let totalInvestment = recommendations.reduce(0) { $0 + $1.estimatedCost }
        let totalPotentialSavings = recommendations.reduce(0) { $0 + $1.potentialSavings }
        
        let paybackPeriodMonths = totalInvestment > 0 ? (totalInvestment / (totalPotentialSavings / 12)) : 0
        let annualROI = totalInvestment > 0 ? ((totalPotentialSavings - totalInvestment) / totalInvestment * 100) : 0
        
        return PreventiveROIAnalysis(
            buildingId: buildingId,
            totalInvestment: totalInvestment,
            annualSavings: totalPotentialSavings,
            paybackPeriodMonths: paybackPeriodMonths,
            annualROIPercentage: annualROI,
            riskReduction: calculateRiskReduction(buildingId),
            recommendations: recommendations
        )
    }
    
    // MARK: - Private Methods
    
    private func performInitialAnalysis() async {
        await generatePredictions()
    }
    
    private func startPeriodicAnalysis() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(PredictionConfig.analysisInterval * 1_000_000_000))
            
            if !Task.isCancelled {
                await generatePredictions()
            }
        }
    }
    
    private func getAllBuildings() async throws -> [CoreTypes.NamedCoordinate] {
        let rows = try await database.query("""
            SELECT id, name, address, latitude, longitude, type, bin, bbl
            FROM buildings
            WHERE isActive = 1
        """)
        
        return rows.compactMap { row -> CoreTypes.NamedCoordinate? in
            guard let id = row["id"] as? String ?? (row["id"] as? Int64).map(String.init),
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lon = row["longitude"] as? Double,
                  let typeStr = row["type"] as? String else {
                return nil
            }
            
            let buildingType = CoreTypes.BuildingType(rawValue: typeStr) ?? .residential
            
            var metadata: [String: Any] = [:]
            if let bin = row["bin"] as? String { metadata["bin"] = bin }
            if let bbl = row["bbl"] as? String { metadata["bbl"] = bbl }
            
            return CoreTypes.NamedCoordinate(
                id: id,
                name: name,
                address: address,
                latitude: lat,
                longitude: lon,
                type: buildingType
            )
        }
    }
    
    private func calculateBuildingRiskScore(_ building: CoreTypes.NamedCoordinate) async throws -> BuildingRiskScore {
        // Get historical compliance data
        let complianceHistory = await getComplianceHistory(building.id)
        
        // Analyze patterns using ML if available, otherwise use heuristics
        let hpdRisk = calculateHPDRisk(complianceHistory)
        let dobRisk = calculateDOBRisk(complianceHistory)
        let ll97Risk = calculateLL97Risk(complianceHistory)
        let overallRisk = (hpdRisk + dobRisk + ll97Risk) / 3.0
        
        // Get historical violation trends
        let violationTrend = await calculateViolationTrend(building.id)
        
        return BuildingRiskScore(
            buildingId: building.id,
            buildingName: building.name,
            overallRisk: overallRisk,
            hpdRisk: hpdRisk,
            dobRisk: dobRisk,
            ll97Risk: ll97Risk,
            violationTrend: violationTrend,
            lastUpdated: Date(),
            confidenceLevel: calculateConfidenceLevel(complianceHistory.count),
            riskFactors: identifyRiskFactors(complianceHistory)
        )
    }
    
    private func generateBuildingPredictions(_ building: CoreTypes.NamedCoordinate, riskScore: BuildingRiskScore) async throws -> [ViolationPrediction] {
        var predictions: [ViolationPrediction] = []
        
        // Generate HPD violation predictions
        if riskScore.hpdRisk > PredictionConfig.riskThresholds.low {
            let hpdPrediction = ViolationPrediction(
                buildingId: building.id,
                buildingName: building.name,
                violationType: .hpd,
                riskScore: riskScore.hpdRisk,
                predictedDate: Date().addingTimeInterval(TimeInterval(30 * 24 * 60 * 60)), // 30 days
                confidence: riskScore.confidenceLevel,
                estimatedFine: calculateEstimatedFine(.hpd, risk: riskScore.hpdRisk),
                preventiveActions: getPreventiveActions(.hpd, risk: riskScore.hpdRisk),
                description: generatePredictionDescription(.hpd, risk: riskScore.hpdRisk)
            )
            predictions.append(hpdPrediction)
        }
        
        // Generate DOB violation predictions
        if riskScore.dobRisk > PredictionConfig.riskThresholds.low {
            let dobPrediction = ViolationPrediction(
                buildingId: building.id,
                buildingName: building.name,
                violationType: .dob,
                riskScore: riskScore.dobRisk,
                predictedDate: Date().addingTimeInterval(TimeInterval(45 * 24 * 60 * 60)), // 45 days
                confidence: riskScore.confidenceLevel,
                estimatedFine: calculateEstimatedFine(.dob, risk: riskScore.dobRisk),
                preventiveActions: getPreventiveActions(.dob, risk: riskScore.dobRisk),
                description: generatePredictionDescription(.dob, risk: riskScore.dobRisk)
            )
            predictions.append(dobPrediction)
        }
        
        // Generate LL97 compliance predictions
        if riskScore.ll97Risk > PredictionConfig.riskThresholds.medium {
            let ll97Prediction = ViolationPrediction(
                buildingId: building.id,
                buildingName: building.name,
                violationType: .ll97,
                riskScore: riskScore.ll97Risk,
                predictedDate: Date().addingTimeInterval(TimeInterval(60 * 24 * 60 * 60)), // 60 days
                confidence: riskScore.confidenceLevel,
                estimatedFine: calculateEstimatedFine(.ll97, risk: riskScore.ll97Risk),
                preventiveActions: getPreventiveActions(.ll97, risk: riskScore.ll97Risk),
                description: generatePredictionDescription(.ll97, risk: riskScore.ll97Risk)
            )
            predictions.append(ll97Prediction)
        }
        
        return predictions
    }
    
    private func getComplianceHistory(_ buildingId: String) async -> [ComplianceEvent] {
        do {
            let rows = try await database.query("""
                SELECT source, severity, reported_date, resolved_date
                FROM compliance_issues
                WHERE building_id = ?
                AND reported_date > date('now', '-2 years')
                ORDER BY reported_date DESC
            """, [buildingId])
            
            return rows.compactMap { row -> ComplianceEvent? in
                guard let source = row["source"] as? String,
                      let severityStr = row["severity"] as? String,
                      let reportedDateStr = row["reported_date"] as? String else {
                    return nil
                }
                
                let reportedDate = parseDate(reportedDateStr) ?? Date()
                let resolvedDate = parseDate(row["resolved_date"] as? String)
                let severity = CoreTypes.ComplianceSeverity(rawValue: severityStr) ?? .medium
                
                return ComplianceEvent(
                    source: source,
                    severity: severity,
                    reportedDate: reportedDate,
                    resolvedDate: resolvedDate
                )
            }
        } catch {
            print("Failed to get compliance history: \(error)")
            return []
        }
    }
    
    private func calculateHPDRisk(_ history: [ComplianceEvent]) -> Double {
        let hpdEvents = history.filter { $0.source == "HPD" }
        
        if hpdEvents.isEmpty { return 0.1 } // Low baseline risk
        
        let recentEvents = hpdEvents.filter { $0.reportedDate > Date().addingTimeInterval(-365 * 24 * 60 * 60) }
        let unresolved = hpdEvents.filter { $0.resolvedDate == nil }.count
        let criticalEvents = hpdEvents.filter { $0.severity == .critical }.count
        
        let riskScore = min(1.0, Double(recentEvents.count) * 0.1 + Double(unresolved) * 0.15 + Double(criticalEvents) * 0.2)
        return riskScore
    }
    
    private func calculateDOBRisk(_ history: [ComplianceEvent]) -> Double {
        let dobEvents = history.filter { $0.source == "DOB" }
        
        if dobEvents.isEmpty { return 0.05 } // Very low baseline risk
        
        let recentEvents = dobEvents.filter { $0.reportedDate > Date().addingTimeInterval(-365 * 24 * 60 * 60) }
        let unresolved = dobEvents.filter { $0.resolvedDate == nil }.count
        
        let riskScore = min(1.0, Double(recentEvents.count) * 0.08 + Double(unresolved) * 0.12)
        return riskScore
    }
    
    private func calculateLL97Risk(_ history: [ComplianceEvent]) -> Double {
        let ll97Events = history.filter { $0.source == "LL97" }
        
        if ll97Events.isEmpty { return 0.3 } // Medium baseline risk for LL97
        
        let recentEvents = ll97Events.filter { $0.reportedDate > Date().addingTimeInterval(-365 * 24 * 60 * 60) }
        let unresolved = ll97Events.filter { $0.resolvedDate == nil }.count
        
        let riskScore = min(1.0, 0.3 + Double(recentEvents.count) * 0.15 + Double(unresolved) * 0.25)
        return riskScore
    }
    
    private func calculateViolationTrend(_ buildingId: String) async -> ViolationTrend {
        do {
            let sixMonthsAgo = Date().addingTimeInterval(-6 * 30 * 24 * 60 * 60)
            let oneYearAgo = Date().addingTimeInterval(-12 * 30 * 24 * 60 * 60)
            
            let recentCount = try await database.query("""
                SELECT COUNT(*) as count FROM compliance_issues
                WHERE building_id = ? AND reported_date > ?
            """, [buildingId, sixMonthsAgo.timeIntervalSince1970]).first?["count"] as? Int64 ?? 0
            
            let olderCount = try await database.query("""
                SELECT COUNT(*) as count FROM compliance_issues
                WHERE building_id = ? AND reported_date BETWEEN ? AND ?
            """, [buildingId, oneYearAgo.timeIntervalSince1970, sixMonthsAgo.timeIntervalSince1970]).first?["count"] as? Int64 ?? 0
            
            if olderCount == 0 {
                return recentCount > 0 ? .increasing : .stable
            }
            
            let changeRatio = Double(recentCount) / Double(olderCount)
            
            if changeRatio > 1.2 {
                return .increasing
            } else if changeRatio < 0.8 {
                return .decreasing
            } else {
                return .stable
            }
            
        } catch {
            return .stable
        }
    }
    
    private func calculateConfidenceLevel(_ dataPoints: Int) -> Double {
        if dataPoints >= PredictionConfig.minHistoricalDataPoints {
            return min(0.9, 0.3 + Double(dataPoints) * 0.05)
        } else {
            return 0.1 + Double(dataPoints) * 0.02
        }
    }
    
    private func identifyRiskFactors(_ history: [ComplianceEvent]) -> [String] {
        var factors: [String] = []
        
        let unresolvedCount = history.filter { $0.resolvedDate == nil }.count
        if unresolvedCount > 0 {
            factors.append("Unresolved violations: \(unresolvedCount)")
        }
        
        let criticalCount = history.filter { $0.severity == .critical }.count
        if criticalCount > 0 {
            factors.append("Critical violations: \(criticalCount)")
        }
        
        let recentCount = history.filter { $0.reportedDate > Date().addingTimeInterval(-90 * 24 * 60 * 60) }.count
        if recentCount > 2 {
            factors.append("Recent violation spike")
        }
        
        return factors
    }
    
    private func calculateEstimatedFine(_ type: ViolationType, risk: Double) -> Double {
        let baseFines: [ViolationType: Double] = [
            .hpd: 1500,
            .dob: 2500,
            .ll97: 25000
        ]
        
        return (baseFines[type] ?? 1000) * (1 + risk)
    }
    
    private func getPreventiveActions(_ type: ViolationType, risk: Double) -> [String] {
        switch type {
        case .hpd:
            return risk > 0.7 ? ["Schedule immediate inspection", "Review heating systems", "Check for code violations"] :
                               ["Routine maintenance check", "Update tenant communications"]
        case .dob:
            return risk > 0.7 ? ["Audit all permits", "Schedule permit renewals", "Review construction compliance"] :
                               ["Check permit expiration dates", "Update building records"]
        case .ll97:
            return risk > 0.7 ? ["Energy audit", "HVAC system upgrade", "Building envelope improvements"] :
                               ["Monitor energy usage", "Schedule efficiency assessment"]
        }
    }
    
    private func generatePredictionDescription(_ type: ViolationType, risk: Double) -> String {
        let riskLevel = risk > 0.8 ? "very high" : risk > 0.6 ? "high" : "moderate"
        
        switch type {
        case .hpd:
            return "Based on historical patterns, this building has a \(riskLevel) risk of receiving HPD violations in the next 30 days."
        case .dob:
            return "Analysis indicates a \(riskLevel) probability of DOB compliance issues or permit expirations in the next 45 days."
        case .ll97:
            return "Energy usage patterns suggest a \(riskLevel) risk of exceeding LL97 emissions limits in the next reporting period."
        }
    }
    
    private func calculateViolationAvoidanceSavings(_ type: ViolationType) -> Double {
        switch type {
        case .hpd:
            return 5000 // Average cost of HPD violation resolution
        case .dob:
            return 8000 // Average cost of DOB violation and delays
        case .ll97:
            return 50000 // Average LL97 fine
        }
    }
    
    private func calculateRiskReduction(_ buildingId: String) -> Double {
        // Estimated risk reduction from implementing all recommendations
        return 0.6 // 60% risk reduction
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
}

// MARK: - Supporting Types

public struct ViolationPrediction: Identifiable {
    public let id = UUID()
    public let buildingId: String
    public let buildingName: String
    public let violationType: ViolationType
    public let riskScore: Double
    public let predictedDate: Date
    public let confidence: Double
    public let estimatedFine: Double
    public let preventiveActions: [String]
    public let description: String
    
    public var riskLevel: String {
        switch riskScore {
        case 0.8...: return "Very High"
        case 0.6..<0.8: return "High"
        case 0.4..<0.6: return "Moderate"
        case 0.2..<0.4: return "Low"
        default: return "Very Low"
        }
    }
}

public struct BuildingRiskScore {
    public let buildingId: String
    public let buildingName: String
    public let overallRisk: Double
    public let hpdRisk: Double
    public let dobRisk: Double
    public let ll97Risk: Double
    public let violationTrend: ViolationTrend
    public let lastUpdated: Date
    public let confidenceLevel: Double
    public let riskFactors: [String]
}

public struct PreventiveRecommendation {
    public let type: ActionType
    public let title: String
    public let description: String
    public let estimatedCost: Double
    public let potentialSavings: Double
    public let priority: Priority
    public let timeframe: String
    public let roiRatio: Double
    
    public enum ActionType {
        case inspection
        case maintenance
        case upgrade
        case documentation
    }
    
    public enum Priority {
        case critical
        case high
        case medium
        case low
    }
}

public struct PreventiveROIAnalysis {
    public let buildingId: String
    public let totalInvestment: Double
    public let annualSavings: Double
    public let paybackPeriodMonths: Double
    public let annualROIPercentage: Double
    public let riskReduction: Double
    public let recommendations: [PreventiveRecommendation]
}

public enum ViolationType: String, CaseIterable {
    case hpd = "HPD"
    case dob = "DOB"
    case ll97 = "LL97"
}

public enum ViolationTrend {
    case increasing
    case stable
    case decreasing
}

private struct ComplianceEvent {
    let source: String
    let severity: CoreTypes.ComplianceSeverity
    let reportedDate: Date
    let resolvedDate: Date?
}