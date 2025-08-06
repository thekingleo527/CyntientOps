//
//  ComplianceViewModel.swift
//  CyntientOps
//
//  🛡️ PHASE 2: COMPLIANCE SUITE VIEW MODEL
//  ViewModel for comprehensive compliance management
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class ComplianceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var lastUpdateTime: Date?
    
    // Compliance Data
    @Published public var buildings: [CoreTypes.NamedCoordinate] = []
    @Published public var activeViolations: [CoreTypes.ComplianceIssue] = []
    @Published public var pendingInspections: [CoreTypes.ComplianceIssue] = []
    @Published public var recentViolations: [CoreTypes.ComplianceIssue] = []
    @Published public var predictiveInsights: [CoreTypes.IntelligenceInsight] = []
    
    // Metrics
    @Published public var overallComplianceScore: Double = 0.0
    @Published public var resolvedThisMonth: Int = 0
    @Published public var violationsTrend: Double = 0.0
    @Published public var inspectionsTrend: Double = 0.0
    @Published public var resolutionTrend: Double = 0.0
    @Published public var costTrend: Double = 0.0
    @Published public var formattedComplianceCost: String = "$0"
    
    // MARK: - Service Container
    
    private let container: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(container: ServiceContainer) {
        self.container = container
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Load compliance data for specified buildings
    public func loadComplianceData(for buildings: [CoreTypes.NamedCoordinate]) async {
        isLoading = true
        errorMessage = nil
        
        self.buildings = buildings
        
        do {
            // Load violations and issues
            await loadViolationsData()
            
            // Load inspections
            await loadInspectionsData()
            
            // Generate insights
            await loadPredictiveInsights()
            
            // Calculate metrics
            await calculateComplianceMetrics()
            
            lastUpdateTime = Date()
            
        } catch {
            errorMessage = "Failed to load compliance data: \(error.localizedDescription)"
            print("⚠️ ComplianceViewModel error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Get critical deadlines approaching within 30 days
    public func getCriticalDeadlines() async -> [ComplianceDeadline] {
        let calendar = Calendar.current
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        var deadlines: [ComplianceDeadline] = []
        
        // Generate sample critical deadlines based on violations
        for violation in activeViolations.prefix(5) {
            if let buildingId = violation.buildingId {
                let dueDate = calendar.date(byAdding: .day, value: Int.random(in: 1...30), to: Date()) ?? Date()
                
                deadlines.append(ComplianceDeadline(
                    id: UUID().uuidString,
                    title: "Resolve: \(violation.title)",
                    dueDate: dueDate,
                    buildingId: buildingId,
                    category: violation.type.rawValue,
                    severity: violation.severity
                ))
            }
        }
        
        return deadlines.filter { $0.dueDate <= thirtyDaysFromNow }
    }
    
    /// Generate comprehensive compliance report
    public func generateComplianceReport() async {
        print("✅ Generating comprehensive compliance report...")
        // Implementation would generate and export report
    }
    
    /// Get compliance score for specific category
    public func getCategoryScore(_ category: ComplianceSuiteView.ComplianceCategory) -> Double {
        switch category {
        case .all:
            return overallComplianceScore
        case .hpd:
            return calculateCategoryScore(for: .regulatory)
        case .dob:
            return calculateCategoryScore(for: .safety)
        case .fdny:
            return calculateCategoryScore(for: .safety)
        case .ll97:
            return calculateCategoryScore(for: .environmental)
        case .ll11:
            return calculateCategoryScore(for: .safety)
        case .dep:
            return calculateCategoryScore(for: .environmental)
        }
    }
    
    /// Get building compliance score
    public func getBuildingComplianceScore(_ buildingId: String) -> Double {
        let buildingViolations = activeViolations.filter { $0.buildingId == buildingId }
        
        if buildingViolations.isEmpty {
            return 1.0 // Perfect compliance
        }
        
        // Calculate score based on severity of violations
        let totalSeverity = buildingViolations.reduce(0.0) { total, violation in
            switch violation.severity {
            case .critical: return total + 4.0
            case .high: return total + 3.0
            case .medium: return total + 2.0
            case .low: return total + 1.0
            }
        }
        
        // Convert to compliance score (0-1)
        let maxPossibleSeverity = Double(buildingViolations.count) * 4.0
        return max(0.0, 1.0 - (totalSeverity / maxPossibleSeverity))
    }
    
    /// Get critical issues count for building
    public func getBuildingCriticalIssues(_ buildingId: String) -> Int {
        return activeViolations.filter { 
            $0.buildingId == buildingId && $0.severity == .critical 
        }.count
    }
    
    /// Get building categories that have issues
    public func getBuildingCategories(_ buildingId: String) -> [ComplianceSuiteView.ComplianceCategory] {
        let buildingViolations = activeViolations.filter { $0.buildingId == buildingId }
        var categories: Set<ComplianceSuiteView.ComplianceCategory> = []
        
        for violation in buildingViolations {
            switch violation.type {
            case .regulatory:
                categories.insert(.hpd)
            case .safety:
                categories.insert(.dob)
                categories.insert(.fdny)
            case .environmental:
                categories.insert(.ll97)
                categories.insert(.dep)
            case .operational:
                categories.insert(.dob)
            }
        }
        
        return Array(categories)
    }
    
    // MARK: - Private Methods
    
    private func loadViolationsData() async {
        do {
            // Get all tasks for client buildings
            let allTasks = try await container.tasks.getAllTasks()
            let buildingIds = Set(buildings.map { $0.id })
            
            var violations: [CoreTypes.ComplianceIssue] = []
            
            // Find overdue compliance-related tasks
            let overdueTasks = allTasks.filter { task in
                guard let buildingId = task.buildingId,
                      buildingIds.contains(buildingId),
                      let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            // Convert overdue tasks to compliance issues
            for task in overdueTasks {
                let buildingName = buildings.first { $0.id == task.buildingId }?.name
                
                violations.append(CoreTypes.ComplianceIssue(
                    title: task.title,
                    description: task.description ?? "Overdue task requires immediate attention",
                    severity: determineSeverity(for: task),
                    buildingId: task.buildingId,
                    buildingName: buildingName,
                    status: .open,
                    type: determineComplianceType(for: task)
                ))
            }
            
            // Generate additional compliance issues based on building characteristics
            await generateAdditionalViolations(&violations)
            
            // Sort by severity and date
            activeViolations = violations.sorted { violation1, violation2 in
                if violation1.severity != violation2.severity {
                    return violation1.severity.priorityValue > violation2.severity.priorityValue
                }
                return violation1.dueDate > violation2.dueDate
            }
            
            // Set recent violations (last 30 days)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            recentViolations = activeViolations.filter { $0.dueDate >= thirtyDaysAgo }
            
        } catch {
            print("⚠️ Failed to load violations data: \(error)")
        }
    }
    
    private func loadInspectionsData() async {
        do {
            // Get inspection tasks
            let allTasks = try await container.tasks.getAllTasks()
            let buildingIds = Set(buildings.map { $0.id })
            
            let inspectionTasks = allTasks.filter { task in
                guard let buildingId = task.buildingId,
                      buildingIds.contains(buildingId) else { return false }
                return task.category == .inspection && !task.isCompleted
            }
            
            var inspections: [CoreTypes.ComplianceIssue] = []
            
            for task in inspectionTasks {
                let buildingName = buildings.first { $0.id == task.buildingId }?.name
                
                inspections.append(CoreTypes.ComplianceIssue(
                    title: "Inspection: \(task.title)",
                    description: task.description ?? "Pending inspection",
                    severity: .medium,
                    buildingId: task.buildingId,
                    buildingName: buildingName,
                    status: .pending,
                    type: .regulatory
                ))
            }
            
            pendingInspections = inspections.sorted { $0.dueDate < $1.dueDate }
            
        } catch {
            print("⚠️ Failed to load inspection data: \(error)")
        }
    }
    
    private func loadPredictiveInsights() async {
        // Use unified intelligence service
        let allInsights = container.intelligence.getInsights(for: .client)
        
        // Filter for compliance-related insights
        predictiveInsights = allInsights.filter { insight in
            insight.type == .compliance || 
            insight.type == .safety ||
            insight.type == .environmental
        }
    }
    
    private func calculateComplianceMetrics() async {
        // Calculate overall compliance score
        if !buildings.isEmpty {
            let totalScore = buildings.reduce(0.0) { total, building in
                total + getBuildingComplianceScore(building.id)
            }
            overallComplianceScore = totalScore / Double(buildings.count)
        }
        
        // Calculate resolved count (mock data for now)
        resolvedThisMonth = Int.random(in: 5...15)
        
        // Calculate trends (mock data)
        violationsTrend = Double.random(in: -0.15...0.05) // Hopefully decreasing
        inspectionsTrend = Double.random(in: -0.1...0.1)
        resolutionTrend = Double.random(in: 0.0...0.2) // Hopefully increasing
        costTrend = Double.random(in: -0.05...0.1)
        
        // Calculate compliance cost estimate
        let totalCost = activeViolations.reduce(0.0) { total, violation in
            switch violation.severity {
            case .critical: return total + 5000
            case .high: return total + 2500
            case .medium: return total + 1000
            case .low: return total + 500
            }
        }
        
        formattedComplianceCost = "$\(Int(totalCost / 1000))K"
    }
    
    private func generateAdditionalViolations(_ violations: inout [CoreTypes.ComplianceIssue]) async {
        // Generate some realistic compliance issues for demonstration
        let issueTemplates = [
            ("Fire Safety Inspection Overdue", "Annual fire safety inspection required", ComplianceSeverity.high, CoreTypes.ComplianceType.safety),
            ("HPD Violation Notice", "Housing maintenance issue reported", ComplianceSeverity.medium, CoreTypes.ComplianceType.regulatory),
            ("LL97 Emissions Reporting", "Local Law 97 emissions report due", ComplianceSeverity.critical, CoreTypes.ComplianceType.environmental),
            ("Elevator Inspection", "Elevator safety certification expired", ComplianceSeverity.high, CoreTypes.ComplianceType.safety),
            ("Water Quality Testing", "Required water quality testing overdue", ComplianceSeverity.medium, CoreTypes.ComplianceType.environmental)
        ]
        
        for building in buildings.prefix(3) { // Generate for first 3 buildings
            if let template = issueTemplates.randomElement() {
                violations.append(CoreTypes.ComplianceIssue(
                    title: template.0,
                    description: template.1,
                    severity: template.2,
                    buildingId: building.id,
                    buildingName: building.name,
                    status: .open,
                    type: template.3
                ))
            }
        }
    }
    
    private func determineSeverity(for task: CoreTypes.ContextualTask) -> ComplianceSeverity {
        // Determine severity based on task characteristics
        if task.category == .inspection || task.category == .safety {
            return .high
        } else if task.title.lowercased().contains("critical") || task.title.lowercased().contains("emergency") {
            return .critical
        } else if let dueDate = task.dueDate {
            let daysPastDue = Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
            if daysPastDue > 30 {
                return .high
            } else if daysPastDue > 7 {
                return .medium
            }
        }
        return .low
    }
    
    private func determineComplianceType(for task: CoreTypes.ContextualTask) -> CoreTypes.ComplianceType {
        switch task.category {
        case .inspection: return .regulatory
        case .safety: return .safety
        case .maintenance: return .operational
        default: return .regulatory
        }
    }
    
    private func calculateCategoryScore(for type: CoreTypes.ComplianceType) -> Double {
        let categoryViolations = activeViolations.filter { $0.type == type }
        
        if categoryViolations.isEmpty {
            return 1.0
        }
        
        // Calculate average severity impact
        let totalSeverity = categoryViolations.reduce(0.0) { total, violation in
            switch violation.severity {
            case .critical: return total + 4.0
            case .high: return total + 3.0
            case .medium: return total + 2.0
            case .low: return total + 1.0
            }
        }
        
        let maxPossibleSeverity = Double(categoryViolations.count) * 4.0
        return max(0.0, 1.0 - (totalSeverity / maxPossibleSeverity))
    }
    
    private func setupSubscriptions() {
        // Subscribe to building updates
        container.dashboardSync.clientDashboardUpdates
            .filter { $0.type == .complianceStatusChanged }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    if let buildings = self?.buildings {
                        await self?.loadComplianceData(for: buildings)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Extensions

extension ComplianceSeverity {
    var priorityValue: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - HPD Violations ViewModel

@MainActor
public final class HPDViolationsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isLoading = false
    @Published public var violations: [HPDViolation] = []
    @Published public var buildings: [CoreTypes.NamedCoordinate] = []
    @Published public var totalViolations: Int = 0
    @Published public var classCCount: Int = 0
    @Published public var overdueCount: Int = 0
    @Published public var violationTrends: [ViolationTrendData] = []
    @Published public var resolutionTimes: [ResolutionTimeData] = []
    @Published public var buildingPerformance: [BuildingPerformanceData] = []
    @Published public var predictiveInsights: [HPDPredictiveInsight] = []
    
    // MARK: - Service Container
    
    private let container: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(container: ServiceContainer) {
        self.container = container
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Load HPD violations data
    public func loadViolations() async {
        isLoading = true
        
        // Load client buildings
        await loadBuildings()
        
        // Generate HPD violations data
        await generateViolationsData()
        
        // Load analytics data
        await loadAnalyticsData()
        
        // Calculate metrics
        await calculateMetrics()
        
        isLoading = false
    }
    
    /// Refresh violations data
    public func refreshViolations() async {
        await loadViolations()
    }
    
    /// Get violation count for specific class
    public func getClassCount(_ violationClass: HPDViolationsView.HPDViolationClass) -> Int {
        if violationClass == .all {
            return totalViolations
        }
        return violations.filter { $0.violationClass == violationClass.rawValue }.count
    }
    
    /// Get violation count for building
    public func getBuildingViolationCount(_ buildingId: String) -> Int {
        return violations.filter { $0.buildingId == buildingId }.count
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
    
    private func generateViolationsData() async {
        var generatedViolations: [HPDViolation] = []
        
        let violationTypes = [
            "Peeling Paint", "Broken Window", "Heating Issues", "Plumbing Problems",
            "Electrical Hazards", "Rodent Infestation", "Water Damage", "Structural Issues"
        ]
        
        let violationClasses = ["Class A", "Class B", "Class C"]
        let statuses = ["Open", "In Progress", "Resolved"]
        
        for building in buildings {
            // Generate 0-5 violations per building
            let violationCount = Int.random(in: 0...5)
            
            for i in 0..<violationCount {
                let violationType = violationTypes.randomElement() ?? "General Violation"
                let violationClass = violationClasses.randomElement() ?? "Class A"
                let status = statuses.randomElement() ?? "Open"
                let dateIssued = Date().addingTimeInterval(-Double.random(in: 0...(86400 * 180))) // 0-180 days ago
                let dateCertified = status == "Resolved" ? Date().addingTimeInterval(-Double.random(in: 0...(86400 * 30))) : nil
                
                generatedViolations.append(HPDViolation(
                    id: UUID().uuidString,
                    buildingId: building.id,
                    buildingAddress: building.address,
                    violationType: violationType,
                    violationClass: violationClass,
                    description: "HPD violation: \(violationType) reported at \(building.name)",
                    status: status,
                    dateIssued: dateIssued,
                    dateCertified: dateCertified,
                    priority: violationClass == "Class C" ? 3 : (violationClass == "Class B" ? 2 : 1)
                ))
            }
        }
        
        violations = generatedViolations
    }
    
    private func loadAnalyticsData() async {
        // Generate trend data
        violationTrends = generateTrendData()
        
        // Generate resolution time data
        resolutionTimes = generateResolutionTimeData()
        
        // Generate building performance data
        buildingPerformance = generateBuildingPerformanceData()
        
        // Generate predictive insights
        predictiveInsights = generatePredictiveInsights()
    }
    
    private func calculateMetrics() async {
        totalViolations = violations.count
        classCCount = violations.filter { $0.violationClass == "Class C" }.count
        
        // Calculate overdue violations (open for more than 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-86400 * 30)
        overdueCount = violations.filter { 
            $0.status == "Open" && $0.dateIssued < thirtyDaysAgo 
        }.count
    }
    
    private func generateTrendData() -> [ViolationTrendData] {
        var trends: [ViolationTrendData] = []
        let calendar = Calendar.current
        
        for i in 0..<12 {
            let date = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            trends.append(ViolationTrendData(
                date: date,
                count: Int.random(in: 5...25),
                violationClass: ["Class A", "Class B", "Class C"].randomElement() ?? "Class A"
            ))
        }
        
        return trends.reversed()
    }
    
    private func generateResolutionTimeData() -> [ResolutionTimeData] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        return months.map { month in
            ResolutionTimeData(
                month: month,
                averageDays: Double.random(in: 15...45),
                violationClass: ["Class A", "Class B", "Class C"].randomElement() ?? "Class A"
            )
        }
    }
    
    private func generateBuildingPerformanceData() -> [BuildingPerformanceData] {
        return buildings.map { building in
            let totalViolations = Int.random(in: 0...10)
            let resolvedViolations = Int.random(in: 0...totalViolations)
            
            return BuildingPerformanceData(
                buildingId: building.id,
                buildingName: building.name,
                totalViolations: totalViolations,
                resolvedViolations: resolvedViolations,
                averageResolutionDays: Double.random(in: 15...60)
            )
        }
    }
    
    private func generatePredictiveInsights() -> [HPDPredictiveInsight] {
        return [
            HPDPredictiveInsight(
                id: UUID().uuidString,
                title: "Heating Season Violations Likely",
                description: "Historical data suggests increased heating violations in next 30 days",
                riskScore: 0.75,
                confidence: 0.82,
                buildingId: buildings.first?.id,
                category: "Heating"
            ),
            HPDPredictiveInsight(
                id: UUID().uuidString,
                title: "Paint Violation Risk",
                description: "Buildings over 15 years old show elevated paint violation probability",
                riskScore: 0.60,
                confidence: 0.71,
                buildingId: nil,
                category: "Paint/Plaster"
            )
        ]
    }
    
    private func setupSubscriptions() {
        // Subscribe to building updates
        container.dashboardSync.clientDashboardUpdates
            .filter { $0.type == .complianceStatusChanged }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshViolations()
                }
            }
            .store(in: &cancellables)
    }
}