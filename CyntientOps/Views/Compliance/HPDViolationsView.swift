//
//  HPDViolationsView.swift
//  CyntientOps
//
//  🏢 PHASE 2: HPD VIOLATIONS MANAGEMENT
//  Comprehensive HPD violation tracking and resolution
//

import SwiftUI
import MapKit

public struct HPDViolationsView: View {
    @EnvironmentObject private var container: ServiceContainer
    @StateObject private var viewModel: HPDViolationsViewModel
    
    @State private var selectedBuilding: String?
    @State private var selectedClass: HPDViolationClass = .all
    @State private var showingViolationDetail = false
    @State private var selectedViolation: HPDViolation?
    @State private var showingMap = false
    
    public enum HPDViolationClass: String, CaseIterable {
        case all = "All"
        case classA = "Class A" // Non-hazardous
        case classB = "Class B" // Hazardous
        case classC = "Class C" // Immediately hazardous
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .classA: return .green
            case .classB: return .orange
            case .classC: return .red
            }
        }
        
        var description: String {
            switch self {
            case .all: return "All Violations"
            case .classA: return "Non-hazardous conditions"
            case .classB: return "Hazardous conditions"
            case .classC: return "Immediately hazardous conditions"
            }
        }
    }
    
    public init(container: ServiceContainer) {
        self._viewModel = StateObject(wrappedValue: HPDViolationsViewModel(container: container))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with violation summary
                violationSummaryHeader
                
                // Filter controls
                filterControls
                
                // Main content
                TabView {
                    // List View
                    violationListView
                        .tabItem {
                            Label("List", systemImage: "list.bullet")
                        }
                    
                    // Map View
                    violationMapView
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }
                    
                    // Analytics View
                    violationAnalyticsView
                        .tabItem {
                            Label("Analytics", systemImage: "chart.bar")
                        }
                }
            }
            .background(CyntientOpsDesign.BackgroundColors.primary)
            .navigationTitle("HPD Violations")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadViolations()
                }
            }
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showingViolationDetail) {
            if let violation = selectedViolation {
                HPDViolationDetailView(violation: violation) {
                    showingViolationDetail = false
                    selectedViolation = nil
                }
            }
        }
    }
    
    // MARK: - Header Components
    
    private var violationSummaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active HPD Violations")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(viewModel.totalViolations)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Quick stats
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Class C")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("\(viewModel.classCCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(viewModel.overdueCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Class breakdown
            HStack(spacing: 16) {
                ForEach([HPDViolationClass.classA, .classB, .classC], id: \.self) { violationClass in
                    VStack(spacing: 4) {
                        Text(violationClass.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(viewModel.getClassCount(violationClass))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(violationClass.color)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.red.opacity(0.6),
                    Color.orange.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Filter Controls
    
    private var filterControls: some View {
        VStack(spacing: 8) {
            // Class filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HPDViolationClass.allCases, id: \.self) { violationClass in
                        ClassFilterButton(
                            violationClass: violationClass,
                            isSelected: selectedClass == violationClass,
                            count: viewModel.getClassCount(violationClass),
                            action: { selectedClass = violationClass }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Building filter
            if !viewModel.buildings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        BuildingFilterButton(
                            buildingName: "All Buildings",
                            isSelected: selectedBuilding == nil,
                            violationCount: viewModel.totalViolations,
                            action: { selectedBuilding = nil }
                        )
                        
                        ForEach(viewModel.buildings, id: \.id) { building in
                            BuildingFilterButton(
                                buildingName: building.name,
                                isSelected: selectedBuilding == building.id,
                                violationCount: viewModel.getBuildingViolationCount(building.id),
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
    
    // MARK: - Content Views
    
    private var violationListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredViolations, id: \.id) { violation in
                    HPDViolationCard(
                        violation: violation,
                        onTap: {
                            selectedViolation = violation
                            showingViolationDetail = true
                        }
                    )
                }
                
                if filteredViolations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No violations found")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("All buildings are compliant for the selected criteria")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding()
        }
    }
    
    private var violationMapView: some View {
        HPDViolationsMapView(
            violations: filteredViolations,
            buildings: viewModel.buildings,
            selectedViolation: $selectedViolation,
            showingDetail: $showingViolationDetail
        )
    }
    
    private var violationAnalyticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Violation trends
                ViolationTrendsChart(data: viewModel.violationTrends)
                
                // Resolution time analytics
                ResolutionTimeChart(data: viewModel.resolutionTimes)
                
                // Building performance
                BuildingPerformanceChart(data: viewModel.buildingPerformance)
                
                // Predictive insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Predictive Insights")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(viewModel.predictiveInsights, id: \.id) { insight in
                        HPDPredictiveInsightCard(insight: insight)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredViolations: [HPDViolation] {
        var violations = viewModel.violations
        
        // Filter by class
        if selectedClass != .all {
            violations = violations.filter { $0.violationClass == selectedClass.rawValue }
        }
        
        // Filter by building
        if let buildingId = selectedBuilding {
            violations = violations.filter { $0.buildingId == buildingId }
        }
        
        return violations.sorted { $0.priority > $1.priority }
    }
    
    // MARK: - Data Loading
    
    private func loadViolations() async {
        await viewModel.loadViolations()
    }
    
    private func refreshData() async {
        await viewModel.refreshViolations()
    }
}

// MARK: - Supporting Views

private struct ClassFilterButton: View {
    let violationClass: HPDViolationsView.HPDViolationClass
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(violationClass.color)
                    .frame(width: 8, height: 8)
                
                Text(violationClass.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? violationClass.color.opacity(0.3) : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? violationClass.color : Color.clear, lineWidth: 1)
            )
        }
    }
}

private struct BuildingFilterButton: View {
    let buildingName: String
    let isSelected: Bool
    let violationCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(buildingName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if violationCount > 0 {
                    Text("\(violationCount) violations")
                        .font(.caption2)
                        .opacity(0.7)
                } else {
                    Text("Compliant")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(12)
        }
    }
}

private struct HPDViolationCard: View {
    let violation: HPDViolation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(violation.violationType)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(violation.buildingAddress ?? "Unknown Address")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // Class indicator
                        Text(violation.violationClass)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(classColor(violation.violationClass))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        // Status
                        Text(violation.status)
                            .font(.caption2)
                            .foregroundColor(statusColor(violation.status))
                    }
                }
                
                // Description
                Text(violation.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                // Footer
                HStack {
                    // Date issued
                    Label(violation.dateIssued, style: .date, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    // Days since issued
                    if violation.daysSinceIssued > 0 {
                        Text("\(violation.daysSinceIssued) days ago")
                            .font(.caption2)
                            .foregroundColor(violation.daysSinceIssued > 30 ? .red : .orange)
                    }
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func classColor(_ violationClass: String) -> Color {
        switch violationClass {
        case "Class A": return .green
        case "Class B": return .orange
        case "Class C": return .red
        default: return .gray
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "open": return .red
        case "resolved": return .green
        case "in progress": return .orange
        default: return .gray
        }
    }
}

private struct HPDViolationsMapView: View {
    let violations: [HPDViolation]
    let buildings: [CoreTypes.NamedCoordinate]
    @Binding var selectedViolation: HPDViolation?
    @Binding var showingDetail: Bool
    
    var body: some View {
        Map {
            ForEach(violations, id: \.id) { violation in
                if let building = buildings.first(where: { $0.id == violation.buildingId }),
                   let coordinate = building.coordinate {
                    
                    Annotation(
                        violation.violationType,
                        coordinate: coordinate,
                        anchor: .center
                    ) {
                        Button(action: {
                            selectedViolation = violation
                            showingDetail = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(violationClassColor(violation.violationClass))
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "exclamationmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
        }
        .mapStyle(.hybrid)
    }
    
    private func violationClassColor(_ violationClass: String) -> Color {
        switch violationClass {
        case "Class A": return .green
        case "Class B": return .orange
        case "Class C": return .red
        default: return .gray
        }
    }
}

// MARK: - Chart Views (Placeholders for now)

private struct ViolationTrendsChart: View {
    let data: [ViolationTrendData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Violation Trends")
                .font(.headline)
                .foregroundColor(.white)
            
            // Placeholder for chart implementation
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Text("Chart Implementation")
                        .foregroundColor(.white.opacity(0.5))
                )
                .cornerRadius(12)
        }
    }
}

private struct ResolutionTimeChart: View {
    let data: [ResolutionTimeData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Resolution Time")
                .font(.headline)
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 150)
                .overlay(
                    Text("Resolution Time Chart")
                        .foregroundColor(.white.opacity(0.5))
                )
                .cornerRadius(12)
        }
    }
}

private struct BuildingPerformanceChart: View {
    let data: [BuildingPerformanceData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 180)
                .overlay(
                    Text("Building Performance Chart")
                        .foregroundColor(.white.opacity(0.5))
                )
                .cornerRadius(12)
        }
    }
}

private struct HPDPredictiveInsightCard: View {
    let insight: HPDPredictiveInsight
    
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
                
                HStack {
                    Text("Risk Score: \(Int(insight.riskScore * 100))%")
                        .font(.caption2)
                        .foregroundColor(insight.riskScore > 0.7 ? .red : .orange)
                    
                    Spacer()
                    
                    Text("Confidence: \(Int(insight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            
            Spacer()
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// MARK: - Detail View

private struct HPDViolationDetailView: View {
    let violation: HPDViolation
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Violation header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(violation.violationType)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(violation.buildingAddress ?? "Unknown Address")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Status and class
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Class")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(violation.violationClass)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(violation.status)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Divider()
                        .background(.white.opacity(0.3))
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(violation.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Divider()
                        .background(.white.opacity(0.3))
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timeline")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Issued:")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(violation.dateIssued, style: .date)
                                    .foregroundColor(.white)
                            }
                            
                            if let certifiedDate = violation.dateCertified {
                                HStack {
                                    Text("Certified:")
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text(certifiedDate, style: .date)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    if violation.status.lowercased() == "open" {
                        Divider()
                            .background(.white.opacity(0.3))
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button("Schedule Repair") {
                                // Schedule repair action
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            
                            Button("Contact HPD") {
                                // Contact HPD action
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
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

// MARK: - Supporting Types

public struct HPDViolation {
    let id: String
    let buildingId: String
    let buildingAddress: String?
    let violationType: String
    let violationClass: String // "Class A", "Class B", "Class C"
    let description: String
    let status: String // "Open", "Resolved", "In Progress"
    let dateIssued: Date
    let dateCertified: Date?
    let priority: Int
    
    var daysSinceIssued: Int {
        Calendar.current.dateComponents([.day], from: dateIssued, to: Date()).day ?? 0
    }
    
    public init(id: String, buildingId: String, buildingAddress: String?, violationType: String, violationClass: String, description: String, status: String, dateIssued: Date, dateCertified: Date?, priority: Int) {
        self.id = id
        self.buildingId = buildingId
        self.buildingAddress = buildingAddress
        self.violationType = violationType
        self.violationClass = violationClass
        self.description = description
        self.status = status
        self.dateIssued = dateIssued
        self.dateCertified = dateCertified
        self.priority = priority
    }
}

public struct HPDPredictiveInsight {
    let id: String
    let title: String
    let description: String
    let riskScore: Double
    let confidence: Double
    let buildingId: String?
    let category: String
    
    public init(id: String, title: String, description: String, riskScore: Double, confidence: Double, buildingId: String?, category: String) {
        self.id = id
        self.title = title
        self.description = description
        self.riskScore = riskScore
        self.confidence = confidence
        self.buildingId = buildingId
        self.category = category
    }
}

// Placeholder data types for charts
public struct ViolationTrendData {
    let date: Date
    let count: Int
    let violationClass: String
}

public struct ResolutionTimeData {
    let month: String
    let averageDays: Double
    let violationClass: String
}

public struct BuildingPerformanceData {
    let buildingId: String
    let buildingName: String
    let totalViolations: Int
    let resolvedViolations: Int
    let averageResolutionDays: Double
}