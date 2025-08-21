//
//  LL97EmissionsViewModel.swift
//  CyntientOps
//
//  🌿 PHASE 2: LL97 EMISSIONS VIEW MODEL
//  ViewModel for Local Law 97 emissions compliance management
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class LL97EmissionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var lastUpdateTime: Date?
    
    // Emissions Data
    @Published public var emissionsData: [LL97EmissionsData] = []
    @Published public var buildings: [CoreTypes.NamedCoordinate] = []
    @Published public var totalEmissions: Double = 0
    @Published public var emissionsReductionProgress: Double = 0.0
    @Published public var nonCompliantBuildings: [CoreTypes.NamedCoordinate] = []
    
    // Analytics Data
    @Published public var emissionsBreakdown: [EmissionsBreakdownData] = []
    @Published public var keyMetrics: [EmissionsMetric] = []
    @Published public var complianceMilestones: [ComplianceMilestone] = []
    @Published public var recommendedActions: [ComplianceAction] = []
    @Published public var reductionStrategies: [ReductionStrategy] = []
    @Published public var recommendedImplementationPlan: [ImplementationPhase] = []
    
    // MARK: - Service Container
    
    private let container: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    public var formattedTotalEmissions: String {
        return String(format: "%.0f", totalEmissions)
    }
    
    // MARK: - Initialization
    
    public init(container: ServiceContainer) {
        self.container = container
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Load all emissions data
    public func loadEmissionsData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load buildings
            await loadBuildings()
            
            // Generate emissions data for each building
            await generateEmissionsData()
            
            // Load analytics data
            await loadAnalyticsData()
            
            // Calculate totals and metrics
            await calculateTotalMetrics()
            
            lastUpdateTime = Date()
            
        } catch {
            errorMessage = "Failed to load emissions data: \(error.localizedDescription)"
            print("⚠️ LL97EmissionsViewModel error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh emissions data
    public func refreshEmissionsData() async {
        await loadEmissionsData()
    }
    
    /// Get emissions data for specific building
    public func getBuildingEmissions(_ buildingId: String) -> Double {
        return emissionsData.first { $0.buildingId == buildingId }?.totalEmissions ?? 0
    }
    
    /// Generate emissions report
    public func generateEmissionsReport() async {
        print("✅ Generating LL97 emissions report...")
        // Implementation would generate and export report
    }
    
    // MARK: - Private Methods
    
    private func loadBuildings() async {
        // Get client buildings if available, otherwise all buildings
        if let currentUser = container.auth.currentUser, currentUser.role == .client {
            if let clientData = try? await container.client.getClientForUser(currentUser.email) {
                let clientBuildingIds = try? await container.client.getBuildingsForClient(clientData.id)
                
                if let buildingIds = clientBuildingIds {
                    let allBuildings = container.operationalData.buildings
                    buildings = allBuildings
                        .filter { buildingIds.contains($0.id) }
                        .map { building in
                            CoreTypes.NamedCoordinate(
                                id: building.id,
                                name: building.name,
                                address: building.address,
                                latitude: building.latitude,
                                longitude: building.longitude
                            )
                        }
                }
            }
        } else {
            // Admin/Manager sees all buildings
            buildings = container.operationalData.buildings.map { building in
                CoreTypes.NamedCoordinate(
                    id: building.id,
                    name: building.name,
                    address: building.address,
                    latitude: building.latitude,
                    longitude: building.longitude
                )
            }
        }
    }
    
    private func generateEmissionsData() async {
        var emissions: [LL97EmissionsData] = []
        
        for building in buildings {
            // Generate realistic emissions data based on building characteristics
            let baseEmissions = generateBaseEmissions(for: building)
            let emissionsIntensity = generateEmissionsIntensity(for: building)
            let reductionProgress = generateReductionProgress(for: building)
            let complianceStatus = determineComplianceStatus(reductionProgress: reductionProgress, emissions: baseEmissions)
            let yearOverYearChange = Double.random(in: -15.0...5.0) // -15% to +5% change
            
            emissions.append(LL97EmissionsData(
                id: UUID().uuidString,
                buildingId: building.id,
                buildingName: building.name,
                totalEmissions: baseEmissions,
                emissionsIntensity: emissionsIntensity,
                reductionProgress: reductionProgress,
                complianceStatus: complianceStatus,
                yearOverYearChange: yearOverYearChange
            ))
        }
        
        emissionsData = emissions.sorted { $0.totalEmissions > $1.totalEmissions }
        
        // Identify non-compliant buildings
        nonCompliantBuildings = buildings.filter { building in
            emissionsData.first { $0.buildingId == building.id }?.complianceStatus == .nonCompliant
        }
    }
    
    private func generateBaseEmissions(for building: CoreTypes.NamedCoordinate) -> Double {
        // Generate realistic emissions based on building characteristics
        // This would normally come from actual utility data
        
        let buildingTypeMultiplier: Double
        if building.name.contains("Museum") || building.name.contains("Center") {
            buildingTypeMultiplier = 1.8 // Higher emissions for institutional buildings
        } else if building.name.contains("Residential") || building.name.contains("Ave") {
            buildingTypeMultiplier = 1.2 // Moderate emissions for residential
        } else {
            buildingTypeMultiplier = 1.0 // Base commercial emissions
        }
        
        // Base emissions range: 200-800 tCO2e per building
        let baseRange = Double.random(in: 200...800)
        return baseRange * buildingTypeMultiplier
    }
    
    private func generateEmissionsIntensity(for building: CoreTypes.NamedCoordinate) -> Double {
        // Generate kg CO2e per square foot
        // NYC average is around 13 kg CO2e/sq ft
        let baseIntensity = Double.random(in: 8.0...18.0)
        
        // Adjust for building age (older buildings typically higher intensity)
        if building.name.contains("Historic") || building.name.contains("Classic") {
            return baseIntensity * 1.3
        } else if building.name.contains("New") || building.name.contains("Modern") {
            return baseIntensity * 0.8
        } else {
            return baseIntensity
        }
    }
    
    private func generateReductionProgress(for building: CoreTypes.NamedCoordinate) -> Double {
        // Progress toward 40% reduction by 2030 (LL97 requirement)
        // 0.0 = no progress, 1.0 = target achieved
        
        let baseProgress = Double.random(in: 0.1...0.9)
        
        // Better buildings have higher progress
        if building.name.contains("Solar") || building.name.contains("Green") {
            return min(1.0, baseProgress * 1.4)
        } else if building.name.contains("Old") || building.name.contains("Classic") {
            return baseProgress * 0.6
        } else {
            return baseProgress
        }
    }
    
    private func determineComplianceStatus(reductionProgress: Double, emissions: Double) -> LL97ComplianceStatus {
        // Determine compliance status based on progress and current emissions
        if reductionProgress >= 0.8 {
            return .compliant
        } else if reductionProgress >= 0.5 {
            return .onTrack
        } else if reductionProgress >= 0.3 {
            return .atRisk
        } else {
            return .nonCompliant
        }
    }
    
    private func loadAnalyticsData() async {
        // Generate emissions breakdown by source
        emissionsBreakdown = [
            EmissionsBreakdownData(source: "Electricity", emissions: totalEmissions * 0.65, percentage: 65.0, color: .yellow),
            EmissionsBreakdownData(source: "Natural Gas", emissions: totalEmissions * 0.25, percentage: 25.0, color: .blue),
            EmissionsBreakdownData(source: "Fuel Oil", emissions: totalEmissions * 0.08, percentage: 8.0, color: .orange),
            EmissionsBreakdownData(source: "Steam", emissions: totalEmissions * 0.02, percentage: 2.0, color: .gray)
        ]
        
        // Generate key metrics
        keyMetrics = generateKeyMetrics()
        
        // Generate compliance milestones
        complianceMilestones = generateComplianceMilestones()
        
        // Generate recommended actions
        recommendedActions = generateRecommendedActions()
        
        // Generate reduction strategies
        reductionStrategies = generateReductionStrategies()
        
        // Generate implementation plan
        recommendedImplementationPlan = generateImplementationPlan()
    }
    
    private func calculateTotalMetrics() async {
        // Calculate total emissions
        totalEmissions = emissionsData.reduce(0) { $0 + $1.totalEmissions }
        
        // Calculate overall reduction progress
        if !emissionsData.isEmpty {
            emissionsReductionProgress = emissionsData.reduce(0) { $0 + $1.reductionProgress } / Double(emissionsData.count)
        }
    }
    
    private func generateKeyMetrics() -> [EmissionsMetric] {
        let averageIntensity = emissionsData.isEmpty ? 0 : emissionsData.reduce(0) { $0 + $1.emissionsIntensity } / Double(emissionsData.count)
        let compliantCount = emissionsData.filter { $0.complianceStatus == .compliant }.count
        let totalCost = emissionsData.reduce(0) { $0 + ($1.totalEmissions * 25) } // $25 per tCO2e estimated cost
        
        return [
            EmissionsMetric(
                id: "total_emissions",
                title: "Total Emissions",
                value: "\(Int(totalEmissions)) tCO₂e",
                trend: -0.05, // 5% reduction trend
                color: .green,
                icon: "leaf.fill"
            ),
            EmissionsMetric(
                id: "average_intensity",
                title: "Avg. Intensity",
                value: "\(Int(averageIntensity)) kg/sq ft",
                trend: -0.08, // 8% improvement
                color: .blue,
                icon: "building.2.fill"
            ),
            EmissionsMetric(
                id: "compliant_buildings",
                title: "Compliant Buildings",
                value: "\(compliantCount)",
                trend: 0.12, // 12% increase in compliance
                color: .green,
                icon: "checkmark.circle.fill"
            ),
            EmissionsMetric(
                id: "compliance_cost",
                title: "Estimated Cost",
                value: "$\(Int(totalCost / 1000))K",
                trend: -0.03, // 3% cost reduction
                color: .orange,
                icon: "dollarsign.circle.fill"
            )
        ]
    }
    
    private func generateComplianceMilestones() -> [ComplianceMilestone] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            ComplianceMilestone(
                id: "baseline_2024",
                date: calendar.date(from: DateComponents(year: 2024, month: 5, day: 1)) ?? now,
                title: "Baseline Reporting",
                description: "Submit 2024 emissions baseline to NYC",
                isCompleted: true
            ),
            ComplianceMilestone(
                id: "target_2027",
                date: calendar.date(from: DateComponents(year: 2027, month: 1, day: 1)) ?? now,
                title: "First Compliance Period",
                description: "Meet initial LL97 emissions limits",
                isCompleted: false
            ),
            ComplianceMilestone(
                id: "target_2030",
                date: calendar.date(from: DateComponents(year: 2030, month: 1, day: 1)) ?? now,
                title: "Full Compliance",
                description: "Achieve 40% emissions reduction",
                isCompleted: false
            ),
            ComplianceMilestone(
                id: "target_2035",
                date: calendar.date(from: DateComponents(year: 2035, month: 1, day: 1)) ?? now,
                title: "Enhanced Targets",
                description: "Meet stricter long-term limits",
                isCompleted: false
            )
        ]
    }
    
    private func generateRecommendedActions() -> [ComplianceAction] {
        var actions: [ComplianceAction] = []
        
        // High priority actions for non-compliant buildings
        if !nonCompliantBuildings.isEmpty {
            actions.append(ComplianceAction(
                id: "energy_audit",
                title: "Energy Audits",
                description: "Conduct comprehensive energy audits for non-compliant buildings",
                priority: .high,
                estimatedImpact: "10-15% emissions reduction",
                icon: "magnifyingglass.circle"
            ))
        }
        
        // Medium priority general improvements
        actions.append(ComplianceAction(
            id: "hvac_upgrade",
            title: "HVAC Optimization",
            description: "Upgrade heating and cooling systems across portfolio",
            priority: .medium,
            estimatedImpact: "15-20% emissions reduction",
            icon: "wind"
        ))
        
        actions.append(ComplianceAction(
            id: "lighting_led",
            title: "LED Conversion",
            description: "Convert all lighting to energy-efficient LEDs",
            priority: .medium,
            estimatedImpact: "5-8% emissions reduction",
            icon: "lightbulb"
        ))
        
        // Low priority long-term improvements
        actions.append(ComplianceAction(
            id: "solar_installation",
            title: "Solar Installation",
            description: "Install solar panels on suitable rooftops",
            priority: .low,
            estimatedImpact: "20-25% emissions reduction",
            icon: "sun.max"
        ))
        
        return actions
    }
    
    private func generateReductionStrategies() -> [ReductionStrategy] {
        return [
            ReductionStrategy(
                id: "hvac_modernization",
                name: "HVAC Modernization",
                description: "Replace old HVAC systems with high-efficiency models",
                cost: 250000,
                emissionsReduction: 120,
                roi: 0.15,
                implementationTime: "6-12 months"
            ),
            ReductionStrategy(
                id: "building_envelope",
                name: "Building Envelope Improvements",
                description: "Improve insulation, windows, and air sealing",
                cost: 180000,
                emissionsReduction: 85,
                roi: 0.12,
                implementationTime: "3-6 months"
            ),
            ReductionStrategy(
                id: "renewable_energy",
                name: "Renewable Energy",
                description: "Install solar panels and purchase renewable energy",
                cost: 400000,
                emissionsReduction: 200,
                roi: 0.18,
                implementationTime: "8-15 months"
            ),
            ReductionStrategy(
                id: "smart_controls",
                name: "Smart Building Controls",
                description: "Install automated energy management systems",
                cost: 75000,
                emissionsReduction: 45,
                roi: 0.22,
                implementationTime: "2-4 months"
            )
        ]
    }
    
    private func generateImplementationPlan() -> [ImplementationPhase] {
        return [
            ImplementationPhase(
                id: "phase_1",
                name: "Immediate Actions",
                timeframe: "2024-2025",
                progress: 0.3,
                strategies: ["Energy Audits", "LED Conversion", "Smart Controls"]
            ),
            ImplementationPhase(
                id: "phase_2",
                name: "Major Upgrades",
                timeframe: "2025-2027",
                progress: 0.1,
                strategies: ["HVAC Modernization", "Building Envelope"]
            ),
            ImplementationPhase(
                id: "phase_3",
                name: "Renewable Integration",
                timeframe: "2027-2030",
                progress: 0.0,
                strategies: ["Solar Installation", "Grid Integration"]
            )
        ]
    }
    
    private func setupSubscriptions() {
        // Subscribe to building updates
        container.dashboardSync.clientDashboardUpdates
            .filter { $0.type == .buildingMetricsChanged }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshEmissionsData()
                }
            }
            .store(in: &cancellables)
    }
}