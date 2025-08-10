
//  BuildingHistoryComponents.swift
//  CyntientOps v6.0
//
//  📜 HISTORY: Comprehensive maintenance and activity tracking
//  📊 ANALYTICS: Performance trends and insights
//  🔍 SEARCH: Filter and export historical data
//

import SwiftUI
import Combine

// MARK: - Supporting Types (using BuildingDetailViewModel types)
// MaintenanceRecord types are defined in BuildingDetailViewModel as BDMaintenanceRecord

struct MaintenanceRecordRow: View {
    let record: BDMaintenanceRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(record.description)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                if let cost = record.cost {
                    Text("$\(cost.doubleValue, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - Maintenance History Card

struct MaintenanceHistoryCard: View {
    let maintenanceRecords: [BDMaintenanceRecord]
    let buildingId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Maintenance History", systemImage: "wrench.and.screwdriver")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("\(maintenanceRecords.count) records")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            // Records list
            ForEach(maintenanceRecords.prefix(5), id: \.id) { record in
                MaintenanceRecordRow(record: record)
            }
        }
        .francoCardPadding()
        .francoGlassBackground()
    }
}

// MARK: - Vendor Visits Card

struct VendorVisitsCard: View {
    let buildingId: String
    @State private var visits: [VendorVisit] = []
    @State private var isLoading = true
    @State private var showingAddVisit = false
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Vendor Visits", systemImage: "person.badge.clock")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Add visit button
                if let userRole = getUserRole(), userRole == .worker || userRole == .admin {
                    Button(action: { showingAddVisit = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if isLoading {
                ProgressView("Loading vendor visits...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if visits.isEmpty {
                Text("No vendor visits recorded")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 12) {
                    ForEach(visits.prefix(10)) { visit in
                        VendorVisitRow(visit: visit)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadVendorVisits()
        }
        .sheet(isPresented: $showingAddVisit) {
            LogVendorVisitSheet(
                buildingId: buildingId,
                onSave: { newVisit in
                    visits.insert(newVisit, at: 0)
                }
            )
        }
    }
    
    private func getUserRole() -> CoreTypes.UserRole? {
        // Get from auth manager or dashboard sync
        return .worker // Placeholder
    }
    
    private func loadVendorVisits() async {
        do {
            let rows = try await GRDBManager.shared.query("""
                SELECT * FROM vendor_visits
                WHERE building_id = ?
                ORDER BY visit_date DESC
                LIMIT 50
            """, [buildingId])
            
            visits = rows.compactMap { VendorVisit(from: $0) }
            isLoading = false
            
        } catch {
            print("❌ Error loading vendor visits: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Compliance History List

struct ComplianceHistoryList: View {
    let buildingId: String
    @State private var complianceRecords: [ComplianceRecord] = []
    @State private var selectedTimeRange = TimeRange.lastMonth
    @State private var selectedType: ComplianceType = .all
    
    enum TimeRange: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case lastYear = "Last Year"
        case all = "All Time"
    }
    
    enum ComplianceType: String, CaseIterable {
        case all = "All"
        case sanitation = "Sanitation"
        case safety = "Safety"
        case building = "Building"
        case environmental = "Environmental"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Label("Compliance History", systemImage: "checkmark.seal")
                .font(.headline)
                .foregroundColor(.white)
            
            // Filters
            VStack(spacing: 12) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ComplianceType.allCases, id: \.self) { type in
                            ComplianceTypeFilterChip(
                                type: type,
                                isSelected: selectedType == type,
                                action: { selectedType = type }
                            )
                        }
                    }
                }
            }
            
            // Records list
            if filteredRecords.isEmpty {
                Text("No compliance records for selected filters")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredRecords) { record in
                            ComplianceRecordRow(record: record)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            
            // Summary stats
            ComplianceSummaryBar(records: filteredRecords)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadComplianceHistory()
        }
    }
    
    private var filteredRecords: [ComplianceRecord] {
        complianceRecords.filter { record in
            let typeMatches = selectedType == .all || record.type == selectedType.rawValue
            let dateMatches = isWithinTimeRange(record.date, range: selectedTimeRange)
            return typeMatches && dateMatches
        }
    }
    
    private func isWithinTimeRange(_ date: Date, range: TimeRange) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .lastWeek:
            return date > calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        case .lastMonth:
            return date > calendar.date(byAdding: .month, value: -1, to: now)!
        case .lastQuarter:
            return date > calendar.date(byAdding: .month, value: -3, to: now)!
        case .lastYear:
            return date > calendar.date(byAdding: .year, value: -1, to: now)!
        case .all:
            return true
        }
    }
    
    private func loadComplianceHistory() async {
        // Load from database
        // Mock data for now
        complianceRecords = [
            ComplianceRecord(
                id: "1",
                buildingId: buildingId,
                type: "sanitation",
                status: "passed",
                date: Date().addingTimeInterval(-86400),
                inspector: "DSNY Inspector",
                notes: "All requirements met"
            ),
            ComplianceRecord(
                id: "2",
                buildingId: buildingId,
                type: "safety",
                status: "warning",
                date: Date().addingTimeInterval(-604800),
                inspector: "Fire Department",
                notes: "Exit sign needs replacement"
            )
        ]
    }
}

// MARK: - Issue Resolution Timeline

struct IssueResolutionTimeline: View {
    let buildingId: String
    @State private var issues: [BuildingIssue] = []
    @State private var selectedStatus = IssueStatus.all
    
    enum IssueStatus: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Issue Timeline", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Status filter
                Menu {
                    ForEach(IssueStatus.allCases, id: \.self) { status in
                        Button(action: { selectedStatus = status }) {
                            Label(status.rawValue, systemImage: statusIcon(status))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedStatus.rawValue)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Timeline
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredIssues) { issue in
                        IssueTimelineItem(issue: issue)
                    }
                }
            }
            .frame(maxHeight: 500)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadIssues()
        }
    }
    
    private var filteredIssues: [BuildingIssue] {
        if selectedStatus == .all {
            return issues
        }
        return issues.filter { $0.status == selectedStatus.rawValue }
    }
    
    private func statusIcon(_ status: IssueStatus) -> String {
        switch status {
        case .all: return "circle"
        case .open: return "circle"
        case .inProgress: return "circle.badge.clock"
        case .resolved: return "checkmark.circle.fill"
        }
    }
    
    private func loadIssues() async {
        // Load from database
        // Mock data for now
        issues = [
            BuildingIssue(
                id: "1",
                title: "Elevator maintenance required",
                description: "Annual inspection due",
                status: "open",
                priority: "high",
                reportedDate: Date().addingTimeInterval(-172800),
                reportedBy: "System",
                assignedTo: nil,
                resolvedDate: nil,
                resolution: nil
            )
        ]
    }
}

// MARK: - Building Activity Feed

struct BuildingActivityFeed: View {
    let buildingId: String
    @State private var activities: [BuildingActivity] = []
    @State private var isLoadingMore = false
    @State private var hasMoreData = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(activities) { activity in
                        ActivityFeedItem(activity: activity)
                    }
                    
                    if hasMoreData {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .onAppear {
                                Task {
                                    await loadMoreActivities()
                                }
                            }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadInitialActivities()
        }
    }
    
    private func loadInitialActivities() async {
        // Load recent activities
        activities = generateMockActivities(count: 20)
    }
    
    private func loadMoreActivities() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let newActivities = generateMockActivities(count: 10)
        activities.append(contentsOf: newActivities)
        
        if activities.count > 50 {
            hasMoreData = false
        }
        
        isLoadingMore = false
    }
    
    private func generateMockActivities(count: Int) -> [BuildingActivity] {
        (0..<count).map { index in
            BuildingActivity(
                id: UUID().uuidString,
                type: ["task_completed", "worker_arrived", "issue_reported", "inventory_updated"].randomElement()!,
                title: "Activity \(activities.count + index + 1)",
                description: "Description for activity",
                timestamp: Date().addingTimeInterval(-Double(index * 3600)),
                userId: "user_\(index)",
                userName: "Worker \(index)"
            )
        }
    }
}

// MARK: - History Filter Bar

struct HistoryFilterBar: View {
    let onFilterChanged: (HistoryFilter) -> Void
    @State private var selectedType = FilterType.all
    @State private var selectedDateRange = DateRange.lastMonth
    @State private var searchText = ""
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case maintenance = "Maintenance"
        case compliance = "Compliance"
        case issues = "Issues"
        case vendors = "Vendors"
    }
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case lastWeek = "Week"
        case lastMonth = "Month"
        case lastQuarter = "Quarter"
        case lastYear = "Year"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Type filters
                    ForEach(FilterType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isActive: selectedType == type,
                            count: getFilterCount(for: type),
                            action: {
                                selectedType = type
                                applyFilters()
                            }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                        .background(Color.white.opacity(0.3))
                    
                    // Date range filters
                    ForEach(DateRange.allCases, id: \.self) { range in
                        FilterChip(
                            title: range.rawValue,
                            isActive: selectedDateRange == range,
                            count: getDateRangeCount(for: range),
                            action: {
                                selectedDateRange = range
                                applyFilters()
                            }
                        )
                    }
                }
            }
        }
        .onChange(of: searchText) { _ in
            applyFilters()
        }
    }
    
    private func applyFilters() {
        let filter = HistoryFilter(
            type: selectedType.rawValue,
            dateRange: selectedDateRange.rawValue,
            searchText: searchText
        )
        onFilterChanged(filter)
    }
    
    private func getFilterCount(for type: FilterType) -> Int {
        // Return estimated count - would be based on actual data in real implementation
        switch type {
        case .all:
            return 25
        case .maintenance:
            return 8
        case .compliance:
            return 12
        case .issues:
            return 5
        case .vendors:
            return 3
        }
    }
    
    private func getDateRangeCount(for range: DateRange) -> Int {
        // Return estimated count - would be based on actual data in real implementation
        switch range {
        case .today:
            return 3
        case .lastWeek:
            return 8
        case .lastMonth:
            return 15
        case .lastQuarter:
            return 22
        case .lastYear:
            return 25
        }
    }
}

// MARK: - Export History Sheet

struct ExportHistorySheet: View {
    let buildingId: String
    let buildingName: String
    @State private var exportFormat = ExportFormat.pdf
    @State private var includePhotos = false
    @State private var dateRange = DateRangeSelection.lastMonth
    @State private var selectedCategories: Set<String> = ["maintenance", "compliance", "issues"]
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case excel = "Excel"
        case csv = "CSV"
    }
    
    enum DateRangeSelection: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case lastYear = "Last Year"
        case custom = "Custom Range"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if exportFormat == .pdf {
                        Toggle("Include Photos", isOn: $includePhotos)
                    }
                }
                
                Section(header: Text("Date Range")) {
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(DateRangeSelection.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    
                    if dateRange == .custom {
                        DatePicker("Start Date", selection: .constant(Date()), displayedComponents: .date)
                        DatePicker("End Date", selection: .constant(Date()), displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Categories to Include")) {
                    ForEach(["maintenance", "compliance", "issues", "vendors", "activities"], id: \.self) { category in
                        HStack {
                            Image(systemName: selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedCategories.contains(category) ? .blue : .gray)
                                .onTapGesture {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            
                            Text(category.capitalized)
                            
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Text("The report will be generated and available for download")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportHistory) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Export")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedCategories.isEmpty || isExporting)
                }
            }
        }
    }
    
    private func exportHistory() {
        isExporting = true
        
        Task {
            // Generate export
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // In real implementation, generate file and share
            print("Exporting \(buildingName) history as \(exportFormat.rawValue)")
            print("Categories: \(selectedCategories)")
            print("Date range: \(dateRange.rawValue)")
            
            isExporting = false
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct VendorVisitRow: View {
    let visit: VendorVisit
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Vendor type icon
            Image(systemName: vendorIcon(visit.vendorType))
                .font(.title3)
                .foregroundColor(vendorColor(visit.vendorType))
                .frame(width: 40, height: 40)
                .background(vendorColor(visit.vendorType).opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(visit.vendorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(visit.purpose)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(visit.visitDate.formatted(date: .abbreviated, time: .shortened), 
                          systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let duration = visit.duration {
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Label("\(duration) min", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            if visit.requiresFollowUp {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func vendorIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "maintenance": return "wrench.fill"
        case "delivery": return "shippingbox.fill"
        case "inspection": return "magnifyingglass.circle.fill"
        case "cleaning": return "sparkles"
        default: return "person.fill"
        }
    }
    
    private func vendorColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "maintenance": return .orange
        case "delivery": return .blue
        case "inspection": return .purple
        case "cleaning": return .green
        default: return .gray
        }
    }
}

struct ComplianceRecordRow: View {
    let record: ComplianceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Status icon
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                Text(record.type.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(record.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let inspector = record.inspector {
                Text("Inspector: \(inspector)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if let notes = record.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch record.status {
        case "passed": return "checkmark.circle.fill"
        case "failed": return "xmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch record.status {
        case "passed": return .green
        case "failed": return .red
        case "warning": return .orange
        default: return .gray
        }
    }
    
    private var backgroundColor: Color {
        switch record.status {
        case "passed": return Color.green.opacity(0.1)
        case "failed": return Color.red.opacity(0.1)
        case "warning": return Color.orange.opacity(0.1)
        default: return Color.white.opacity(0.05)
        }
    }
}

struct ComplianceTypeFilterChip: View {
    let type: ComplianceHistoryList.ComplianceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                )
        }
    }
}

struct ComplianceSummaryBar: View {
    let records: [ComplianceRecord]
    
    private var stats: ComplianceStats {
        let total = records.count
        let passed = records.filter { $0.status == "passed" }.count
        let failed = records.filter { $0.status == "failed" }.count
        let warnings = records.filter { $0.status == "warning" }.count
        
        return ComplianceStats(
            total: total,
            passed: passed,
            failed: failed,
            warnings: warnings,
            passRate: total > 0 ? Double(passed) / Double(total) * 100 : 0
        )
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ComplianceStatItem(
                label: "Pass Rate",
                value: "\(Int(stats.passRate))%",
                color: stats.passRate > 80 ? .green : .orange
            )
            
            ComplianceStatItem(
                label: "Passed",
                value: "\(stats.passed)",
                color: .green
            )
            
            ComplianceStatItem(
                label: "Warnings",
                value: "\(stats.warnings)",
                color: .orange
            )
            
            ComplianceStatItem(
                label: "Failed",
                value: "\(stats.failed)",
                color: .red
            )
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct ComplianceStatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct IssueTimelineItem: View {
    let issue: BuildingIssue
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline connector
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2)
            }
            
            // Issue content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(issue.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    PriorityBadge(priority: issue.priority)
                }
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label(issue.reportedDate.formatted(date: .abbreviated, time: .omitted), 
                          systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let assignedTo = issue.assignedTo {
                        Label(assignedTo, systemImage: "person.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                if issue.status == "resolved", let resolution = issue.resolution {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resolution")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text(resolution)
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.8))
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private var statusColor: Color {
        switch issue.status {
        case "open": return .red
        case "inProgress": return .orange
        case "resolved": return .green
        default: return .gray
        }
    }
}

struct PriorityBadge: View {
    let priority: String
    
    var body: some View {
        Text(priority.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(priorityColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

struct ActivityFeedItem: View {
    let activity: BuildingActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Activity icon
            Image(systemName: activityIcon)
                .font(.caption)
                .foregroundColor(activityColor)
                .frame(width: 32, height: 32)
                .background(activityColor.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let description = activity.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack(spacing: 8) {
                    Text(activity.userName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(activity.timestamp, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var activityIcon: String {
        switch activity.type {
        case "task_completed": return "checkmark.circle.fill"
        case "worker_arrived": return "person.fill.checkmark"
        case "issue_reported": return "exclamationmark.triangle"
        case "inventory_updated": return "shippingbox.fill"
        default: return "circle.fill"
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case "task_completed": return .green
        case "worker_arrived": return .blue
        case "issue_reported": return .orange
        case "inventory_updated": return .purple
        default: return .gray
        }
    }
}

struct BuildingFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                )
        }
    }
}

struct LogVendorVisitSheet: View {
    let buildingId: String
    let onSave: (VendorVisit) -> Void
    
    @State private var vendorName = ""
    @State private var vendorType = "maintenance"
    @State private var purpose = ""
    @State private var visitDate = Date()
    @State private var duration: Int?
    @State private var requiresFollowUp = false
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vendor Information")) {
                    TextField("Vendor Name", text: $vendorName)
                    
                    Picker("Type", selection: $vendorType) {
                        Text("Maintenance").tag("maintenance")
                        Text("Delivery").tag("delivery")
                        Text("Inspection").tag("inspection")
                        Text("Cleaning").tag("cleaning")
                        Text("Other").tag("other")
                    }
                    
                    TextField("Purpose of Visit", text: $purpose)
                }
                
                Section(header: Text("Visit Details")) {
                    DatePicker("Date & Time", selection: $visitDate)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Minutes", value: $duration, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    Toggle("Requires Follow-up", isOn: $requiresFollowUp)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Vendor Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let visit = VendorVisit(
                            id: UUID().uuidString,
                            buildingId: buildingId,
                            vendorName: vendorName,
                            vendorType: vendorType,
                            purpose: purpose,
                            visitDate: visitDate,
                            duration: duration,
                            requiresFollowUp: requiresFollowUp,
                            notes: notes.isEmpty ? nil : notes,
                            loggedBy: "current_user" // Get from auth
                        )
                        onSave(visit)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(vendorName.isEmpty || purpose.isEmpty)
                }
            }
        }
    }
}

// MARK: - Data Models

struct VendorVisit: Identifiable {
    let id: String
    let buildingId: String
    let vendorName: String
    let vendorType: String
    let purpose: String
    let visitDate: Date
    let duration: Int? // in minutes
    let requiresFollowUp: Bool
    let notes: String?
    let loggedBy: String
    
    init(id: String, buildingId: String, vendorName: String, vendorType: String,
         purpose: String, visitDate: Date, duration: Int?, requiresFollowUp: Bool,
         notes: String?, loggedBy: String) {
        self.id = id
        self.buildingId = buildingId
        self.vendorName = vendorName
        self.vendorType = vendorType
        self.purpose = purpose
        self.visitDate = visitDate
        self.duration = duration
        self.requiresFollowUp = requiresFollowUp
        self.notes = notes
        self.loggedBy = loggedBy
    }
    
    init(from row: [String: Any]) {
        self.id = row["id"] as? String ?? UUID().uuidString
        self.buildingId = row["building_id"] as? String ?? ""
        self.vendorName = row["vendor_name"] as? String ?? ""
        self.vendorType = row["vendor_type"] as? String ?? "other"
        self.purpose = row["purpose"] as? String ?? ""
        self.visitDate = ISO8601DateFormatter().date(from: row["visit_date"] as? String ?? "") ?? Date()
        self.duration = row["duration"] as? Int
        self.requiresFollowUp = (row["requires_follow_up"] as? Int ?? 0) == 1
        self.notes = row["notes"] as? String
        self.loggedBy = row["logged_by"] as? String ?? ""
    }
}

struct ComplianceRecord: Identifiable {
    let id: String
    let buildingId: String
    let type: String
    let status: String
    let date: Date
    let inspector: String?
    let notes: String?
}

struct BuildingIssue: Identifiable {
    let id: String
    let title: String
    let description: String
    let status: String
    let priority: String
    let reportedDate: Date
    let reportedBy: String
    let assignedTo: String?
    let resolvedDate: Date?
    let resolution: String?
}

struct BuildingActivity: Identifiable {
    let id: String
    let type: String
    let title: String
    let description: String?
    let timestamp: Date
    let userId: String
    let userName: String
}

struct HistoryFilter {
    let type: String
    let dateRange: String
    let searchText: String
}

struct ComplianceStats {
    let total: Int
    let passed: Int
    let failed: Int
    let warnings: Int
    let passRate: Double
}
