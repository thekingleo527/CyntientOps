//
//  ClientMainMenuView.swift
//  CyntientOps v6.0
//
//  ✅ REFACTORED: Aligned with CoreTypes
//  ✅ FIXED: Renamed conflicting declarations
//  ✅ NAMESPACED: Prefixed components to avoid conflicts
//  ✅ INTEGRATED: Works with ClientDashboard architecture
//

import SwiftUI
import MapKit

// MARK: - Client Main Menu View (Renamed to avoid conflict)

public struct ClientMainMenuViewV6: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var contextEngine: ClientContextEngine
    
    public var body: some View {
        NavigationView {
            List {
                // Portfolio Section
                Section("Portfolio") {
                    ClientMenuRow(
                        icon: "building.2",
                        title: "Buildings",
                        subtitle: "\(contextEngine.clientBuildings.count) properties",
                        color: CyntientOpsDesign.DashboardColors.clientPrimary
                    )
                    
                    ClientMenuRow(
                        icon: "chart.pie",
                        title: "Analytics",
                        subtitle: "Performance insights",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                    
                    ClientMenuRow(
                        icon: "doc.text",
                        title: "Reports",
                        subtitle: "Monthly summaries",
                        color: CyntientOpsDesign.DashboardColors.clientSecondary
                    )
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
                
                // Compliance Section
                Section("Compliance") {
                    ClientMenuRow(
                        icon: "checkmark.shield",
                        title: "Compliance Dashboard",
                        subtitle: "\(Int(contextEngine.complianceOverview.overallScore * 100))% compliant",
                        color: contextEngine.complianceOverview.overallScore > 0.9 ?
                            CyntientOpsDesign.DashboardColors.compliant :
                            CyntientOpsDesign.DashboardColors.warning
                    )
                    
                    ClientMenuRow(
                        icon: "doc.badge.clock",
                        title: "Audit History",
                        subtitle: "Past inspections",
                        color: CyntientOpsDesign.DashboardColors.clientAccent
                    )
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
                
                // Communication Section
                Section("Communication") {
                    ClientMenuRow(
                        icon: "message",
                        title: "Messages",
                        subtitle: "Team communication",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                    
                    ClientMenuRow(
                        icon: "bell",
                        title: "Notifications",
                        subtitle: contextEngine.realtimeAlerts.isEmpty ?
                            "No new alerts" : "\(contextEngine.realtimeAlerts.count) new",
                        color: contextEngine.criticalAlerts.isEmpty ?
                            CyntientOpsDesign.DashboardColors.inactive :
                            CyntientOpsDesign.DashboardColors.warning
                    )
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
                
                // Support Section
                Section("Support") {
                    ClientMenuRow(
                        icon: "questionmark.circle",
                        title: "Help Center",
                        subtitle: "FAQs and guides",
                        color: CyntientOpsDesign.DashboardColors.tertiaryText
                    )
                    
                    ClientMenuRow(
                        icon: "gear",
                        title: "Settings",
                        subtitle: "Account preferences",
                        color: CyntientOpsDesign.DashboardColors.tertiaryText
                    )
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Client Buildings List View

public struct ClientBuildingsListView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let performanceMap: [String: Double]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .performance
    @State private var filterOption: FilterOption = .all
    
    public enum SortOption: String, CaseIterable {
        case name = "Name"
        case performance = "Performance"
        case location = "Location"
    }
    
    public enum FilterOption: String, CaseIterable {
        case all = "All"
        case highPerformance = "High Performance"
        case needsAttention = "Needs Attention"
        case critical = "Critical"
    }
    
    private var filteredBuildings: [CoreTypes.NamedCoordinate] {
        let filtered = buildings.filter { building in
            searchText.isEmpty || building.name.localizedCaseInsensitiveContains(searchText)
        }.filter { building in
            switch filterOption {
            case .all:
                return true
            case .highPerformance:
                return (performanceMap[building.id] ?? 0) >= 0.8
            case .needsAttention:
                let performance = performanceMap[building.id] ?? 0
                return performance < 0.8 && performance >= 0.6
            case .critical:
                return (performanceMap[building.id] ?? 0) < 0.6
            }
        }
        
        return filtered.sorted { building1, building2 in
            switch sortOption {
            case .name:
                return building1.name < building2.name
            case .performance:
                let perf1 = performanceMap[building1.id] ?? 0
                let perf2 = performanceMap[building2.id] ?? 0
                return perf1 > perf2
            case .location:
                return building1.address < building2.address
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    TextField("Search buildings...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            ClientFilterChip(
                                title: option.rawValue,
                                isSelected: filterOption == option,
                                color: chipColor(for: option),
                                action: { filterOption = option }
                            )
                        }
                        
                        Spacer()
                        
                        // Sort menu
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortOption = option }) {
                                    Label(
                                        option.rawValue,
                                        systemImage: sortOption == option ? "checkmark" : ""
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                                Text("Sort")
                                    .font(.caption)
                            }
                            .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding()
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
            
            // Buildings list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredBuildings, id: \.id) { building in
                        ClientBuildingListRow(
                            building: building,
                            performance: performanceMap[building.id] ?? 0,
                            onTap: { onSelectBuilding(building) }
                        )
                    }
                }
                .padding()
            }
            
            // Summary footer
            HStack {
                Text("\(filteredBuildings.count) of \(buildings.count) buildings")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                Spacer()
                
                if let avgPerformance = averagePerformance {
                    Text("Avg: \(Int(avgPerformance * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(performanceColor(for: avgPerformance))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }
    
    private var averagePerformance: Double? {
        let performances = filteredBuildings.compactMap { performanceMap[$0.id] }
        guard !performances.isEmpty else { return nil }
        return performances.reduce(0, +) / Double(performances.count)
    }
    
    private func chipColor(for option: FilterOption) -> Color {
        switch option {
        case .all:
            return CyntientOpsDesign.DashboardColors.clientPrimary
        case .highPerformance:
            return CyntientOpsDesign.DashboardColors.success
        case .needsAttention:
            return CyntientOpsDesign.DashboardColors.warning
        case .critical:
            return CyntientOpsDesign.DashboardColors.critical
        }
    }
    
    private func performanceColor(for value: Double) -> Color {
        if value >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if value >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        } else {
            return CyntientOpsDesign.DashboardColors.critical
        }
    }
}

// MARK: - Client Compliance Overview (renamed from ClientComplianceDetailView)

public struct ClientComplianceOverview: View {
    let complianceOverview: CoreTypes.ComplianceOverview
    let issues: [CoreTypes.ComplianceIssue]
    let selectedIssue: CoreTypes.ComplianceIssue?
    
    @State private var selectedSeverity: CoreTypes.ComplianceSeverity?
    @State private var selectedStatus: CoreTypes.ComplianceStatus?
    @State private var showingIssueDetail = false
    @State private var detailIssue: CoreTypes.ComplianceIssue?
    
    private var filteredIssues: [CoreTypes.ComplianceIssue] {
        issues.filter { issue in
            (selectedSeverity == nil || issue.severity == selectedSeverity) &&
            (selectedStatus == nil || issue.status == selectedStatus)
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Compliance Score Card
                ClientComplianceScoreCard(overview: complianceOverview)
                
                // Quick Stats
                HStack(spacing: 12) {
                    ClientQuickStatCard(
                        title: "Open Issues",
                        value: "\(filteredIssues.filter { $0.status == .open }.count)",
                        icon: "exclamationmark.circle",
                        color: CyntientOpsDesign.DashboardColors.warning
                    )
                    
                    ClientQuickStatCard(
                        title: "Critical",
                        value: "\(complianceOverview.criticalViolations)",
                        icon: "exclamationmark.triangle.fill",
                        color: CyntientOpsDesign.DashboardColors.critical
                    )
                    
                    ClientQuickStatCard(
                        title: "Pending",
                        value: "\(complianceOverview.pendingInspections)",
                        icon: "calendar",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                }
                
                // Filters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter Issues")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    // Severity filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ClientFilterChip(
                                title: "All Severities",
                                isSelected: selectedSeverity == nil,
                                action: { selectedSeverity = nil }
                            )
                            
                            ForEach(CoreTypes.ComplianceSeverity.allCases, id: \.self) { severity in
                                ClientFilterChip(
                                    title: severity.rawValue,
                                    isSelected: selectedSeverity == severity,
                                    color: severityColor(severity),
                                    action: { selectedSeverity = severity }
                                )
                            }
                        }
                    }
                    
                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ClientFilterChip(
                                title: "All Statuses",
                                isSelected: selectedStatus == nil,
                                action: { selectedStatus = nil }
                            )
                            
                            ForEach([CoreTypes.ComplianceStatus.open, .inProgress, .resolved], id: \.self) { status in
                                ClientFilterChip(
                                    title: status.rawValue,
                                    isSelected: selectedStatus == status,
                                    color: statusColor(status),
                                    action: { selectedStatus = status }
                                )
                            }
                        }
                    }
                }
                
                // Issues List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Issues (\(filteredIssues.count))")
                            .font(.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                        }
                    }
                    
                    ForEach(filteredIssues) { issue in
                        ClientComplianceIssueCard(issue: issue) {
                            detailIssue = issue
                            showingIssueDetail = true
                        }
                    }
                }
            }
            .padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .sheet(isPresented: $showingIssueDetail) {
            if let issue = detailIssue {
                ClientComplianceIssueDetailSheet(issue: issue)
            }
        }
        .onAppear {
            if let selected = selectedIssue {
                detailIssue = selected
                showingIssueDetail = true
            }
        }
    }
    
    private func severityColor(_ severity: CoreTypes.ComplianceSeverity) -> Color {
        switch severity {
        case .low: return CyntientOpsDesign.DashboardColors.info
        case .medium: return CyntientOpsDesign.DashboardColors.warning
        case .high: return CyntientOpsDesign.DashboardColors.critical
        case .critical: return CyntientOpsDesign.DashboardColors.violation
        }
    }
    
    private func statusColor(_ status: CoreTypes.ComplianceStatus) -> Color {
        switch status {
        case .open: return CyntientOpsDesign.DashboardColors.warning
        case .inProgress: return CyntientOpsDesign.DashboardColors.info
        case .resolved: return CyntientOpsDesign.DashboardColors.success
        default: return CyntientOpsDesign.DashboardColors.inactive
        }
    }
}

// MARK: - Supporting Components (All Prefixed)

struct ClientMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .padding(.vertical, 4)
    }
}

struct ClientFilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = CyntientOpsDesign.DashboardColors.clientPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClientBuildingListRow: View {
    let building: CoreTypes.NamedCoordinate
    let performance: Double
    let onTap: () -> Void
    
    private var performanceColor: Color {
        if performance >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if performance >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        } else {
            return CyntientOpsDesign.DashboardColors.critical
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Building icon with performance indicator
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.1))
                        )
                    
                    Circle()
                        .fill(performanceColor)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(CyntientOpsDesign.DashboardColors.cardBackground, lineWidth: 2)
                        )
                }
                
                // Building details
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(1)
                    
                    // Performance bar
                    HStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(performanceColor)
                                    .frame(width: geometry.size.width * performance)
                            }
                        }
                        .frame(width: 60, height: 4)
                        
                        Text("\(Int(performance * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(performanceColor)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CyntientOpsDesign.DashboardColors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClientComplianceScoreCard: View {
    let overview: CoreTypes.ComplianceOverview
    
    private var scoreColor: Color {
        if overview.overallScore >= 0.9 {
            return CyntientOpsDesign.DashboardColors.compliant
        } else if overview.overallScore >= 0.7 {
            return CyntientOpsDesign.DashboardColors.warning
        } else {
            return CyntientOpsDesign.DashboardColors.violation
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Score display
            VStack(spacing: 8) {
                Text("Overall Compliance Score")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("\(Int(overview.overallScore * 100))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                
                // Visual indicator
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [scoreColor, scoreColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 300 * overview.overallScore, height: 12)
                }
                .frame(width: 300)
            }
            
            // Last updated info
            HStack {
                Label(
                    "Updated: \(overview.lastUpdated.formatted(.dateTime.day().month()))",
                    systemImage: "checkmark.seal"
                )
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .francoDarkCardBackground()
    }
}

struct ClientQuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ClientComplianceIssueCard: View {
    let issue: CoreTypes.ComplianceIssue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    // Severity indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(severityColor)
                            .frame(width: 8, height: 8)
                        
                        Text(issue.severity.rawValue.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(severityColor)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(issue.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.2))
                        )
                        .foregroundColor(statusColor)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(2)
                    
                    Text(issue.description)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(2)
                }
                
                // Metadata
                HStack(spacing: 16) {
                    if let buildingName = issue.buildingName {
                        Label(buildingName, systemImage: "building.2")
                            .font(.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                    }
                    
                    if let dueDate = issue.dueDate {
                        Label(dueDate.formatted(.dateTime.day().month()), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(Date() > dueDate ?
                                CyntientOpsDesign.DashboardColors.critical :
                                CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .low: return CyntientOpsDesign.DashboardColors.info
        case .medium: return CyntientOpsDesign.DashboardColors.warning
        case .high: return CyntientOpsDesign.DashboardColors.critical
        case .critical: return CyntientOpsDesign.DashboardColors.violation
        }
    }
    
    private var statusColor: Color {
        switch issue.status {
        case .open: return CyntientOpsDesign.DashboardColors.warning
        case .inProgress: return CyntientOpsDesign.DashboardColors.info
        case .resolved: return CyntientOpsDesign.DashboardColors.success
        default: return CyntientOpsDesign.DashboardColors.inactive
        }
    }
}

struct ClientComplianceIssueDetailSheet: View {
    let issue: CoreTypes.ComplianceIssue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Issue header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(issue.severity.rawValue.uppercased(), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(severityColor)
                            
                            Spacer()
                            
                            Text(issue.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(statusColor)
                                )
                                .foregroundColor(.white)
                        }
                        
                        Text(issue.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        Text(issue.description)
                            .font(.body)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    .padding()
                    .francoDarkCardBackground()
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 16) {
                        ClientDetailRow(label: "Building", value: issue.buildingName ?? "Not specified", icon: "building.2")
                        ClientDetailRow(label: "Type", value: issue.type.rawValue, icon: "tag")
                        ClientDetailRow(label: "Reported", value: issue.reportedDate.formatted(.dateTime.day().month().year()), icon: "calendar")
                        
                        if let dueDate = issue.dueDate {
                            ClientDetailRow(
                                label: "Due Date",
                                value: dueDate.formatted(.dateTime.day().month().year()),
                                icon: "clock",
                                color: Date() > dueDate ? CyntientOpsDesign.DashboardColors.critical : nil
                            )
                        }
                        
                        if let assignedTo = issue.assignedTo {
                            ClientDetailRow(label: "Assigned To", value: assignedTo, icon: "person")
                        }
                    }
                    .padding()
                    .francoDarkCardBackground()
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            Label("Contact Property Manager", systemImage: "phone")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(style: .primary))
                        
                        Button(action: {}) {
                            Label("View Documentation", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(style: .secondary))
                    }
                    .padding()
                }
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .low: return CyntientOpsDesign.DashboardColors.info
        case .medium: return CyntientOpsDesign.DashboardColors.warning
        case .high: return CyntientOpsDesign.DashboardColors.critical
        case .critical: return CyntientOpsDesign.DashboardColors.violation
        }
    }
    
    private var statusColor: Color {
        switch issue.status {
        case .open: return CyntientOpsDesign.DashboardColors.warning
        case .inProgress: return CyntientOpsDesign.DashboardColors.info
        case .resolved: return CyntientOpsDesign.DashboardColors.success
        default: return CyntientOpsDesign.DashboardColors.inactive
        }
    }
}

struct ClientDetailRow: View {
    let label: String
    let value: String
    let icon: String
    var color: Color?
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color ?? CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
}

// Additional helper views (Renamed to avoid conflicts)
struct ClientProfileViewPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Client Profile View")
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ClientBuildingDetailViewPlaceholder: View {
    let building: CoreTypes.NamedCoordinate
    
    var body: some View {
        Text("Building Detail: \(building.name)")
    }
}

// MARK: - Preview Provider

struct ClientMainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ClientMainMenuViewV6()
                .preferredColorScheme(.dark)
                .previewDisplayName("Main Menu")
            
            ClientBuildingsListView(
                buildings: [
                    CoreTypes.NamedCoordinate(
                        id: "1",
                        name: "123 Main Street",
                        address: "123 Main St, New York, NY",
                        latitude: 40.7128,
                        longitude: -74.0060
                    ),
                    CoreTypes.NamedCoordinate(
                        id: "2",
                        name: "456 Park Avenue",
                        address: "456 Park Ave, New York, NY",
                        latitude: 40.7589,
                        longitude: -73.9851
                    )
                ],
                performanceMap: [
                    "1": 0.85,
                    "2": 0.65
                ],
                onSelectBuilding: { _ in }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Buildings List")
            
            ClientComplianceOverview(
                complianceOverview: CoreTypes.ComplianceOverview(
                    overallScore: 0.85,
                    criticalViolations: 2,
                    pendingInspections: 3
                ),
                issues: CoreTypes.ComplianceIssue.previewSet,
                selectedIssue: nil
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Compliance Overview")
        }
    }
}
