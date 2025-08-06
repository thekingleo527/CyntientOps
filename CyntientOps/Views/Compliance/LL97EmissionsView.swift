//
//  LL97EmissionsView.swift
//  CyntientOps
//
//  🌿 PHASE 2: LL97 EMISSIONS COMPLIANCE
//  Comprehensive Local Law 97 emissions monitoring and reporting
//

import SwiftUI
import Charts

public struct LL97EmissionsView: View {
    @EnvironmentObject private var container: ServiceContainer
    @StateObject private var viewModel: LL97EmissionsViewModel
    
    @State private var selectedBuilding: String?
    @State private var selectedTimeframe: EmissionsTimeframe = .currentYear
    @State private var showingEmissionsDetail = false
    @State private var selectedEmissionsData: LL97EmissionsData?
    @State private var showingCompliancePlan = false
    
    public enum EmissionsTimeframe: String, CaseIterable {
        case currentYear = "Current Year"
        case lastYear = "Last Year"
        case fiveYear = "5-Year Trend"
        case projection = "2030 Projection"
        
        var period: String {
            switch self {
            case .currentYear: return "2024"
            case .lastYear: return "2023"
            case .fiveYear: return "2019-2024"
            case .projection: return "2024-2030"
            }
        }
        
        var icon: String {
            switch self {
            case .currentYear: return "calendar"
            case .lastYear: return "calendar.badge.minus"
            case .fiveYear: return "chart.line.uptrend.xyaxis"
            case .projection: return "chart.bar.xaxis"
            }
        }
    }
    
    public init(container: ServiceContainer) {
        self._viewModel = StateObject(wrappedValue: LL97EmissionsViewModel(container: container))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with emissions overview
                emissionsOverviewHeader
                
                // Filter controls
                filterControls
                
                // Main content tabs
                TabView {
                    // Overview Tab
                    emissionsOverviewTab
                        .tabItem {
                            Label("Overview", systemImage: "chart.pie")
                        }
                    
                    // Buildings Performance Tab
                    buildingsPerformanceTab
                        .tabItem {
                            Label("Buildings", systemImage: "building.2")
                        }
                    
                    // Compliance Tracking Tab
                    complianceTrackingTab
                        .tabItem {
                            Label("Compliance", systemImage: "checkmark.shield")
                        }
                    
                    // Reduction Strategies Tab
                    reductionStrategiesTab
                        .tabItem {
                            Label("Strategies", systemImage: "leaf")
                        }
                }
            }
            .background(CyntientOpsDesign.BackgroundColors.primary)
            .navigationTitle("LL97 Emissions")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadEmissionsData()
                }
            }
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showingEmissionsDetail) {
            if let emissionsData = selectedEmissionsData {
                LL97EmissionsDetailView(emissionsData: emissionsData) {
                    showingEmissionsDetail = false
                    selectedEmissionsData = nil
                }
            }
        }
        .sheet(isPresented: $showingCompliancePlan) {
            LL97CompliancePlanView(buildings: viewModel.buildings) {
                showingCompliancePlan = false
            }
        }
    }
    
    // MARK: - Header Components
    
    private var emissionsOverviewHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Emissions")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        Text(viewModel.formattedTotalEmissions)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("tCO₂e")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    emissionsComplianceIndicator
                }
                
                Spacer()
                
                // Quick actions
                VStack(spacing: 8) {
                    Button(action: { showingCompliancePlan = true }) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                    
                    Button(action: { Task { await generateEmissionsReport() } }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            // Compliance status bar
            complianceStatusBar
        }
        .padding()
        .background(emissionsGradientBackground)
    }
    
    private var emissionsComplianceIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: complianceIcon)
                .font(.caption)
                .foregroundColor(complianceColor)
            
            Text(complianceStatus)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(complianceColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(complianceColor.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var complianceStatusBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("2030 Compliance Target")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(Int((1 - viewModel.emissionsReductionProgress) * 100))% reduction needed")
                    .font(.caption)
                    .foregroundColor(viewModel.emissionsReductionProgress > 0.5 ? .green : .orange)
            }
            
            ProgressView(value: viewModel.emissionsReductionProgress)
                .tint(viewModel.emissionsReductionProgress > 0.5 ? .green : .orange)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
    
    // MARK: - Filter Controls
    
    private var filterControls: some View {
        VStack(spacing: 8) {
            // Timeframe filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(EmissionsTimeframe.allCases, id: \.self) { timeframe in
                        TimeframeFilterButton(
                            timeframe: timeframe,
                            isSelected: selectedTimeframe == timeframe,
                            action: { selectedTimeframe = timeframe }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Building filter
            if !viewModel.buildings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        BuildingEmissionsFilterButton(
                            buildingName: "All Buildings",
                            isSelected: selectedBuilding == nil,
                            emissionsValue: viewModel.totalEmissions,
                            action: { selectedBuilding = nil }
                        )
                        
                        ForEach(viewModel.buildings, id: \.id) { building in
                            BuildingEmissionsFilterButton(
                                buildingName: building.name,
                                isSelected: selectedBuilding == building.id,
                                emissionsValue: viewModel.getBuildingEmissions(building.id),
                                action: { selectedBuilding = building.id }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Tab Views
    
    private var emissionsOverviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Emissions breakdown chart
                EmissionsBreakdownChart(
                    data: viewModel.emissionsBreakdown,
                    timeframe: selectedTimeframe
                )
                
                // Building emissions ranking
                BuildingEmissionsRanking(
                    buildings: filteredBuildingEmissions,
                    onBuildingTap: { buildingData in
                        selectedEmissionsData = buildingData
                        showingEmissionsDetail = true
                    }
                )
                
                // Key metrics cards
                EmissionsMetricsGrid(
                    metrics: viewModel.keyMetrics,
                    timeframe: selectedTimeframe
                )
            }
            .padding()
        }
    }
    
    private var buildingsPerformanceTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Performance comparison chart
                BuildingPerformanceChart(
                    buildings: filteredBuildingEmissions,
                    metric: .emissionsIntensity
                )
                
                // Building cards grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(filteredBuildingEmissions, id: \.buildingId) { building in
                        BuildingEmissionsCard(
                            building: building,
                            onTap: {
                                selectedEmissionsData = building
                                showingEmissionsDetail = true
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var complianceTrackingTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Compliance timeline
                ComplianceTimelineChart(
                    milestones: viewModel.complianceMilestones,
                    currentProgress: viewModel.emissionsReductionProgress
                )
                
                // Non-compliant buildings alert
                if !viewModel.nonCompliantBuildings.isEmpty {
                    NonCompliantBuildingsAlert(
                        buildings: viewModel.nonCompliantBuildings,
                        onViewDetails: { building in
                            if let emissionsData = viewModel.emissionsData.first(where: { $0.buildingId == building.id }) {
                                selectedEmissionsData = emissionsData
                                showingEmissionsDetail = true
                            }
                        }
                    )
                }
                
                // Compliance actions
                ComplianceActionsGrid(
                    actions: viewModel.recommendedActions,
                    onActionTap: { action in
                        // Handle compliance action
                    }
                )
            }
            .padding()
        }
    }
    
    private var reductionStrategiesTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Strategy effectiveness chart
                StrategyEffectivenessChart(
                    strategies: viewModel.reductionStrategies
                )
                
                // Cost-benefit analysis
                CostBenefitAnalysisView(
                    strategies: viewModel.reductionStrategies,
                    onStrategySelect: { strategy in
                        // Handle strategy selection
                    }
                )
                
                // Implementation timeline
                ImplementationTimelineView(
                    strategies: viewModel.recommendedImplementationPlan
                )
            }
            .padding()
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredBuildingEmissions: [LL97EmissionsData] {
        var emissions = viewModel.emissionsData
        
        // Filter by selected building
        if let buildingId = selectedBuilding {
            emissions = emissions.filter { $0.buildingId == buildingId }
        }
        
        // Filter by timeframe (would normally involve date filtering)
        // For now, return all data
        
        return emissions.sorted { $0.totalEmissions > $1.totalEmissions }
    }
    
    private var emissionsGradientBackground: some View {
        LinearGradient(
            colors: [
                complianceColor.opacity(0.6),
                complianceColor.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var complianceColor: Color {
        if viewModel.emissionsReductionProgress >= 0.7 {
            return .green
        } else if viewModel.emissionsReductionProgress >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var complianceIcon: String {
        if viewModel.emissionsReductionProgress >= 0.7 {
            return "checkmark.circle.fill"
        } else if viewModel.emissionsReductionProgress >= 0.4 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var complianceStatus: String {
        if viewModel.emissionsReductionProgress >= 0.7 {
            return "On Track"
        } else if viewModel.emissionsReductionProgress >= 0.4 {
            return "At Risk"
        } else {
            return "Non-Compliant"
        }
    }
    
    // MARK: - Data Loading
    
    private func loadEmissionsData() async {
        await viewModel.loadEmissionsData()
    }
    
    private func refreshData() async {
        await viewModel.refreshEmissionsData()
    }
    
    private func generateEmissionsReport() async {
        await viewModel.generateEmissionsReport()
    }
}

// MARK: - Supporting Views

private struct TimeframeFilterButton: View {
    let timeframe: LL97EmissionsView.EmissionsTimeframe
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: timeframe.icon)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(timeframe.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(timeframe.period)
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 1)
            )
        }
    }
}

private struct BuildingEmissionsFilterButton: View {
    let buildingName: String
    let isSelected: Bool
    let emissionsValue: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(buildingName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(Int(emissionsValue)) tCO₂e")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(12)
        }
    }
}

private struct EmissionsBreakdownChart: View {
    let data: [EmissionsBreakdownData]
    let timeframe: LL97EmissionsView.EmissionsTimeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emissions Breakdown")
                .font(.headline)
                .foregroundColor(.white)
            
            // Placeholder for chart implementation
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 250)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Emissions Breakdown Chart")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(timeframe.period)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                    }
                )
                .cornerRadius(12)
        }
    }
}

private struct BuildingEmissionsRanking: View {
    let buildings: [LL97EmissionsData]
    let onBuildingTap: (LL97EmissionsData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Emissions Ranking")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(buildings.enumerated()), id: \.offset) { index, building in
                    BuildingRankingRow(
                        rank: index + 1,
                        building: building,
                        onTap: { onBuildingTap(building) }
                    )
                }
            }
        }
    }
}

private struct BuildingRankingRow: View {
    let rank: Int
    let building: LL97EmissionsData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Rank indicator
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.buildingName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(Int(building.totalEmissions)) tCO₂e • \(Int(building.emissionsIntensity)) kg/sq ft")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                ComplianceStatusIndicator(status: building.complianceStatus)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.7)
        }
    }
}

private struct ComplianceStatusIndicator: View {
    let status: LL97ComplianceStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            
            Text(status.displayName)
                .font(.caption2)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(status.color.opacity(0.2))
        .cornerRadius(8)
    }
}

private struct EmissionsMetricsGrid: View {
    let metrics: [EmissionsMetric]
    let timeframe: LL97EmissionsView.EmissionsTimeframe
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(metrics, id: \.id) { metric in
                EmissionsMetricCard(metric: metric)
            }
        }
    }
}

private struct EmissionsMetricCard: View {
    let metric: EmissionsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(metric.color)
                
                Spacer()
                
                Image(systemName: metric.trend > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                    .foregroundColor(metric.trend > 0 ? .red : .green)
            }
            
            Text(metric.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(metric.title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .francoDarkCardBackground()
    }
}

private struct BuildingEmissionsCard: View {
    let building: LL97EmissionsData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(building.buildingName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    ComplianceStatusIndicator(status: building.complianceStatus)
                }
                
                Text("\(Int(building.totalEmissions)) tCO₂e")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(Int(building.emissionsIntensity)) kg CO₂e/sq ft")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                // Progress bar for 2030 target
                ProgressView(value: building.reductionProgress)
                    .tint(building.reductionProgress > 0.5 ? .green : .orange)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chart Views (Placeholders)

private struct BuildingPerformanceChart: View {
    let buildings: [LL97EmissionsData]
    let metric: PerformanceMetric
    
    enum PerformanceMetric {
        case totalEmissions
        case emissionsIntensity
        case reductionProgress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Performance Comparison")
                .font(.headline)
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Text("Performance Chart Implementation")
                        .foregroundColor(.white.opacity(0.5))
                )
                .cornerRadius(12)
        }
    }
}

private struct ComplianceTimelineChart: View {
    let milestones: [ComplianceMilestone]
    let currentProgress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LL97 Compliance Timeline")
                .font(.headline)
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 150)
                .overlay(
                    Text("Compliance Timeline Chart")
                        .foregroundColor(.white.opacity(0.5))
                )
                .cornerRadius(12)
        }
    }
}

private struct NonCompliantBuildingsAlert: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onViewDetails: (CoreTypes.NamedCoordinate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Non-Compliant Buildings")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("\(buildings.count) buildings are not meeting LL97 requirements")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            LazyVStack(spacing: 8) {
                ForEach(buildings, id: \.id) { building in
                    Button(action: { onViewDetails(building) }) {
                        HStack {
                            Text(building.name)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct ComplianceActionsGrid: View {
    let actions: [ComplianceAction]
    let onActionTap: (ComplianceAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(actions, id: \.id) { action in
                    ComplianceActionCard(action: action) {
                        onActionTap(action)
                    }
                }
            }
        }
    }
}

private struct ComplianceActionCard: View {
    let action: ComplianceAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: action.icon)
                        .foregroundColor(action.priority.color)
                    
                    Spacer()
                    
                    Text(action.priority.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(action.priority.color.opacity(0.2))
                        .foregroundColor(action.priority.color)
                        .cornerRadius(4)
                }
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("Est. Impact: \(action.estimatedImpact)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct StrategyEffectivenessChart: View {
    let strategies: [ReductionStrategy]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy Effectiveness")
                .font(.headline)
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Text("Strategy Effectiveness Chart")
                        .foregroundColor(.white.opacity(0.5))
                )
                .cornerRadius(12)
        }
    }
}

private struct CostBenefitAnalysisView: View {
    let strategies: [ReductionStrategy]
    let onStrategySelect: (ReductionStrategy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost-Benefit Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(strategies, id: \.id) { strategy in
                    StrategyAnalysisRow(strategy: strategy) {
                        onStrategySelect(strategy)
                    }
                }
            }
        }
    }
}

private struct StrategyAnalysisRow: View {
    let strategy: ReductionStrategy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Cost: \(strategy.formattedCost) • ROI: \(strategy.formattedROI)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(strategy.emissionsReduction)) tCO₂e")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("reduction")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ImplementationTimelineView: View {
    let strategies: [ImplementationPhase]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Implementation Timeline")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(strategies, id: \.id) { phase in
                    ImplementationPhaseRow(phase: phase)
                }
            }
        }
    }
}

private struct ImplementationPhaseRow: View {
    let phase: ImplementationPhase
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(phase.timeframe)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            ProgressView(value: phase.progress)
                .tint(phase.progress > 0.5 ? .green : .orange)
                .frame(width: 60)
            
            Text("\(Int(phase.progress * 100))%")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 30)
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// MARK: - Detail Views

private struct LL97EmissionsDetailView: View {
    let emissionsData: LL97EmissionsData
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Building emissions overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text(emissionsData.buildingName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Emissions")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(Int(emissionsData.totalEmissions)) tCO₂e")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Intensity")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(Int(emissionsData.emissionsIntensity)) kg/sq ft")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        ComplianceStatusIndicator(status: emissionsData.complianceStatus)
                    }
                    .padding()
                    .francoDarkCardBackground()
                    
                    // Additional detail sections would go here
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Text("Detailed Emissions Analysis")
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(CyntientOpsDesign.BackgroundColors.primary)
            .navigationTitle("Emissions Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

private struct LL97CompliancePlanView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("LL97 Compliance Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Text("Compliance Plan Content")
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(CyntientOpsDesign.BackgroundColors.primary)
            .navigationTitle("Compliance Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

public struct LL97EmissionsData {
    let id: String
    let buildingId: String
    let buildingName: String
    let totalEmissions: Double
    let emissionsIntensity: Double // kg CO2e per sq ft
    let reductionProgress: Double // Progress toward 2030 target
    let complianceStatus: LL97ComplianceStatus
    let yearOverYearChange: Double
    
    public init(id: String, buildingId: String, buildingName: String, totalEmissions: Double, emissionsIntensity: Double, reductionProgress: Double, complianceStatus: LL97ComplianceStatus, yearOverYearChange: Double) {
        self.id = id
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.totalEmissions = totalEmissions
        self.emissionsIntensity = emissionsIntensity
        self.reductionProgress = reductionProgress
        self.complianceStatus = complianceStatus
        self.yearOverYearChange = yearOverYearChange
    }
}

public enum LL97ComplianceStatus {
    case compliant
    case onTrack
    case atRisk
    case nonCompliant
    
    var color: Color {
        switch self {
        case .compliant: return .green
        case .onTrack: return .blue
        case .atRisk: return .orange
        case .nonCompliant: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .compliant: return "Compliant"
        case .onTrack: return "On Track"
        case .atRisk: return "At Risk"
        case .nonCompliant: return "Non-Compliant"
        }
    }
}

public struct EmissionsBreakdownData {
    let source: String // "Electricity", "Natural Gas", "Fuel Oil", etc.
    let emissions: Double
    let percentage: Double
    let color: Color
}

public struct EmissionsMetric {
    let id: String
    let title: String
    let value: String
    let trend: Double
    let color: Color
    let icon: String
}

public struct ComplianceMilestone {
    let id: String
    let date: Date
    let title: String
    let description: String
    let isCompleted: Bool
}

public struct ComplianceAction {
    let id: String
    let title: String
    let description: String
    let priority: ActionPriority
    let estimatedImpact: String
    let icon: String
    
    enum ActionPriority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
        
        var displayName: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }
}

public struct ReductionStrategy {
    let id: String
    let name: String
    let description: String
    let cost: Double
    let emissionsReduction: Double
    let roi: Double
    let implementationTime: String
    
    var formattedCost: String {
        return "$\(Int(cost / 1000))K"
    }
    
    var formattedROI: String {
        return "\(Int(roi * 100))%"
    }
}

public struct ImplementationPhase {
    let id: String
    let name: String
    let timeframe: String
    let progress: Double
    let strategies: [String]
}