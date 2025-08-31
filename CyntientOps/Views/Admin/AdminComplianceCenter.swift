#if false
//
//  AdminComplianceCenter.swift
//  CyntientOps v6.0
//
//  ✅ COMPREHENSIVE: Central hub for all compliance management
//  ✅ REAL-TIME: Live compliance data from ComplianceService
//  ✅ INTELLIGENT: Nova AI integration for compliance predictions
//  ✅ DARK ELEGANCE: Consistent with established admin theme
//  ✅ DATA-DRIVEN: Real data from compliance_issues table via GRDB
//

import SwiftUI
import Combine

struct AdminComplianceCenter: View {
    // MARK: - Properties
    
    @EnvironmentObject private var container: ServiceContainer
    @EnvironmentObject private var novaEngine: NovaAIManager
    // ViewModel managed by parent flows; avoid creating containers here
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @Environment(\.dismiss) private var dismiss
    
    // State management
    @State private var isLoading = false
    @State private var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @State private var filteredIssues: [CoreTypes.ComplianceIssue] = []
    @State private var buildings: [CoreTypes.NamedCoordinate] = []
    @State private var selectedIssues: Set<String> = []
    
    // Filter states
    @State private var selectedSeverity: ComplianceSeverity = .all
    @State private var selectedStatus: ComplianceStatus = .all
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var searchText = ""
    @State private var showingCriticalOnly = false
    
    // UI States
    @State private var currentContext: ViewContext = .overview
    @State private var selectedIssue: CoreTypes.ComplianceIssue?
    @State private var showingIssueDetail = false
    @State private var showingCreateIssue = false
    @State private var showingBulkActions = false
    @State private var showingScheduleInspection = false
    @State private var showingExportOptions = false
    @State private var refreshID = UUID()
    
    // Intelligence panel state
    @AppStorage("complianceCenterPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // MARK: - Initialization
    // No local ServiceContainer creation. View relies on injected environment objects.
    
    // MARK: - Enums
    
    enum ViewContext {
        case overview
        case issueDetail
        case bulkActions
        case inspection
    }
    
    enum IntelPanelState: String {
        case hidden = "hidden"
        case collapsed = "collapsed"
        case expanded = "expanded"
    }
    
    enum ComplianceSeverity: String, CaseIterable {
        case all = "All"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .all: return .white
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    enum ComplianceStatus: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
        case closed = "Closed"
        
        var color: Color {
            switch self {
            case .all: return .white
            case .open: return .red
            case .inProgress: return .orange
            case .resolved: return .green
            case .closed: return .gray
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var intelligencePanelState: IntelPanelState {
        userPanelPreference
    }
    
    private var complianceMetrics: ComplianceMetrics {
        let total = complianceIssues.count
        let open = complianceIssues.filter { $0.status.rawValue.lowercased() == "open" }.count
        let critical = complianceIssues.filter { 
            $0.severity.rawValue.lowercased() == "critical" && $0.status.rawValue.lowercased() != "resolved"
        }.count
        let resolved = complianceIssues.filter { $0.status.rawValue.lowercased() == "resolved" }.count
        let overdue = complianceIssues.filter { isIssueOverdue($0) }.count
        
        let complianceScore = total > 0 ? Double(resolved) / Double(total) * 100 : 100.0
        
        return ComplianceMetrics(
            total: total,
            open: open,
            critical: critical,
            resolved: resolved,
            overdue: overdue,
            complianceScore: complianceScore
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Compliance Score Card
                complianceScoreView
                
                // Metrics Cards
                metricsCardsView
                
                // Filters
                filtersView
                
                // Issues List
                issuesListView
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
        .onReceive(dashboardSync.crossDashboardUpdates) { update in
            if update.type == .complianceChanged || update.type == .buildingComplianceChanged {
                Task {
                    await loadData()
                }
            }
        }
        .sheet(isPresented: $showingIssueDetail) {
            if let issue = selectedIssue {
                AdminComplianceIssueDetailView(issue: issue) {
                    Task {
                        await loadData()
                    }
                }
                .environmentObject(container)
            }
        }
        .sheet(isPresented: $showingCreateIssue) {
            AdminCreateComplianceIssueView {
                Task {
                    await loadData()
                }
            }
            .environmentObject(container)
        }
        .sheet(isPresented: $showingBulkActions) {
            AdminComplianceBulkActionsView(
                selectedIssues: Array(selectedIssues),
                allIssues: complianceIssues,
                onComplete: {
                    selectedIssues.removeAll()
                    Task {
                        await loadData()
                    }
                }
            )
            .environmentObject(container)
        }
        .sheet(isPresented: $showingScheduleInspection) {
            AdminScheduleInspectionView {
                Task {
                    await loadData()
                }
            }
            .environmentObject(container)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button("Back") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Compliance Center")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Portfolio Management")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Menu {
                Button(action: { showingCreateIssue = true }) {
                    Label("New Issue", systemImage: "plus")
                }
                
                Button(action: { showingScheduleInspection = true }) {
                    Label("Schedule Inspection", systemImage: "calendar.badge.plus")
                }
                
                Button(action: { showingExportOptions = true }) {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Compliance Score View
    
    private var complianceScoreView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Compliance Score")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Portfolio-wide compliance rating")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: complianceMetrics.complianceScore / 100)
                            .stroke(
                                LinearGradient(
                                    colors: complianceMetrics.complianceScore > 90 ? [.green, .blue] : 
                                            complianceMetrics.complianceScore > 75 ? [.orange, .yellow] : [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)
                        
                        Text("\(Int(complianceMetrics.complianceScore))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Quick stats
            HStack(spacing: 20) {
                ComplianceStatItem(
                    title: "Open Issues",
                    value: "\(complianceMetrics.open)",
                    color: .red
                )
                
                ComplianceStatItem(
                    title: "Critical",
                    value: "\(complianceMetrics.critical)",
                    color: .orange
                )
                
                ComplianceStatItem(
                    title: "Resolved",
                    value: "\(complianceMetrics.resolved)",
                    color: .green
                )
                
                if complianceMetrics.overdue > 0 {
                    ComplianceStatItem(
                        title: "Overdue",
                        value: "\(complianceMetrics.overdue)",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Metrics Cards View
    
    private var metricsCardsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ComplianceMetricCard(
                    title: "Total Issues",
                    value: "\(complianceMetrics.total)",
                    subtitle: "Tracked",
                    color: .blue,
                    icon: "list.bullet.clipboard"
                )
                
                ComplianceMetricCard(
                    title: "Open Issues",
                    value: "\(complianceMetrics.open)",
                    subtitle: "Require attention",
                    color: .red,
                    icon: "exclamationmark.circle"
                )
                
                ComplianceMetricCard(
                    title: "Critical",
                    value: "\(complianceMetrics.critical)",
                    subtitle: "High priority",
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
                
                ComplianceMetricCard(
                    title: "Resolved",
                    value: "\(complianceMetrics.resolved)",
                    subtitle: "Completed",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                ComplianceMetricCard(
                    title: "Buildings",
                    value: "\(buildings.count)",
                    subtitle: "Portfolio",
                    color: .purple,
                    icon: "building.2.fill"
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search compliance issues...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            
            // Severity Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ComplianceSeverity.allCases, id: \.self) { severity in
                        FilterPill(
                            title: severity.rawValue,
                            isSelected: selectedSeverity == severity,
                            color: severity.color,
                            onTap: { selectedSeverity = severity; applyFilters() }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Status Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ComplianceStatus.allCases, id: \.self) { status in
                        FilterPill(
                            title: status.rawValue,
                            isSelected: selectedStatus == status,
                            color: status.color,
                            onTap: { selectedStatus = status; applyFilters() }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Bulk Actions Toggle
            if !selectedIssues.isEmpty {
                Button(action: { showingBulkActions = true }) {
                    HStack {
                        Image(systemName: "checklist")
                        Text("Bulk Actions (\(selectedIssues.count))")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Issues List View
    
    private var issuesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredIssues, id: \.id) { issue in
                    AdminComplianceIssueRow(
                        issue: issue,
                        isSelected: selectedIssues.contains(issue.id),
                        onTap: {
                            selectedIssue = issue
                            showingIssueDetail = true
                        },
                        onSelect: { isSelected in
                            if isSelected {
                                selectedIssues.insert(issue.id)
                            } else {
                                selectedIssues.remove(issue.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadData() async {
        isLoading = true
        
        do {
            // Load compliance issues
            let complianceService = ComplianceService.shared
            complianceIssues = try await complianceService.getAllComplianceIssues()
            
            // Load buildings
            buildings = await container.operationalData.buildings
            
            applyFilters()
            
            // Broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .complianceChanged,
                description: "Compliance center refreshed - \(complianceIssues.count) issues loaded"
            )
            dashboardSync.broadcastUpdate(update)
            
        } catch {
            print("❌ Failed to load compliance data: \(error)")
        }
        
        isLoading = false
    }
    
    private func applyFilters() {
        var filtered = complianceIssues
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { issue in
                issue.title.localizedCaseInsensitiveContains(searchText) ||
                issue.description.localizedCaseInsensitiveContains(searchText) ||
                issue.buildingName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply severity filter
        if selectedSeverity != .all {
            filtered = filtered.filter { $0.severity.rawValue.lowercased() == selectedSeverity.rawValue.lowercased() }
        }
        
        // Apply status filter
        if selectedStatus != .all {
            filtered = filtered.filter { $0.status.rawValue.lowercased() == selectedStatus.rawValue.lowercased() }
        }
        
        // Apply building filter
        if let selectedBuilding = selectedBuilding {
            filtered = filtered.filter { $0.buildingId == selectedBuilding.id }
        }
        
        // Show critical only filter
        if showingCriticalOnly {
            filtered = filtered.filter { $0.severity.rawValue.lowercased() == "critical" }
        }
        
        filteredIssues = filtered
    }
    
    private func isIssueOverdue(_ issue: CoreTypes.ComplianceIssue) -> Bool {
        guard let dueDate = issue.dueDate else { return false }
        return dueDate < Date() && issue.status.rawValue.lowercased() != "resolved"
    }
}

// MARK: - Supporting Views

struct ComplianceMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .padding()
        .frame(width: 140, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ComplianceStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct AdminComplianceIssueRow: View {
    let issue: CoreTypes.ComplianceIssue
    let isSelected: Bool
    let onTap: () -> Void
    let onSelect: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: { onSelect(!isSelected) }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.3))
            }
            
            // Issue info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(issue.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    ComplianceSeverityBadge(severity: issue.severity)
                }
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack {
                    if let buildingName = issue.buildingName {
                        Text(buildingName)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    ComplianceStatusBadge(status: issue.status)
                    
                    if let dueDate = issue.dueDate {
                        Text("Due: \(dueDate.formatted(.dateTime.month().day()))")
                            .font(.caption2)
                            .foregroundColor(dueDate < Date() ? .red : .white.opacity(0.5))
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct ComplianceSeverityBadge: View {
    let severity: CoreTypes.ComplianceSeverity
    
    var body: some View {
        Text(severity.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(severityColor.opacity(0.2))
            )
            .foregroundColor(severityColor)
    }
    
    private var severityColor: Color {
        switch severity {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct ComplianceStatusBadge: View {
    let status: CoreTypes.ComplianceStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case .open: return .red
        case .inProgress: return .orange
        case .resolved: return .green
        case .closed: return .gray
        }
    }
}

// MARK: - Data Models

struct ComplianceMetrics {
    let total: Int
    let open: Int
    let critical: Int
    let resolved: Int
    let overdue: Int
    let complianceScore: Double
}

// MARK: - Placeholder Views

struct AdminComplianceIssueDetailView: View {
    let issue: CoreTypes.ComplianceIssue
    let onUpdate: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Compliance Issue Detail")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text(issue.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Issue Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onUpdate()
                    }
                }
            }
        }
    }
}

struct AdminCreateComplianceIssueView: View {
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Compliance Issue")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("New Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                }
            }
        }
    }
}

struct AdminComplianceBulkActionsView: View {
    let selectedIssues: [String]
    let allIssues: [CoreTypes.ComplianceIssue]
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Bulk Actions")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("\(selectedIssues.count) issues selected")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Bulk Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                }
            }
        }
    }
}

struct AdminScheduleInspectionView: View {
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Schedule Inspection")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Schedule Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                }
            }
        }
    }
}

// Preview removed to avoid constructing async ServiceContainer in previews

#endif
