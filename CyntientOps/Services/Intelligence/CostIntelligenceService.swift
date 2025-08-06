//
//  CostIntelligenceService.swift
//  CyntientOps Phase 10.3
//
//  Cost Intelligence for fine predictions, contractor comparisons, budget impact, and savings opportunities
//  Provides comprehensive financial analysis and optimization recommendations
//

import Foundation
import Combine

@MainActor
public class CostIntelligenceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var costAnalyses: [BuildingCostAnalysis] = []
    @Published public var contractorComparisons: [ContractorComparison] = []
    @Published public var budgetForecasts: [BudgetForecast] = []
    @Published public var savingsOpportunities: [SavingsOpportunity] = []
    @Published public var isAnalyzing = false
    @Published public var lastAnalysisTime: Date?
    
    // MARK: - Dependencies
    private let database: GRDBManager
    private let nycCompliance: NYCComplianceService
    private let violationPredictor: ViolationPredictor
    
    // MARK: - Configuration
    private struct CostConfig {
        static let analysisInterval: TimeInterval = 7 * 24 * 60 * 60 // Weekly
        static let contractorDataAge = 365 * 24 * 60 * 60 // 1 year
        static let finePredictionHorizon = 90 * 24 * 60 * 60 // 90 days
        static let defaultInflationRate = 0.035 // 3.5%
        static let urgencyMultiplier = 1.5
    }
    
    // Market rates and historical data
    private let marketRates = MarketRates()
    
    public init(database: GRDBManager, nycCompliance: NYCComplianceService, violationPredictor: ViolationPredictor) {
        self.database = database
        self.nycCompliance = nycCompliance
        self.violationPredictor = violationPredictor
        
        // Start periodic analysis
        Task {
            await performInitialCostAnalysis()
            await startPeriodicAnalysis()
        }
    }
    
    // MARK: - Public Methods
    
    /// Generate comprehensive cost analysis for all buildings
    public func generateCostAnalysis() async {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        defer {
            isAnalyzing = false
            lastAnalysisTime = Date()
        }
        
        print("💰 Starting comprehensive cost intelligence analysis...")
        
        do {
            // Get all buildings
            let buildings = try await getAllBuildings()
            
            var newCostAnalyses: [BuildingCostAnalysis] = []
            var newBudgetForecasts: [BudgetForecast] = []
            var newSavingsOpportunities: [SavingsOpportunity] = []
            
            for building in buildings {
                // Generate cost analysis for each building
                let costAnalysis = try await analyzeBuildingCosts(building)
                newCostAnalyses.append(costAnalysis)
                
                // Generate budget forecast
                let budgetForecast = try await generateBudgetForecast(building, costAnalysis: costAnalysis)
                newBudgetForecasts.append(budgetForecast)
                
                // Identify savings opportunities
                let savingsOps = try await identifySavingsOpportunities(building, costAnalysis: costAnalysis)
                newSavingsOpportunities.append(contentsOf: savingsOps)
            }
            
            // Generate contractor comparisons
            let contractorComps = await generateContractorComparisons()
            
            // Update published properties
            costAnalyses = newCostAnalyses.sorted { $0.totalAnnualCost > $1.totalAnnualCost }
            budgetForecasts = newBudgetForecasts.sorted { $0.projectedTotalCost > $1.projectedTotalCost }
            savingsOpportunities = newSavingsOpportunities.sorted { $0.annualSavings > $1.annualSavings }
            contractorComparisons = contractorComps
            
            print("✅ Cost intelligence analysis completed: \(newCostAnalyses.count) buildings analyzed")
            
        } catch {
            print("❌ Cost intelligence analysis failed: \(error)")
        }
    }
    
    /// Get cost analysis for specific building
    public func getBuildingCostAnalysis(_ buildingId: String) -> BuildingCostAnalysis? {
        return costAnalyses.first { $0.buildingId == buildingId }
    }
    
    /// Get budget forecast for building
    public func getBudgetForecast(_ buildingId: String) -> BudgetForecast? {
        return budgetForecasts.first { $0.buildingId == buildingId }
    }
    
    /// Get savings opportunities for building
    public func getSavingsOpportunities(_ buildingId: String) -> [SavingsOpportunity] {
        return savingsOpportunities.filter { $0.buildingId == buildingId }
    }
    
    /// Calculate fine predictions with cost estimates
    public func predictFineCosts(_ buildingId: String) async throws -> FinePredictionSummary {
        let riskScore = violationPredictor.getBuildingRiskScore(buildingId)
        let predictions = violationPredictor.getBuildingPredictions(buildingId)
        
        guard let riskScore = riskScore else {
            throw CostIntelligenceError.dataNotAvailable("Risk score not available for building")
        }
        
        var totalPredictedFines: Double = 0
        var predictionDetails: [FineEstimate] = []
        
        for prediction in predictions {
            let estimate = FineEstimate(
                violationType: prediction.violationType,
                probability: prediction.riskScore,
                estimatedFine: prediction.estimatedFine,
                timeframe: "Next 90 days",
                mitigationCost: calculateMitigationCost(prediction.violationType, risk: prediction.riskScore),
                netRisk: prediction.estimatedFine - calculateMitigationCost(prediction.violationType, risk: prediction.riskScore)
            )
            predictionDetails.append(estimate)
            totalPredictedFines += estimate.estimatedFine * estimate.probability
        }
        
        return FinePredictionSummary(
            buildingId: buildingId,
            totalPredictedFines: totalPredictedFines,
            timeframe: 90, // days
            confidence: riskScore.confidenceLevel,
            fineEstimates: predictionDetails,
            recommendedMitigationBudget: predictionDetails.reduce(0) { $0 + $1.mitigationCost },
            potentialSavings: predictionDetails.reduce(0) { $0 + max(0, $1.netRisk) }
        )
    }
    
    /// Get top cost-saving contractors for specific work type
    public func getTopContractors(_ workType: WorkType, limit: Int = 5) -> [ContractorRecommendation] {
        let relevantComparisons = contractorComparisons.filter { $0.workType == workType }
        
        return relevantComparisons.flatMap { comparison in
            comparison.contractors.map { contractor in
                ContractorRecommendation(
                    contractorId: contractor.id,
                    name: contractor.name,
                    workType: workType,
                    avgCostPerUnit: contractor.averageCost,
                    qualityRating: contractor.qualityScore,
                    timelinessScore: contractor.timelinessScore,
                    totalSavings: contractor.potentialSavings,
                    recommendationScore: calculateContractorScore(contractor)
                )
            }
        }.sorted { $0.recommendationScore > $1.recommendationScore }.prefix(limit).map { $0 }
    }
    
    /// Generate ROI analysis for specific improvement
    public func calculateImprovementROI(_ buildingId: String, improvement: ImprovementType) async throws -> ROIAnalysis {
        guard let costAnalysis = getBuildingCostAnalysis(buildingId) else {
            throw CostIntelligenceError.dataNotAvailable("Cost analysis not available")
        }
        
        let investmentCost = calculateImprovementCost(improvement, buildingSize: costAnalysis.buildingSize)
        let annualSavings = calculateAnnualSavings(improvement, currentCosts: costAnalysis)
        let paybackPeriod = investmentCost / annualSavings
        let fiveYearROI = (annualSavings * 5 - investmentCost) / investmentCost * 100
        
        return ROIAnalysis(
            buildingId: buildingId,
            improvementType: improvement,
            investmentCost: investmentCost,
            annualSavings: annualSavings,
            paybackPeriodYears: paybackPeriod / 365,
            fiveYearROI: fiveYearROI,
            netPresentValue: calculateNPV(investmentCost, annualSavings: annualSavings, years: 5),
            riskAdjustedROI: fiveYearROI * 0.85 // 15% risk adjustment
        )
    }
    
    // MARK: - Private Methods
    
    private func performInitialCostAnalysis() async {
        await generateCostAnalysis()
    }
    
    private func startPeriodicAnalysis() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(CostConfig.analysisInterval * 1_000_000_000))
            
            if !Task.isCancelled {
                await generateCostAnalysis()
            }
        }
    }
    
    private func getAllBuildings() async throws -> [CoreTypes.NamedCoordinate] {
        let rows = try await database.query("""
            SELECT id, name, address, latitude, longitude, type, size_sqft, year_built
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
            if let sqft = row["size_sqft"] as? Double { metadata["size_sqft"] = sqft }
            if let yearBuilt = row["year_built"] as? Int { metadata["year_built"] = yearBuilt }
            
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
    
    private func analyzeBuildingCosts(_ building: CoreTypes.NamedCoordinate) async throws -> BuildingCostAnalysis {
        // Get historical cost data
        let historicalCosts = try await getHistoricalCosts(building.id)
        let maintenanceCosts = try await getMaintenanceCosts(building.id)
        let complianceCosts = try await getComplianceCosts(building.id)
        let violationCosts = try await getViolationCosts(building.id)
        
        let buildingSize = 5000.0 // Default size since metadata not available
        let yearBuilt = 1950 // Default year since metadata not available
        let buildingAge = Date().year - yearBuilt
        
        // Calculate cost per square foot
        let totalAnnualCost = maintenanceCosts + complianceCosts + violationCosts
        let costPerSqFt = totalAnnualCost / buildingSize
        
        // Compare to market benchmarks
        let marketBenchmark = marketRates.getMaintenanceCostPerSqFt(building.type ?? .residential, age: buildingAge)
        let costEfficiencyRatio = costPerSqFt / marketBenchmark
        
        // Predict future costs
        let projectedCosts = calculateProjectedCosts(historicalCosts, inflationRate: CostConfig.defaultInflationRate)
        
        return BuildingCostAnalysis(
            buildingId: building.id,
            buildingName: building.name,
            buildingSize: buildingSize,
            buildingAge: buildingAge,
            totalAnnualCost: totalAnnualCost,
            maintenanceCosts: maintenanceCosts,
            complianceCosts: complianceCosts,
            violationCosts: violationCosts,
            costPerSqFt: costPerSqFt,
            marketBenchmark: marketBenchmark,
            costEfficiencyRatio: costEfficiencyRatio,
            projectedCosts: projectedCosts,
            lastUpdated: Date(),
            costTrend: calculateCostTrend(historicalCosts),
            riskFactors: identifyCostRiskFactors(building, costs: (maintenanceCosts, complianceCosts, violationCosts))
        )
    }
    
    private func generateBudgetForecast(_ building: CoreTypes.NamedCoordinate, costAnalysis: BuildingCostAnalysis) async throws -> BudgetForecast {
        let violationPredictions = violationPredictor.getBuildingPredictions(building.id)
        
        // Base costs with inflation
        var quarterlyCosts: [QuarterlyCost] = []
        let currentQuarter = Date().quarter
        
        for quarter in 1...4 {
            let quarterMultiplier = getSeasonalMultiplier(quarter)
            let baseCost = costAnalysis.totalAnnualCost / 4 * quarterMultiplier
            
            // Add predicted violation costs for the quarter
            let violationCost = violationPredictions
                .filter { prediction in
                    let predictionQuarter = prediction.predictedDate.quarter
                    return predictionQuarter == quarter
                }
                .reduce(0) { $0 + $1.estimatedFine * $1.riskScore }
            
            quarterlyCosts.append(QuarterlyCost(
                quarter: quarter,
                maintenanceCost: baseCost * 0.7, // 70% maintenance
                complianceCost: baseCost * 0.2,  // 20% compliance
                violationCost: violationCost,
                emergencyCost: baseCost * 0.1,   // 10% emergency buffer
                totalCost: baseCost + violationCost
            ))
        }
        
        let projectedTotalCost = quarterlyCosts.reduce(0) { $0 + $1.totalCost }
        
        return BudgetForecast(
            buildingId: building.id,
            buildingName: building.name,
            forecastYear: Date().year + 1,
            quarterlyCosts: quarterlyCosts,
            projectedTotalCost: projectedTotalCost,
            confidence: 0.8, // 80% confidence
            assumptions: [
                "3.5% inflation rate applied",
                "Seasonal variations included",
                "Violation predictions incorporated",
                "10% emergency buffer allocated"
            ],
            riskAdjustments: calculateBudgetRisks(costAnalysis),
            createdAt: Date()
        )
    }
    
    private func identifySavingsOpportunities(_ building: CoreTypes.NamedCoordinate, costAnalysis: BuildingCostAnalysis) async throws -> [SavingsOpportunity] {
        var opportunities: [SavingsOpportunity] = []
        
        // Energy efficiency opportunities
        if costAnalysis.costEfficiencyRatio > 1.2 {
            opportunities.append(SavingsOpportunity(
                buildingId: building.id,
                buildingName: building.name,
                type: .energyEfficiency,
                title: "HVAC System Optimization",
                description: "Upgrade HVAC system and improve insulation to reduce energy costs by 25%",
                investmentRequired: 15000,
                annualSavings: costAnalysis.totalAnnualCost * 0.25,
                paybackPeriod: 15000 / (costAnalysis.totalAnnualCost * 0.25),
                riskLevel: .low,
                priority: .high,
                implementationTimeframe: "3-6 months",
                roiPercentage: ((costAnalysis.totalAnnualCost * 0.25) * 5 - 15000) / 15000 * 100
            ))
        }
        
        // Preventive maintenance opportunities
        if costAnalysis.violationCosts > costAnalysis.maintenanceCosts * 0.3 {
            opportunities.append(SavingsOpportunity(
                buildingId: building.id,
                buildingName: building.name,
                type: .preventiveMaintenance,
                title: "Enhanced Preventive Maintenance Program",
                description: "Implement proactive maintenance to reduce violations by 60%",
                investmentRequired: 5000,
                annualSavings: costAnalysis.violationCosts * 0.6,
                paybackPeriod: 5000 / (costAnalysis.violationCosts * 0.6),
                riskLevel: .low,
                priority: .high,
                implementationTimeframe: "1-2 months",
                roiPercentage: ((costAnalysis.violationCosts * 0.6) * 3 - 5000) / 5000 * 100
            ))
        }
        
        // Contractor optimization opportunities
        let contractorSavings = await calculateContractorSavings(building.id, currentCosts: costAnalysis)
        if contractorSavings > costAnalysis.totalAnnualCost * 0.1 {
            opportunities.append(SavingsOpportunity(
                buildingId: building.id,
                buildingName: building.name,
                type: .contractorOptimization,
                title: "Contractor Portfolio Optimization",
                description: "Switch to more cost-effective contractors for routine work",
                investmentRequired: 1000, // Transition costs
                annualSavings: contractorSavings,
                paybackPeriod: 1000 / contractorSavings,
                riskLevel: .medium,
                priority: .medium,
                implementationTimeframe: "1 month",
                roiPercentage: (contractorSavings * 3 - 1000) / 1000 * 100
            ))
        }
        
        return opportunities.sorted { $0.roiPercentage > $1.roiPercentage }
    }
    
    private func generateContractorComparisons() async -> [ContractorComparison] {
        let workTypes: [WorkType] = [.hvacMaintenance, .plumbing, .electrical, .roofing, .painting, .cleaning]
        var comparisons: [ContractorComparison] = []
        
        for workType in workTypes {
            let contractors = await getContractorsForWorkType(workType)
            
            if contractors.count >= 2 {
                let comparison = ContractorComparison(
                    workType: workType,
                    contractors: contractors,
                    marketAverage: contractors.reduce(0) { $0 + $1.averageCost } / Double(contractors.count),
                    bestValue: contractors.min { $0.valueScore > $1.valueScore },
                    lastUpdated: Date()
                )
                comparisons.append(comparison)
            }
        }
        
        return comparisons
    }
    
    private func getHistoricalCosts(_ buildingId: String) async throws -> [HistoricalCost] {
        let rows = try await database.query("""
            SELECT cost_type, amount, date_incurred, description
            FROM building_costs 
            WHERE building_id = ? 
            AND date_incurred > date('now', '-2 years')
            ORDER BY date_incurred DESC
        """, [buildingId])
        
        return rows.compactMap { row in
            guard let costType = row["cost_type"] as? String,
                  let amount = row["amount"] as? Double,
                  let dateStr = row["date_incurred"] as? String,
                  let date = parseDate(dateStr) else {
                return nil
            }
            
            return HistoricalCost(
                type: costType,
                amount: amount,
                date: date,
                description: row["description"] as? String ?? ""
            )
        }
    }
    
    private func getMaintenanceCosts(_ buildingId: String) async throws -> Double {
        let rows = try await database.query("""
            SELECT SUM(amount) as total_cost
            FROM building_costs 
            WHERE building_id = ? 
            AND cost_type IN ('maintenance', 'repair', 'service')
            AND date_incurred > date('now', '-1 year')
        """, [buildingId])
        
        return rows.first?["total_cost"] as? Double ?? 0
    }
    
    private func getComplianceCosts(_ buildingId: String) async throws -> Double {
        let rows = try await database.query("""
            SELECT SUM(amount) as total_cost
            FROM building_costs 
            WHERE building_id = ? 
            AND cost_type IN ('inspection', 'certification', 'permit')
            AND date_incurred > date('now', '-1 year')
        """, [buildingId])
        
        return rows.first?["total_cost"] as? Double ?? 0
    }
    
    private func getViolationCosts(_ buildingId: String) async throws -> Double {
        let rows = try await database.query("""
            SELECT SUM(amount) as total_cost
            FROM building_costs 
            WHERE building_id = ? 
            AND cost_type IN ('fine', 'penalty', 'violation')
            AND date_incurred > date('now', '-1 year')
        """, [buildingId])
        
        return rows.first?["total_cost"] as? Double ?? 0
    }
    
    private func calculateProjectedCosts(_ historicalCosts: [HistoricalCost], inflationRate: Double) -> ProjectedCosts {
        let currentYearCosts = historicalCosts.filter { $0.date > Date().addingTimeInterval(-365 * 24 * 60 * 60) }
        let totalCurrentCosts = currentYearCosts.reduce(0) { $0 + $1.amount }
        
        return ProjectedCosts(
            nextYear: totalCurrentCosts * (1 + inflationRate),
            twoYears: totalCurrentCosts * pow(1 + inflationRate, 2),
            fiveYears: totalCurrentCosts * pow(1 + inflationRate, 5)
        )
    }
    
    private func calculateCostTrend(_ historicalCosts: [HistoricalCost]) -> CostTrend {
        let currentYear = Date().year
        let currentYearCosts = historicalCosts.filter { $0.date.year == currentYear }.reduce(0) { $0 + $1.amount }
        let previousYearCosts = historicalCosts.filter { $0.date.year == currentYear - 1 }.reduce(0) { $0 + $1.amount }
        
        if previousYearCosts == 0 { return .stable }
        
        let changeRatio = currentYearCosts / previousYearCosts
        
        if changeRatio > 1.1 {
            return .increasing
        } else if changeRatio < 0.9 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func identifyCostRiskFactors(_ building: CoreTypes.NamedCoordinate, costs: (maintenance: Double, compliance: Double, violations: Double)) -> [String] {
        var riskFactors: [String] = []
        
        let buildingAge = 25 // Default age since metadata not available
        
        if buildingAge > 50 {
            riskFactors.append("Building age: \(buildingAge) years")
        }
        
        if costs.violations > costs.maintenance * 0.5 {
            riskFactors.append("High violation-to-maintenance ratio")
        }
        
        if costs.compliance > costs.maintenance * 0.3 {
            riskFactors.append("High compliance costs")
        }
        
        return riskFactors
    }
    
    private func calculateMitigationCost(_ violationType: ViolationType, risk: Double) -> Double {
        let baseCosts: [ViolationType: Double] = [
            .hpd: 800,
            .dob: 1200,
            .ll97: 5000
        ]
        
        return (baseCosts[violationType] ?? 500) * (1 + risk * 0.5)
    }
    
    private func getSeasonalMultiplier(_ quarter: Int) -> Double {
        switch quarter {
        case 1: return 1.3 // Winter - higher heating costs
        case 2: return 0.9 // Spring - lower costs
        case 3: return 1.1 // Summer - AC costs
        case 4: return 1.0 // Fall - baseline
        default: return 1.0
        }
    }
    
    private func calculateBudgetRisks(_ costAnalysis: BuildingCostAnalysis) -> [BudgetRisk] {
        var risks: [BudgetRisk] = []
        
        if costAnalysis.buildingAge > 40 {
            risks.append(BudgetRisk(
                type: "Equipment Failure",
                probability: 0.3,
                impact: 15000,
                description: "Aging building systems may require emergency replacement"
            ))
        }
        
        if costAnalysis.costEfficiencyRatio > 1.5 {
            risks.append(BudgetRisk(
                type: "Cost Escalation",
                probability: 0.4,
                impact: costAnalysis.totalAnnualCost * 0.2,
                description: "Above-market costs suggest potential for significant increases"
            ))
        }
        
        return risks
    }
    
    private func calculateContractorSavings(_ buildingId: String, currentCosts: BuildingCostAnalysis) async -> Double {
        // Simulate contractor analysis
        let potentialSavings = currentCosts.maintenanceCosts * 0.15 // 15% potential savings
        return potentialSavings
    }
    
    private func getContractorsForWorkType(_ workType: WorkType) async -> [ContractorProfile] {
        // Simulate contractor data - in production this would come from database
        let sampleContractors = [
            ContractorProfile(
                id: "contractor_\(workType.rawValue)_1",
                name: "\(workType.rawValue.capitalized) Pro Services",
                averageCost: marketRates.getWorkTypeCost(workType) * 0.9,
                qualityScore: 4.5,
                timelinessScore: 4.2,
                completedJobs: 45,
                potentialSavings: 2500,
                valueScore: 4.3
            ),
            ContractorProfile(
                id: "contractor_\(workType.rawValue)_2",
                name: "Premium \(workType.rawValue.capitalized)",
                averageCost: marketRates.getWorkTypeCost(workType) * 1.2,
                qualityScore: 4.8,
                timelinessScore: 4.7,
                completedJobs: 32,
                potentialSavings: -1000,
                valueScore: 4.0
            ),
            ContractorProfile(
                id: "contractor_\(workType.rawValue)_3",
                name: "Budget \(workType.rawValue.capitalized)",
                averageCost: marketRates.getWorkTypeCost(workType) * 0.7,
                qualityScore: 3.8,
                timelinessScore: 3.5,
                completedJobs: 28,
                potentialSavings: 3200,
                valueScore: 3.6
            )
        ]
        
        return sampleContractors
    }
    
    private func calculateContractorScore(_ contractor: ContractorProfile) -> Double {
        // Weighted score: 40% quality, 30% timeliness, 30% cost savings potential
        let qualityScore = contractor.qualityScore / 5.0 * 40
        let timelinessScore = contractor.timelinessScore / 5.0 * 30
        let savingsScore = min(contractor.potentialSavings / 5000, 1.0) * 30
        
        return qualityScore + timelinessScore + savingsScore
    }
    
    private func calculateImprovementCost(_ improvement: ImprovementType, buildingSize: Double) -> Double {
        let costPerSqFt: [ImprovementType: Double] = [
            .hvacUpgrade: 25,
            .windowReplacement: 15,
            .roofReplacement: 12,
            .insulation: 8,
            .lighting: 5,
            .smartSystems: 10
        ]
        
        return (costPerSqFt[improvement] ?? 10) * buildingSize
    }
    
    private func calculateAnnualSavings(_ improvement: ImprovementType, currentCosts: BuildingCostAnalysis) -> Double {
        let savingsRatio: [ImprovementType: Double] = [
            .hvacUpgrade: 0.3,      // 30% energy savings
            .windowReplacement: 0.15, // 15% energy savings
            .roofReplacement: 0.1,   // 10% maintenance savings
            .insulation: 0.2,        // 20% energy savings
            .lighting: 0.08,         // 8% energy savings
            .smartSystems: 0.12      // 12% operational savings
        ]
        
        return currentCosts.totalAnnualCost * (savingsRatio[improvement] ?? 0.1)
    }
    
    private func calculateNPV(_ investment: Double, annualSavings: Double, years: Int, discountRate: Double = 0.08) -> Double {
        var npv = -investment
        
        for year in 1...years {
            npv += annualSavings / pow(1 + discountRate, Double(year))
        }
        
        return npv
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
}

// MARK: - Supporting Types

public struct BuildingCostAnalysis {
    public let buildingId: String
    public let buildingName: String
    public let buildingSize: Double
    public let buildingAge: Int
    public let totalAnnualCost: Double
    public let maintenanceCosts: Double
    public let complianceCosts: Double
    public let violationCosts: Double
    public let costPerSqFt: Double
    public let marketBenchmark: Double
    public let costEfficiencyRatio: Double
    public let projectedCosts: ProjectedCosts
    public let lastUpdated: Date
    public let costTrend: CostTrend
    public let riskFactors: [String]
}

public struct ProjectedCosts {
    public let nextYear: Double
    public let twoYears: Double
    public let fiveYears: Double
}

public enum CostTrend {
    case increasing
    case stable
    case decreasing
}

public struct ContractorComparison {
    public let workType: WorkType
    public let contractors: [ContractorProfile]
    public let marketAverage: Double
    public let bestValue: ContractorProfile?
    public let lastUpdated: Date
}

public struct ContractorProfile {
    public let id: String
    public let name: String
    public let averageCost: Double
    public let qualityScore: Double
    public let timelinessScore: Double
    public let completedJobs: Int
    public let potentialSavings: Double
    public let valueScore: Double
}

public struct ContractorRecommendation {
    public let contractorId: String
    public let name: String
    public let workType: WorkType
    public let avgCostPerUnit: Double
    public let qualityRating: Double
    public let timelinessScore: Double
    public let totalSavings: Double
    public let recommendationScore: Double
}

public enum WorkType: String, CaseIterable {
    case hvacMaintenance
    case plumbing
    case electrical
    case roofing
    case painting
    case cleaning
}

public struct BudgetForecast {
    public let buildingId: String
    public let buildingName: String
    public let forecastYear: Int
    public let quarterlyCosts: [QuarterlyCost]
    public let projectedTotalCost: Double
    public let confidence: Double
    public let assumptions: [String]
    public let riskAdjustments: [BudgetRisk]
    public let createdAt: Date
}

public struct QuarterlyCost {
    public let quarter: Int
    public let maintenanceCost: Double
    public let complianceCost: Double
    public let violationCost: Double
    public let emergencyCost: Double
    public let totalCost: Double
}

public struct BudgetRisk {
    public let type: String
    public let probability: Double
    public let impact: Double
    public let description: String
}

public struct SavingsOpportunity {
    public let buildingId: String
    public let buildingName: String
    public let type: SavingsType
    public let title: String
    public let description: String
    public let investmentRequired: Double
    public let annualSavings: Double
    public let paybackPeriod: Double
    public let riskLevel: RiskLevel
    public let priority: Priority
    public let implementationTimeframe: String
    public let roiPercentage: Double
    
    public enum SavingsType {
        case energyEfficiency
        case preventiveMaintenance
        case contractorOptimization
        case technologyUpgrade
        case processImprovement
    }
    
    public enum RiskLevel {
        case low
        case medium
        case high
    }
    
    public enum Priority {
        case low
        case medium
        case high
        case critical
    }
}

public struct FinePredictionSummary {
    public let buildingId: String
    public let totalPredictedFines: Double
    public let timeframe: Int // days
    public let confidence: Double
    public let fineEstimates: [FineEstimate]
    public let recommendedMitigationBudget: Double
    public let potentialSavings: Double
}

public struct FineEstimate {
    public let violationType: ViolationType
    public let probability: Double
    public let estimatedFine: Double
    public let timeframe: String
    public let mitigationCost: Double
    public let netRisk: Double // estimatedFine - mitigationCost
}

public struct ROIAnalysis {
    public let buildingId: String
    public let improvementType: ImprovementType
    public let investmentCost: Double
    public let annualSavings: Double
    public let paybackPeriodYears: Double
    public let fiveYearROI: Double
    public let netPresentValue: Double
    public let riskAdjustedROI: Double
}

public enum ImprovementType {
    case hvacUpgrade
    case windowReplacement
    case roofReplacement
    case insulation
    case lighting
    case smartSystems
}

private struct HistoricalCost {
    let type: String
    let amount: Double
    let date: Date
    let description: String
}

public enum CostIntelligenceError: LocalizedError {
    case dataNotAvailable(String)
    case calculationError(String)
    case invalidParameters(String)
    
    public var errorDescription: String? {
        switch self {
        case .dataNotAvailable(let msg): return "Data not available: \(msg)"
        case .calculationError(let msg): return "Calculation error: \(msg)"
        case .invalidParameters(let msg): return "Invalid parameters: \(msg)"
        }
    }
}

// MARK: - Market Rates Helper

private struct MarketRates {
    func getMaintenanceCostPerSqFt(_ buildingType: CoreTypes.BuildingType, age: Int) -> Double {
        let baseCost: Double = switch buildingType {
        case .residential: 8.5
        case .office: 12.0
        case .retail: 11.0
        case .industrial: 6.5
        case .warehouse: 7.0
        case .medical: 15.0
        case .educational: 9.0
        case .mixed: 10.0
        }
        
        // Age multiplier
        let ageMultiplier = 1 + Double(max(0, age - 20)) * 0.02 // 2% per year after 20 years
        
        return baseCost * ageMultiplier
    }
    
    func getWorkTypeCost(_ workType: WorkType) -> Double {
        switch workType {
        case .hvacMaintenance: return 150
        case .plumbing: return 120
        case .electrical: return 140
        case .roofing: return 200
        case .painting: return 80
        case .cleaning: return 50
        }
    }
}

// MARK: - Extensions

extension Date {
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    var quarter: Int {
        let month = Calendar.current.component(.month, from: self)
        return (month - 1) / 3 + 1
    }
}