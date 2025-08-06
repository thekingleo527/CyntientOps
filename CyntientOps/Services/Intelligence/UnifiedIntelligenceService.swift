//
//  UnifiedIntelligenceService.swift
//  CyntientOps (formerly CyntientOps) v6.0
//
//  🧠 PHASE 3: UNIFIED INTELLIGENCE SYSTEM
//  ✅ MERGED: NovaIntelligenceEngine + IntelligenceService + NovaFeatureManager
//  ✅ CONSOLIDATED: Single source of truth for all AI operations
//  ✅ NOVA INTEGRATED: Connected to NovaAIManager for persistent state
//  ✅ ROLE-BASED: Insights filtered by user role (Worker/Admin/Client)
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - Unified Intelligence Service

@MainActor
public final class UnifiedIntelligenceService: ObservableObject {
    
    // MARK: - Published Properties (Merged from all services)
    
    // Core Intelligence State
    @Published public var insights: [CoreTypes.IntelligenceInsight] = []
    @Published public var scenarios: [CoreTypes.AIScenario] = []
    @Published public var processingState: ProcessingState = .idle
    @Published public var suggestions: [CoreTypes.AISuggestion] = []
    @Published public var lastError: Error?
    
    // Navigation & UI Features (from NovaFeatureManager)
    @Published public var navigationSuggestions: [NavigationSuggestion] = []
    @Published public var availableFeatures: [NovaAIFeature] = []
    @Published public var activeInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var currentContext: String = ""
    @Published public var isProcessing = false
    @Published public var errorMessage: String?
    
    // Context & Scenario Management
    @Published public var timeOfDay: TimeOfDay = .morning
    @Published public var activeScenarios: [CoreTypes.AIScenario] = []
    @Published public var currentScenario: CoreTypes.AIScenario?
    @Published public var showingScenario = false
    @Published public var hasActiveScenarios = false
    
    // Emergency & Repair State
    @Published public var repairState = NovaEmergencyRepairState()
    
    // MARK: - Dependencies (Injected via ServiceContainer)
    
    private let database: GRDBManager
    private let workers: WorkerService
    private let buildings: BuildingService
    private let tasks: TaskService
    private let metrics: BuildingMetricsService
    private let compliance: ComplianceService
    
    // Nova AI Manager (singleton reference)
    private weak var novaManager: NovaAIManager?
    
    // MARK: - Processing State
    
    public enum ProcessingState: Equatable {
        case idle
        case processing
        case generating
        case analyzing
        case complete
        case error(String)
    }
    
    // MARK: - Internal Engines (Merged functionality)
    
    private let navigationEngine: NavigationEngine
    private let analyticsEngine: AnalyticsEngine
    private let featureEngine: FeatureEngine
    private let complianceEngine: ComplianceEngine
    
    // MARK: - Data Caching (from NovaIntelligenceEngine)
    
    private var portfolioCache: (data: NovaAggregatedData, timestamp: Date)?
    private var buildingCache: [String: (data: NovaAggregatedData, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Publishers & Subscriptions
    
    private let insightUpdateSubject = PassthroughSubject<[CoreTypes.IntelligenceInsight], Never>()
    public var insightUpdates: AnyPublisher<[CoreTypes.IntelligenceInsight], Never> {
        insightUpdateSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    public init(
        database: GRDBManager,
        workers: WorkerService,
        buildings: BuildingService,
        tasks: TaskService,
        metrics: BuildingMetricsService,
        compliance: ComplianceService
    ) async throws {
        
        self.database = database
        self.workers = workers
        self.buildings = buildings
        self.tasks = tasks
        self.metrics = metrics
        self.compliance = compliance
        
        // Initialize internal engines
        self.navigationEngine = NavigationEngine()
        self.analyticsEngine = AnalyticsEngine()
        self.featureEngine = FeatureEngine()
        self.complianceEngine = ComplianceEngine(compliance: compliance)
        
        // Setup initial state
        await initializeIntelligence()
        setupSubscriptions()
        setupAutoRefresh()
        updateTimeOfDay()
        
        print("🧠 UnifiedIntelligenceService: Fully initialized with merged engines")
    }
    
    // MARK: - Public API Methods
    
    /// Get role-based insights (Core functionality)
    public func getInsights(for role: CoreTypes.UserRole) -> [CoreTypes.IntelligenceInsight] {
        switch role {
        case .worker:
            return insights.filter { 
                $0.category == .operations || 
                $0.category == .weather ||
                $0.category == .safety
            }
        case .admin, .manager:
            return insights // Admin/Manager sees all
        case .client:
            return insights.filter {
                $0.category == .compliance ||
                $0.category == .cost ||
                $0.category == .performance
            }
        }
    }
    
    /// Set Nova AI Manager reference
    public func setNovaManager(_ nova: NovaAIManager) {
        self.novaManager = nova
        
        // Update Nova state when processing changes
        $processingState
            .sink { [weak nova] state in
                Task { @MainActor in
                    switch state {
                    case .processing, .generating, .analyzing:
                        nova?.novaState = .thinking
                    case .complete:
                        nova?.novaState = .active
                    case .error:
                        nova?.novaState = .error
                    case .idle:
                        nova?.novaState = .idle
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Generate portfolio insights (from IntelligenceService)
    public func generatePortfolioInsights() async throws -> [CoreTypes.IntelligenceInsight] {
        processingState = .generating
        
        var newInsights: [CoreTypes.IntelligenceInsight] = []
        
        do {
            // Get data from services
            let buildingList = try await buildings.getAllBuildings()
            let allTasks = try await tasks.getAllTasks()
            let activeWorkers = try await workers.getAllActiveWorkers()
            
            // Performance Analysis
            let completionRate = calculatePortfolioCompletionRate(tasks: allTasks)
            if completionRate < 0.85 {
                newInsights.append(CoreTypes.IntelligenceInsight(
                    title: "Portfolio Performance Below Target",
                    description: "Completion rate at \(Int(completionRate * 100))%. Target is 85%+",
                    type: .performance,
                    priority: .high
                ))
            }
            
            // Worker Utilization
            let utilizationRate = try await workers.getWorkerUtilization()
            if utilizationRate > 0.95 {
                newInsights.append(CoreTypes.IntelligenceInsight(
                    title: "High Worker Utilization",
                    description: "Workers at \(Int(utilizationRate * 100))% capacity. Consider load balancing.",
                    type: .operations,
                    priority: .medium
                ))
            }
            
            // Compliance Analysis
            // let complianceInsights = try await compliance.getComplianceInsights()
            // newInsights.append(contentsOf: complianceInsights)
            
            // Building-specific insights
            for building in buildingList {
                let buildingTasks = allTasks.filter { $0.buildingId == building.id }
                let buildingInsights = await generateBuildingInsights(building: building, tasks: buildingTasks)
                newInsights.append(contentsOf: buildingInsights)
            }
            
            // Update insights
            self.insights = newInsights
            processingState = .complete
            
            // Broadcast insights
            insightUpdateSubject.send(newInsights)
            
            return newInsights
            
        } catch {
            processingState = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// Process task completion intelligence
    public func processTaskCompletion(task: CoreTypes.ContextualTask, workerId: String) async {
        processingState = .analyzing
        
        // Generate insights based on task completion
        var completionInsights: [CoreTypes.IntelligenceInsight] = []
        
        // Check for patterns
        if task.category?.rawValue == "DSNY Compliance" {
            completionInsights.append(CoreTypes.IntelligenceInsight(
                title: "DSNY Task Completed",
                description: "Compliance task completed for \(task.building?.name ?? "building")",
                type: .compliance,
                priority: .medium
            ))
        }
        
        // Performance tracking
        if let estimated = task.estimatedDuration {
            completionInsights.append(CoreTypes.IntelligenceInsight(
                title: "Task Duration Analysis",
                description: "Task estimated duration: \(Int(estimated))min",
                type: .performance,
                priority: .low
            ))
        }
        
        // Add to insights
        insights.append(contentsOf: completionInsights)
        processingState = .idle
    }
    
    /// Get aggregated portfolio data (from NovaIntelligenceEngine)
    public func getPortfolioData() async throws -> NovaAggregatedData {
        // Check cache first
        if let cached = portfolioCache,
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.data
        }
        
        processingState = .processing
        
        do {
            let buildingList = try await buildings.getAllBuildings()
            let allTasks = try await tasks.getAllTasks()
            let activeWorkers = try await workers.getAllActiveWorkers()
            
            let aggregatedData = NovaAggregatedData(
                buildingCount: buildingList.count,
                taskCount: allTasks.count,
                workerCount: activeWorkers.count,
                completedTaskCount: allTasks.filter { $0.isCompleted }.count,
                urgentTaskCount: allTasks.filter { $0.priority == .high }.count,
                overdueTaskCount: allTasks.filter { 
                    if let dueDate = $0.dueDate {
                        return dueDate.timeIntervalSinceNow < 86400 // Next 24 hours
                    }
                    return false
                }.count,
                averageCompletionRate: calculatePortfolioCompletionRate(tasks: allTasks),
                timestamp: Date()
            )
            
            // Cache the result
            portfolioCache = (aggregatedData, Date())
            processingState = .complete
            
            return aggregatedData
            
        } catch {
            processingState = .error(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Feature Management (from NovaFeatureManager)
    
    public func updateAvailableFeatures(for workerId: String) async {
        do {
            let worker = try await workers.getWorkerProfile(for: workerId)
            let capabilities = try await workers.getWorkerCapabilities(for: workerId)
            
            var features: [NovaAIFeature] = []
            
            // Basic features for all workers
            features.append(.taskManagement)
            features.append(.clockInOut)
            
            // Capability-based features
            if capabilities.canUploadPhotos {
                features.append(.photoEvidence)
            }
            
            if capabilities.canAddEmergencyTasks {
                features.append(.emergencyTasks)
            }
            
            if capabilities.canViewMap {
                features.append(.mapNavigation)
            }
            
            // Role-based features
            if worker.role == .manager || worker.role == .admin {
                features.append(.analytics)
                features.append(.workerManagement)
            }
            
            self.availableFeatures = features
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func initializeIntelligence() async {
        // Generate initial insights
        do {
            let initialInsights = try await generatePortfolioInsights()
            self.insights = initialInsights
            
            // Initialize time-based context
            updateTimeOfDay()
            
        } catch {
            print("⚠️ Failed to initialize intelligence: \(error)")
        }
    }
    
    private func setupSubscriptions() {
        // Auto-refresh insights periodically
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task {
                try? await self?.generatePortfolioInsights()
            }
        }
    }
    
    private func setupAutoRefresh() {
        // Refresh intelligence every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshIntelligence()
            }
        }
    }
    
    private func refreshIntelligence() async {
        do {
            _ = try await generatePortfolioInsights()
        } catch {
            print("⚠️ Failed to refresh intelligence: \(error)")
        }
    }
    
    private func updateTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            timeOfDay = .morning
        case 12..<17:
            timeOfDay = .afternoon
        case 17..<22:
            timeOfDay = .evening
        default:
            timeOfDay = .night
        }
    }
    
    private func calculatePortfolioCompletionRate(tasks: [CoreTypes.ContextualTask]) -> Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedTasks = tasks.filter { $0.isCompleted }
        return Double(completedTasks.count) / Double(tasks.count)
    }
    
    private func generateBuildingInsights(building: CoreTypes.NamedCoordinate, tasks: [CoreTypes.ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let overdueTasks = tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate < Date()
            }
            return false
        }
        
        if overdueTasks.count > 3 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Building Has Overdue Tasks",
                description: "\(building.name) has \(overdueTasks.count) overdue tasks",
                type: .operations,
                priority: .high
            ))
        }
        
        return insights
    }
    
    private func calculateComplianceScore() async -> Double {
        // Calculate overall compliance score
        do {
            let complianceData = try await compliance.getComplianceOverview()
            return complianceData.overallScore
        } catch {
            return 0.0
        }
    }
    
    private func generatePerformanceMetrics() async -> [String: Double] {
        var performanceMetrics: [String: Double] = [:]
        
        do {
            let utilizationRate = try await workers.getWorkerUtilization()
            performanceMetrics["workerUtilization"] = utilizationRate
            
            let allTasks = try await tasks.getAllTasks()
            let completionRate = calculatePortfolioCompletionRate(tasks: allTasks)
            performanceMetrics["taskCompletion"] = completionRate
            
        } catch {
            print("⚠️ Failed to generate performance metrics: \(error)")
        }
        
        return performanceMetrics
    }
    
    // MARK: - Command Chain Integration (Phase 6)
    
    /// Report command chain metrics for analysis
    public func reportChainMetrics(successRate: Double, recentExecutions: Int) {
        if successRate < 0.8 {
            let insight = CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Command Chain Success Rate Low",
                description: "Recent command chain success rate is \(String(format: "%.1f", successRate * 100))% across \(recentExecutions) executions",
                type: .performance,
                priority: .high,
                actionRequired: true,
                generatedAt: Date()
            )
            
            Task { @MainActor in
                insights.append(insight)
                novaManager?.novaState = .urgent
            }
        }
    }
    
    /// Process task completion for intelligence updates
    public func processTaskCompletion(taskId: String, workerId: String) async {
        do {
            let task = try await tasks.getTask(taskId)
            let worker = try await workers.getWorker(workerId)
            
            // Generate insights about task completion
            if let buildingId = task.buildingId {
                let building = try await buildings.getBuilding(buildingId: buildingId)
                
                let insight = CoreTypes.IntelligenceInsight(
                    id: UUID().uuidString,
                    title: "Task Completed",
                    description: "\(worker.name) completed \(task.title) at \(building.name)",
                    type: .operations,
                    priority: .medium,
                    actionRequired: false,
                    generatedAt: Date()
                )
                
                insights.append(insight)
            }
            
        } catch {
            print("⚠️ Failed to process task completion: \(error)")
        }
    }
    
    /// Start monitoring a violation resolution
    public func startViolationMonitoring(_ violationId: String) async {
        let insight = CoreTypes.IntelligenceInsight(
            id: UUID().uuidString,
            title: "Violation Monitoring Started",
            description: "Now monitoring resolution progress for violation \(violationId)",
            type: .compliance,
            priority: .medium,
            actionRequired: false,
            generatedAt: Date()
        )
        
        insights.append(insight)
    }
    
    /// Start intelligence monitoring background task
    public func startIntelligenceMonitoring() async {
        while !Task.isCancelled {
            do {
                // Refresh insights every 5 minutes
                try await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
                await refreshIntelligence()
            } catch {
                print("Intelligence monitoring interrupted: \(error)")
                break
            }
        }
    }
    
    /// Check if intelligence monitoring is active
    public var isMonitoring: Bool {
        return refreshTimer?.isValid ?? false
    }
}

// MARK: - Supporting Types

public struct NavigationSuggestion: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let destination: String?
    public let priority: Priority
    
    public enum Priority: Int {
        case low = 0
        case medium = 1
        case high = 2
    }
}

public enum NovaAIFeature: String, CaseIterable {
    case taskManagement = "task_management"
    case clockInOut = "clock_in_out"
    case photoEvidence = "photo_evidence"
    case emergencyTasks = "emergency_tasks"
    case mapNavigation = "map_navigation"
    case analytics = "analytics"
    case workerManagement = "worker_management"
    
    public var displayName: String {
        switch self {
        case .taskManagement: return "Task Management"
        case .clockInOut: return "Clock In/Out"
        case .photoEvidence: return "Photo Evidence"
        case .emergencyTasks: return "Emergency Tasks"
        case .mapNavigation: return "Map Navigation"
        case .analytics: return "Analytics"
        case .workerManagement: return "Worker Management"
        }
    }
}

public enum TimeOfDay: String {
    case morning, afternoon, evening, night
}


// MARK: - Internal Engines

private class NavigationEngine {
    func generateSuggestions(for context: String) -> [NavigationSuggestion] {
        // Generate navigation suggestions based on context
        return []
    }
}

private class AnalyticsEngine {
    func analyze(data: NovaAggregatedData) -> [CoreTypes.IntelligenceInsight] {
        // Analyze data and generate insights
        return []
    }
}

private class FeatureEngine {
    func getAvailableFeatures(for role: CoreTypes.UserRole) -> [NovaAIFeature] {
        // Return available features based on role
        switch role {
        case .worker:
            return [.taskManagement, .clockInOut, .photoEvidence]
        case .manager, .admin:
            return NovaAIFeature.allCases
        case .client:
            return [.analytics]
        }
    }
}

private class ComplianceEngine {
    private let compliance: ComplianceService
    
    init(compliance: ComplianceService) {
        self.compliance = compliance
    }
    
    func generateInsights() async -> [CoreTypes.IntelligenceInsight] {
        // Generate compliance-related insights
        return []
    }
}