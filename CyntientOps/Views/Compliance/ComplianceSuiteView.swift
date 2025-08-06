//
//  ComplianceSuiteView.swift
//  CyntientOps
//
//  🛡️ PHASE 2: ADVANCED COMPLIANCE SUITE
//  Full compliance management with drilling capabilities
//

import SwiftUI

public struct ComplianceSuiteView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    @EnvironmentObject private var container: ServiceContainer
    @StateObject private var viewModel: ComplianceViewModel
    
    @State private var selectedCategory: ComplianceCategory = .all
    @State private var showingViolationDetails = false
    @State private var selectedViolation: ComplianceIssue?
    @State private var showingDeadlineAlert = false
    @State private var criticalDeadlines: [ComplianceDeadline] = []
    
    public enum ComplianceCategory: String, CaseIterable {
        case all = "All"
        case hpd = "HPD"
        case dob = "DOB"
        case fdny = "FDNY"
        case ll97 = "LL97"
        case ll11 = "LL11"
        case dep = "DEP"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet.rectangle.portrait"
            case .hpd: return "house.circle"
            case .dob: return "building.2.crop.circle"
            case .fdny: return "flame.circle"
            case .ll97: return "leaf.circle"
            case .ll11: return "checkmark.shield"
            case .dep: return "drop.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .hpd: return .orange
            case .dob: return .green
            case .fdny: return .red
            case .ll97: return .mint
            case .ll11: return .indigo
            case .dep: return .cyan
            }
        }
    }
    
    public init(buildings: [CoreTypes.NamedCoordinate], container: ServiceContainer) {
        self.buildings = buildings
        self._viewModel = StateObject(wrappedValue: ComplianceViewModel(container: container))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Overall Compliance Score
                complianceHeader
                
                // Category Filter
                categoryFilter
                
                // Critical Deadlines Alert (if any)
                if !criticalDeadlines.isEmpty {
                    criticalDeadlinesAlert
                }
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Compliance Overview Cards
                        complianceOverviewCards
                        
                        // Buildings Compliance Grid
                        buildingsComplianceGrid
                        
                        // Recent Violations
                        recentViolationsSection
                        
                        // Predictive Insights
                        predictiveInsightsSection
                    }
                    .padding()
                }
            }
            .background(CyntientOpsDesign.BackgroundColors.primary)
            .navigationTitle("Compliance Suite")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadComplianceData()
                }
            }
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showingViolationDetails) {
            if let violation = selectedViolation {
                ViolationDetailSheet(violation: violation, onDismiss: {
                    showingViolationDetails = false
                    selectedViolation = nil
                })
            }
        }
        .alert("Critical Deadlines", isPresented: $showingDeadlineAlert) {
            Button("Review", role: .destructive) {
                // Navigate to deadline management
            }
            Button("Dismiss", role: .cancel) { }
        } message: {
            Text("You have \(criticalDeadlines.count) critical compliance deadlines approaching within 30 days.")
        }
    }
    
    // MARK: - Header Components
    
    private var complianceHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Compliance Score")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        Text("\(Int(viewModel.overallComplianceScore * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        complianceScoreIndicator
                    }
                }
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 8) {
                    Button(action: { Task { await generateComplianceReport() } }) {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                    
                    Button(action: { showingDeadlineAlert = true }) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            // Progress indicators
            complianceProgressBars
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    complianceGradientColor.opacity(0.8),
                    complianceGradientColor.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var complianceScoreIndicator: some View {
        Image(systemName: complianceScoreIcon)
            .font(.title2)
            .foregroundColor(complianceScoreColor)
            .background(
                Circle()
                    .fill(complianceScoreColor.opacity(0.2))
                    .frame(width: 32, height: 32)
            )
    }
    
    private var complianceProgressBars: some View {
        HStack(spacing: 12) {
            ForEach(ComplianceCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                VStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ProgressView(value: viewModel.getCategoryScore(category))
                        .tint(category.color)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ComplianceCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Content Sections
    
    private var complianceOverviewCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ComplianceMetricCard(
                title: "Active Violations",
                value: "\(viewModel.activeViolations.count)",
                trend: viewModel.violationsTrend,
                color: .red,
                icon: "exclamationmark.triangle"
            )
            
            ComplianceMetricCard(
                title: "Pending Inspections", 
                value: "\(viewModel.pendingInspections.count)",
                trend: viewModel.inspectionsTrend,
                color: .orange,
                icon: "magnifyingglass.circle"
            )
            
            ComplianceMetricCard(
                title: "Resolved This Month",
                value: "\(viewModel.resolvedThisMonth)",
                trend: viewModel.resolutionTrend,
                color: .green,
                icon: "checkmark.circle"
            )
            
            ComplianceMetricCard(
                title: "Compliance Cost",
                value: viewModel.formattedComplianceCost,
                trend: viewModel.costTrend,
                color: .blue,
                icon: "dollarsign.circle"
            )
        }
    }
    
    private var buildingsComplianceGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Compliance Status")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(filteredBuildings, id: \.id) { building in
                    BuildingComplianceCard(
                        building: building,
                        complianceScore: viewModel.getBuildingComplianceScore(building.id),
                        criticalIssues: viewModel.getBuildingCriticalIssues(building.id),
                        onTap: { 
                            // Navigate to building detail
                        }
                    )
                }
            }
        }
    }
    
    private var recentViolationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Violations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full violations list
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.recentViolations.prefix(5), id: \.id) { violation in
                    ViolationRow(
                        violation: violation,
                        onTap: {
                            selectedViolation = violation
                            showingViolationDetails = true
                        }
                    )
                }
            }
        }
    }
    
    private var predictiveInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predictive Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.predictiveInsights, id: \.id) { insight in
                    PredictiveInsightCard(insight: insight)
                }
            }
        }
    }
    
    private var criticalDeadlinesAlert: some View {
        HStack {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Critical Deadlines")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(criticalDeadlines.count) items need attention")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button("Review") {
                showingDeadlineAlert = true
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .border(Color.orange.opacity(0.3))
    }
    
    // MARK: - Helper Methods
    
    private var filteredBuildings: [CoreTypes.NamedCoordinate] {
        switch selectedCategory {
        case .all:
            return buildings
        default:
            return buildings.filter { building in
                viewModel.getBuildingCategories(building.id).contains(selectedCategory)
            }
        }
    }
    
    private var complianceGradientColor: Color {
        let score = viewModel.overallComplianceScore
        if score >= 0.9 { return .green }
        if score >= 0.7 { return .yellow }
        return .red
    }
    
    private var complianceScoreIcon: String {
        let score = viewModel.overallComplianceScore
        if score >= 0.9 { return "checkmark.circle.fill" }
        if score >= 0.7 { return "exclamationmark.triangle.fill" }
        return "xmark.circle.fill"
    }
    
    private var complianceScoreColor: Color {
        let score = viewModel.overallComplianceScore
        if score >= 0.9 { return .green }
        if score >= 0.7 { return .orange }
        return .red
    }
    
    // MARK: - Data Loading
    
    private func loadComplianceData() async {
        await viewModel.loadComplianceData(for: buildings)
        criticalDeadlines = await viewModel.getCriticalDeadlines()
    }
    
    private func refreshData() async {
        await loadComplianceData()
    }
    
    private func generateComplianceReport() async {
        await viewModel.generateComplianceReport()
    }
}

// MARK: - Supporting Views

private struct CategoryFilterButton: View {
    let category: ComplianceSuiteView.ComplianceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? category.color : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
        }
    }
}

private struct ComplianceMetricCard: View {
    let title: String
    let value: String
    let trend: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                    .foregroundColor(trend > 0 ? .green : .red)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .francoDarkCardBackground()
    }
}

private struct BuildingComplianceCard: View {
    let building: CoreTypes.NamedCoordinate
    let complianceScore: Double
    let criticalIssues: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(building.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if criticalIssues > 0 {
                        Text("\(criticalIssues)")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                // Compliance score bar
                ProgressView(value: complianceScore)
                    .tint(complianceScore > 0.7 ? .green : .red)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("\(Int(complianceScore * 100))% Compliant")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ViolationRow: View {
    let violation: ComplianceIssue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Severity indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(severityColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(violation.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(violation.buildingName ?? "Unknown Building")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(violation.dueDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(violation.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch violation.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

private struct PredictiveInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(insight.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                Text("Confidence: \(Int(insight.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
            
            Spacer()
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// MARK: - Supporting Types

public struct ComplianceDeadline {
    let id: String
    let title: String
    let dueDate: Date
    let buildingId: String
    let category: String
    let severity: ComplianceSeverity
    let daysRemaining: Int
    
    public init(id: String, title: String, dueDate: Date, buildingId: String, category: String, severity: ComplianceSeverity) {
        self.id = id
        self.title = title  
        self.dueDate = dueDate
        self.buildingId = buildingId
        self.category = category
        self.severity = severity
        self.daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
}

public enum ComplianceSeverity {
    case critical, high, medium, low
}

// MARK: - Detail Sheet

private struct ViolationDetailSheet: View {
    let violation: ComplianceIssue
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Violation details implementation
                    Text(violation.description ?? "No description available")
                        .foregroundColor(.white)
                    
                    // Add more detail fields as needed
                }
                .padding()
            }
            .background(CyntientOpsDesign.BackgroundColors.primary)
            .navigationTitle("Violation Details")
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