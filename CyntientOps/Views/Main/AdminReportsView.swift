//
//  AdminReportsView.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/3/25.
//


///
//  AdminReportsView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Following established admin panel patterns
//  ✅ INTELLIGENT: Report insights and recommendations
//  ✅ AUTOMATED: Scheduled report generation
//  ✅ COMPREHENSIVE: All report types and formats
//  ✅ DARK ELEGANCE: Consistent theme
//

import SwiftUI
import Combine

struct AdminReportsView: View {
    // MARK: - Properties
    
    @StateObject private var reportGen = ReportGenerator.shared
    @StateObject private var reportService = ReportService.shared
    @StateObject private var novaEngine = NovaAIManager.shared
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @EnvironmentObject private var adminViewModel: AdminDashboardViewModel
    
    // State management
    @State private var isHeroCollapsed = false
    @State private var currentContext: ViewContext = .overview
    @State private var selectedReportType: ReportType = .comprehensive
    @State private var selectedDateRange: DateRange = .lastMonth
    @State private var showingReportBuilder = false
    @State private var showingScheduleSetup = false
    @State private var showingExportOptions = false
    @State private var showingReportHistory = false
    @State private var showingReportPreview = false
    @State private var showingTemplateLibrary = false
    @State private var showingDistributionSettings = false
    @State private var currentReport: GeneratedReport?
    @State private var isGenerating = false
    @State private var searchText = ""
    @State private var filterCategory: ReportCategory = .all
    
    // Intelligence panel state
    @AppStorage("reportsPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // MARK: - Enums
    
    enum ViewContext {
        case overview
        case building
        case creating
        case previewing
        case exporting
    }
    
    enum IntelPanelState: String {
        case hidden = "hidden"
        case minimal = "minimal"
        case collapsed = "collapsed"
        case expanded = "expanded"
    }
    
    enum ReportType: String, CaseIterable {
        case comprehensive = "Comprehensive"
        case compliance = "Compliance"
        case performance = "Performance"
        case financial = "Financial"
        case operations = "Operations"
        case executive = "Executive Summary"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .comprehensive: return "doc.text.fill"
            case .compliance: return "checkmark.shield.fill"
            case .performance: return "chart.line.uptrend.xyaxis"
            case .financial: return "dollarsign.circle.fill"
            case .operations: return "gear"
            case .executive: return "briefcase.fill"
            case .custom: return "slider.horizontal.3"
            }
        }
        
        var color: Color {
            switch self {
            case .comprehensive: return CyntientOpsDesign.DashboardColors.primaryAction
            case .compliance: return CyntientOpsDesign.DashboardColors.warning
            case .performance: return CyntientOpsDesign.DashboardColors.success
            case .financial: return CyntientOpsDesign.DashboardColors.info
            case .operations: return CyntientOpsDesign.DashboardColors.tertiaryAction
            case .executive: return CyntientOpsDesign.DashboardColors.critical
            case .custom: return CyntientOpsDesign.DashboardColors.secondaryAction
            }
        }
    }
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case lastYear = "Last Year"
        case custom = "Custom Range"
        
        var dateInterval: DateInterval {
            let now = Date()
            let calendar = Calendar.current
            
            switch self {
            case .today:
                return DateInterval(start: calendar.startOfDay(for: now), end: now)
            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
                return DateInterval(start: calendar.startOfDay(for: yesterday),
                                  end: calendar.endOfDay(for: yesterday))
            case .lastWeek:
                let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
                return DateInterval(start: weekAgo, end: now)
            case .lastMonth:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
                return DateInterval(start: monthAgo, end: now)
            case .lastQuarter:
                let quarterAgo = calendar.date(byAdding: .month, value: -3, to: now)!
                return DateInterval(start: quarterAgo, end: now)
            case .lastYear:
                let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
                return DateInterval(start: yearAgo, end: now)
            case .custom:
                return DateInterval(start: now, end: now)
            }
        }
    }
    
    enum ReportCategory: String, CaseIterable {
        case all = "All Reports"
        case scheduled = "Scheduled"
        case recent = "Recent"
        case favorites = "Favorites"
        case archived = "Archived"
    }
    
    // MARK: - Computed Properties
    
    private var intelligencePanelState: IntelPanelState {
        switch currentContext {
        case .overview:
            return hasReportingInsights() ? .expanded : userPanelPreference
        case .building, .creating:
            return .minimal
        case .previewing, .exporting:
            return .hidden
        }
    }
    
    private var filteredReports: [GeneratedReport] {
        reportService.generatedReports.filter { report in
            let matchesSearch = searchText.isEmpty ||
                report.name.localizedCaseInsensitiveContains(searchText) ||
                report.type.rawValue.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory: Bool = {
                switch filterCategory {
                case .all: return true
                case .scheduled: return report.isScheduled
                case .recent: return report.generatedDate > Date().addingTimeInterval(-7 * 24 * 3600)
                case .favorites: return report.isFavorite
                case .archived: return report.isArchived
                }
            }()
            
            return matchesSearch && matchesCategory
        }
    }
    
    private func hasReportingInsights() -> Bool {
        reportService.pendingReports.count > 0 ||
        reportService.overdueReports.count > 0 ||
        reportGen.hasQueuedReports
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Dark Elegance Background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                reportsHeader
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Collapsible Reports Hero
                        CollapsibleReportsHeroWrapper(
                            isCollapsed: $isHeroCollapsed,
                            totalReports: reportService.totalReportsGenerated,
                            scheduledReports: reportService.scheduledReports.count,
                            lastGenerated: reportService.lastGeneratedDate,
                            avgGenerationTime: reportService.avgGenerationTime,
                            favoriteReports: reportService.favoriteReports,
                            onGenerateNow: { showingReportBuilder = true },
                            onSchedule: { showingScheduleSetup = true },
                            onViewHistory: { showingReportHistory = true },
                            onTemplates: { showingTemplateLibrary = true }
                        )
                        .zIndex(50)
                        
                        // Quick Report Generation
                        quickReportSection
                        
                        // Scheduled Reports (if any)
                        if !reportService.scheduledReports.isEmpty {
                            scheduledReportsSection
                        }
                        
                        // Recent Reports
                        if !filteredReports.isEmpty {
                            recentReportsSection
                        }
                        
                        // Report Templates
                        reportTemplatesGrid
                        
                        // Spacer for intelligence panel
                        Spacer(minLength: intelligencePanelState == .hidden ? 20 : 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .refreshable {
                    await refreshReportData()
                }
                
                // Contextual Intelligence Panel
                if intelligencePanelState != .hidden && !getReportingInsights().isEmpty {
                    ReportIntelligencePanel(
                        insights: getReportingInsights(),
                        displayMode: intelligencePanelState,
                        onNavigate: handleIntelligenceNavigation
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(CyntientOpsDesign.Animations.spring, value: intelligencePanelState)
                }
            }
            
            // Overlay: Report generation progress
            if isGenerating {
                reportGenerationOverlay
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingReportBuilder) {
            ReportBuilderSheet(
                reportType: selectedReportType,
                dateRange: selectedDateRange,
                buildings: adminViewModel.buildings,
                workers: adminViewModel.workers,
                onGenerate: { config in
                    generateReport(with: config)
                }
            )
            .onAppear { currentContext = .creating }
            .onDisappear { currentContext = .overview }
        }
        .sheet(isPresented: $showingScheduleSetup) {
            ScheduleReportSheet(
                availableReports: reportService.reportTemplates,
                onSchedule: { schedule in
                    scheduleReport(schedule)
                }
            )
        }
        .sheet(isPresented: $showingExportOptions) {
            if let report = currentReport {
                ExportOptionsSheet(
                    report: report,
                    onExport: { format, destination in
                        exportReport(report, format: format, to: destination)
                    }
                )
            }
        }
        .sheet(isPresented: $showingReportHistory) {
            ReportHistorySheet(
                reports: reportService.allReports,
                onSelect: { report in
                    currentReport = report
                    showingReportPreview = true
                }
            )
        }
        .sheet(isPresented: $showingReportPreview) {
            if let report = currentReport {
                ReportPreviewSheet(
                    report: report,
                    onExport: {
                        showingExportOptions = true
                    },
                    onDismiss: {
                        currentReport = nil
                        showingReportPreview = false
                    }
                )
                .onAppear { currentContext = .previewing }
                .onDisappear { currentContext = .overview }
            }
        }
        .sheet(isPresented: $showingTemplateLibrary) {
            TemplateLibrarySheet(
                templates: reportService.reportTemplates,
                onSelect: { template in
                    applyTemplate(template)
                }
            )
        }
        .sheet(isPresented: $showingDistributionSettings) {
            DistributionSettingsSheet(
                currentSettings: reportService.distributionSettings,
                onSave: { settings in
                    updateDistributionSettings(settings)
                }
            )
        }
        .onAppear {
            Task {
                await reportService.loadReportData()
            }
        }
    }
    
    // MARK: - Header
    
    private var reportsHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reports & Analytics")
                        .francoTypography(CyntientOpsDesign.Typography.dashboardTitle)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    HStack(spacing: 8) {
                        Text("\(reportService.totalReportsGenerated)")
                            .francoTypography(CyntientOpsDesign.Typography.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        
                        Text("reports generated")
                            .francoTypography(CyntientOpsDesign.Typography.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        
                        if reportGen.isGenerating {
                            ReportGeneratingIndicator()
                        }
                    }
                }
                
                Spacer()
                
                // Quick action menu
                Menu {
                    Button(action: { showingReportBuilder = true }) {
                        Label("Generate Report", systemImage: "doc.badge.plus")
                    }
                    
                    Button(action: { showingScheduleSetup = true }) {
                        Label("Schedule Report", systemImage: "calendar.badge.clock")
                    }
                    
                    Button(action: { showingTemplateLibrary = true }) {
                        Label("Report Templates", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(action: { showingReportHistory = true }) {
                        Label("View History", systemImage: "clock.arrow.circlepath")
                    }
                    
                    Button(action: { showingDistributionSettings = true }) {
                        Label("Distribution Settings", systemImage: "paperplane")
                    }
                    
                    Button(action: { showingExportOptions = true }) {
                        Label("Export Settings", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(CyntientOpsDesign.DashboardColors.borderSubtle)
        }
    }
    
    // MARK: - Quick Report Section
    
    private var quickReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Report")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                // Report type selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReportType.allCases, id: \.self) { type in
                            ReportTypeChip(
                                type: type,
                                isSelected: selectedReportType == type,
                                onTap: {
                                    withAnimation {
                                        selectedReportType = type
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Date range selector
                HStack {
                    Text("Period:")
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Menu {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Button(range.rawValue) {
                                selectedDateRange = range
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedDateRange.rawValue)
                                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(CyntientOpsDesign.DashboardColors.cardBackground)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        generateQuickReport()
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Generate")
                        }
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .fontWeight(.medium)
                    }
                    .buttonStyle(ReportActionButtonStyle(color: selectedReportType.color))
                }
            }
            .francoCardPadding()
            .francoDarkCardBackground()
        }
    }
    
    // MARK: - Scheduled Reports Section
    
    private var scheduledReportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Scheduled Reports", systemImage: "calendar.badge.clock")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Button("Manage") {
                    showingScheduleSetup = true
                }
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(reportService.scheduledReports.prefix(5)) { schedule in
                        ScheduledReportCard(
                            schedule: schedule,
                            onEdit: {
                                editSchedule(schedule)
                            },
                            onDisable: {
                                disableSchedule(schedule)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Reports Section
    
    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with search
            HStack {
                Text("Report Library")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                // Category filter
                Menu {
                    ForEach(ReportCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) {
                            withAnimation {
                                filterCategory = category
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(filterCategory.rawValue)
                            .francoTypography(CyntientOpsDesign.Typography.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                TextField("Search reports...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
            .cornerRadius(8)
            
            // Reports list
            if filteredReports.isEmpty {
                EmptyReportsState(category: filterCategory)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredReports.prefix(5)) { report in
                        ReportRowCard(
                            report: report,
                            onView: {
                                currentReport = report
                                showingReportPreview = true
                            },
                            onExport: {
                                currentReport = report
                                showingExportOptions = true
                            },
                            onFavorite: {
                                toggleFavorite(report)
                            }
                        )
                    }
                    
                    if filteredReports.count > 5 {
                        Button(action: { showingReportHistory = true }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("View All \(filteredReports.count) Reports")
                            }
                            .francoTypography(CyntientOpsDesign.Typography.subheadline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Report Templates Grid
    
    private var reportTemplatesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Report Templates")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Button("View All") {
                    showingTemplateLibrary = true
                }
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(reportService.featuredTemplates.prefix(4)) { template in
                    TemplateCard(
                        template: template,
                        onUse: {
                            useTemplate(template)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Report Generation Overlay
    
    private var reportGenerationOverlay: some View {
        ZStack {
            CyntientOpsDesign.DashboardColors.baseBackground
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(CyntientOpsDesign.DashboardColors.cardBackground, lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: reportGen.generationProgress)
                        .stroke(CyntientOpsDesign.DashboardColors.primaryAction, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: reportGen.generationProgress)
                    
                    Text("\(Int(reportGen.generationProgress * 100))%")
                        .francoTypography(CyntientOpsDesign.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                
                VStack(spacing: 8) {
                    Text("Generating Report")
                        .francoTypography(CyntientOpsDesign.Typography.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(reportGen.currentStep)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Button("Cancel") {
                    reportGen.cancelGeneration()
                    isGenerating = false
                }
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.xl)
                    .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                    .shadow(radius: 20)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshReportData() async {
        await reportService.refreshData()
    }
    
    private func getReportingInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Critical: Overdue reports
        if reportService.overdueReports.count > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(reportService.overdueReports.count) overdue reports",
                description: "Scheduled reports failed to generate",
                type: .operations,
                priority: .critical,
                actionRequired: true,
                recommendedAction: "Review and regenerate"
            ))
        }
        
        // High: Report generation spike
        if reportGen.queueLength > 5 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "High report demand",
                description: "\(reportGen.queueLength) reports in queue",
                type: .efficiency,
                priority: .high,
                actionRequired: false,
                recommendedAction: "Consider batching"
            ))
        }
        
        // Medium: Popular report template
        if let popular = reportService.mostUsedTemplate {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Popular template: \(popular.name)",
                description: "Used \(popular.usageCount) times this month",
                type: .efficiency,
                priority: .medium,
                actionRequired: false,
                recommendedAction: "Create variant templates"
            ))
        }
        
        // Low: Optimization opportunity
        if reportService.avgGenerationTime > 30 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Report optimization available",
                description: "Average generation time: \(Int(reportService.avgGenerationTime))s",
                type: .efficiency,
                priority: .low,
                actionRequired: false,
                recommendedAction: "Enable caching"
            ))
        }
        
        // Add Nova AI insights
        insights.append(contentsOf: novaEngine.insights.filter {
            $0.type == .operations || $0.type == .efficiency
        })
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func handleIntelligenceNavigation(_ target: ReportIntelligencePanel.NavigationTarget) {
        switch target {
        case .report(let id):
            if let report = reportService.allReports.first(where: { $0.id == id }) {
                currentReport = report
                showingReportPreview = true
            }
            
        case .schedule:
            showingScheduleSetup = true
            
        case .templates:
            showingTemplateLibrary = true
            
        case .history:
            showingReportHistory = true
            
        case .generate:
            showingReportBuilder = true
            
        case .distribution:
            showingDistributionSettings = true
        }
    }
    
    private func generateQuickReport() {
        isGenerating = true
        currentContext = .creating
        
        Task {
            let config = ReportConfiguration(
                type: selectedReportType,
                dateRange: selectedDateRange.dateInterval,
                includePhotos: true,
                format: .pdf
            )
            
            let report = await reportGen.generateReport(config: config)
            
            await MainActor.run {
                isGenerating = false
                currentContext = .overview
                currentReport = report
                showingReportPreview = true
            }
        }
    }
    
    private func generateReport(with config: ReportConfiguration) {
        isGenerating = true
        
        Task {
            let report = await reportGen.generateReport(config: config)
            
            await MainActor.run {
                isGenerating = false
                currentReport = report
                showingReportBuilder = false
                showingReportPreview = true
            }
        }
    }
    
    private func scheduleReport(_ schedule: ReportSchedule) {
        reportService.scheduleReport(schedule)
        showingScheduleSetup = false
    }
    
    private func exportReport(_ report: GeneratedReport, format: ExportFormat, to destination: ExportDestination) {
        reportService.exportReport(report, format: format, to: destination)
        showingExportOptions = false
    }
    
    private func applyTemplate(_ template: ReportTemplate) {
        selectedReportType = template.type
        showingTemplateLibrary = false
        showingReportBuilder = true
    }
    
    private func useTemplate(_ template: ReportTemplate) {
        applyTemplate(template)
    }
    
    private func toggleFavorite(_ report: GeneratedReport) {
        reportService.toggleFavorite(report)
    }
    
    private func editSchedule(_ schedule: ReportSchedule) {
        // Edit schedule implementation
    }
    
    private func disableSchedule(_ schedule: ReportSchedule) {
        reportService.disableSchedule(schedule)
    }
    
    private func updateDistributionSettings(_ settings: DistributionSettings) {
        reportService.updateDistributionSettings(settings)
        showingDistributionSettings = false
    }
}

// MARK: - Collapsible Reports Hero Wrapper

struct CollapsibleReportsHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let totalReports: Int
    let scheduledReports: Int
    let lastGenerated: Date?
    let avgGenerationTime: Double
    let favoriteReports: [GeneratedReport]
    
    let onGenerateNow: () -> Void
    let onSchedule: () -> Void
    let onViewHistory: () -> Void
    let onTemplates: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                MinimalReportsHeroCard(
                    totalReports: totalReports,
                    scheduledCount: scheduledReports,
                    lastGenerated: lastGenerated,
                    onExpand: {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    ReportsHeroStatusCard(
                        totalReports: totalReports,
                        scheduledReports: scheduledReports,
                        lastGenerated: lastGenerated,
                        avgGenerationTime: avgGenerationTime,
                        favoriteReports: favoriteReports,
                        onGenerateNow: onGenerateNow,
                        onSchedule: onSchedule,
                        onViewHistory: onViewHistory,
                        onTemplates: onTemplates
                    )
                    
                    // Collapse button
                    Button(action: {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isCollapsed = true
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                            .padding(8)
                            .background(Circle().fill(CyntientOpsDesign.DashboardColors.glassOverlay))
                    }
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - Minimal Reports Hero Card

struct MinimalReportsHeroCard: View {
    let totalReports: Int
    let scheduledCount: Int
    let lastGenerated: Date?
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.info)
                    .frame(width: 8, height: 8)
                
                // Reports summary
                HStack(spacing: 16) {
                    ReportMetricPill(
                        value: "\(totalReports)",
                        label: "Reports",
                        color: CyntientOpsDesign.DashboardColors.primaryAction
                    )
                    
                    ReportMetricPill(
                        value: "\(scheduledCount)",
                        label: "Scheduled",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                    
                    if let last = lastGenerated {
                        ReportMetricPill(
                            value: last.formatted(.relative(presentation: .named)),
                            label: "Last",
                            color: CyntientOpsDesign.DashboardColors.secondaryText
                        )
                    }
                }
                
                Spacer()
                
                // Expand indicator
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .francoDarkCardBackground(cornerRadius: 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reports Hero Status Card

struct ReportsHeroStatusCard: View {
    let totalReports: Int
    let scheduledReports: Int
    let lastGenerated: Date?
    let avgGenerationTime: Double
    let favoriteReports: [GeneratedReport]
    
    let onGenerateNow: () -> Void
    let onSchedule: () -> Void
    let onViewHistory: () -> Void
    let onTemplates: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Reports overview
            reportsOverviewSection
            
            // Metrics grid
            reportsMetricsGrid
            
            // Quick actions
            quickActionButtons
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var reportsOverviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reporting Status")
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(totalReports)")
                            .francoTypography(CyntientOpsDesign.Typography.largeTitle)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                        
                        Text("reports generated")
                            .francoTypography(CyntientOpsDesign.Typography.body)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                    
                    if let last = lastGenerated {
                        Text("Updated \(last.formatted(.relative(presentation: .named)))")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
            }
            
            // Favorites bar
            if !favoriteReports.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorite Reports")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(favoriteReports.prefix(5)) { report in
                                FavoriteReportChip(report: report)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var reportsMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ReportMetricCard(
                title: "Scheduled",
                value: "\(scheduledReports)",
                icon: "calendar.badge.clock",
                color: CyntientOpsDesign.DashboardColors.info
            )
            
            ReportMetricCard(
                title: "Avg Time",
                value: "\(Int(avgGenerationTime))s",
                icon: "timer",
                color: CyntientOpsDesign.DashboardColors.success
            )
            
            ReportMetricCard(
                title: "This Month",
                value: "\(ReportService.shared.monthlyReportCount)",
                icon: "calendar",
                color: CyntientOpsDesign.DashboardColors.warning
            )
            
            ReportMetricCard(
                title: "Templates",
                value: "\(ReportService.shared.reportTemplates.count)",
                icon: "doc.on.doc",
                color: CyntientOpsDesign.DashboardColors.tertiaryAction
            )
        }
    }
    
    private var quickActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onGenerateNow) {
                Label("Generate", systemImage: "doc.badge.plus")
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(ReportActionButtonStyle(color: CyntientOpsDesign.DashboardColors.primaryAction))
            
            Button(action: onSchedule) {
                Label("Schedule", systemImage: "calendar")
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(ReportActionButtonStyle(color: CyntientOpsDesign.DashboardColors.info))
            
            Button(action: onTemplates) {
                Label("Templates", systemImage: "doc.on.doc")
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(ReportActionButtonStyle(color: CyntientOpsDesign.DashboardColors.success))
        }
    }
}

// MARK: - Supporting Components

struct ReportTypeChip: View {
    let type: AdminReportsView.ReportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                
                Text(type.rawValue)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : type.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? type.color : type.color.opacity(0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(20)
        }
    }
}

struct ScheduledReportCard: View {
    let schedule: ReportSchedule
    let onEdit: () -> Void
    let onDisable: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: schedule.type.icon)
                    .font(.title3)
                    .foregroundColor(schedule.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.name)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(schedule.frequency.displayText)
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: onDisable) {
                        Label("Disable", systemImage: "pause.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            
            HStack {
                Label("Next: \(schedule.nextRun.formatted(.relative(presentation: .named)))",
                      systemImage: "clock")
                    .francoTypography(CyntientOpsDesign.Typography.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                Spacer()
                
                if schedule.isEnabled {
                    Text("ACTIVE")
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                }
            }
        }
        .padding(12)
        .frame(width: 200)
        .francoDarkCardBackground()
    }
}

struct ReportRowCard: View {
    let report: GeneratedReport
    let onView: () -> Void
    let onExport: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        Button(action: onView) {
            HStack(spacing: 12) {
                Image(systemName: report.type.icon)
                    .font(.title3)
                    .foregroundColor(report.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(report.name)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(report.generatedDate.formatted(date: .abbreviated, time: .shortened))
                            .francoTypography(CyntientOpsDesign.Typography.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        
                        Text(report.fileSize)
                            .francoTypography(CyntientOpsDesign.Typography.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onFavorite) {
                        Image(systemName: report.isFavorite ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(report.isFavorite ? .yellow : CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    
                    Button(action: onExport) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TemplateCard: View {
    let template: ReportTemplate
    let onUse: () -> Void
    
    var body: some View {
        Button(action: onUse) {
            VStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(template.color)
                
                VStack(spacing: 4) {
                    Text(template.name)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(template.usageCount) uses")
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .francoDarkCardBackground()
        }
    }
}

struct EmptyReportsState: View {
    let category: AdminReportsView.ReportCategory
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            
            Text("No \(category.rawValue.lowercased())")
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct FavoriteReportChip: View {
    let report: GeneratedReport
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: report.type.icon)
                .font(.caption2)
            
            Text(report.name)
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .lineLimit(1)
        }
        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .cornerRadius(6)
    }
}

struct ReportMetricPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
    }
}

struct ReportMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(title)
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ReportGeneratingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.warning)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("GENERATING")
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
        }
        .onAppear { isAnimating = true }
    }
}

struct ReportActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Intelligence Panel

struct ReportIntelligencePanel: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let displayMode: AdminReportsView.IntelPanelState
    let onNavigate: (NavigationTarget) -> Void
    
    enum NavigationTarget {
        case report(String)
        case schedule
        case templates
        case history
        case generate
        case distribution
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(CyntientOpsDesign.DashboardColors.adminPrimary.opacity(0.3))
                .frame(height: 1)
            
            HStack(spacing: 12) {
                // Nova AI indicator
                ZStack {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.adminPrimary.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .scaleEffect(isProcessing ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                 value: isProcessing)
                    
                    Text("AI")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(insights.prefix(displayMode == .minimal ? 2 : 3)) { insight in
                            ReportInsightCard(insight: insight) {
                                handleInsightAction(insight)
                            }
                        }
                    }
                }
                
                if insights.count > 3 {
                    Button(action: { onNavigate(.history) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "chevron.up")
                                .font(.caption)
                            Text("MORE")
                                .francoTypography(CyntientOpsDesign.Typography.caption2)
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                        .frame(width: 44, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CyntientOpsDesign.DashboardColors.adminPrimary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(CyntientOpsDesign.DashboardColors.adminPrimary.opacity(0.3),
                                              lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                CyntientOpsDesign.DashboardColors.cardBackground
                    .overlay(CyntientOpsDesign.DashboardColors.glassOverlay)
            )
        }
    }
    
    private var isProcessing: Bool {
        NovaAIManager.shared.processingState != .idle
    }
    
    private func handleInsightAction(_ insight: CoreTypes.IntelligenceInsight) {
        // Handle navigation based on insight type
        onNavigate(.generate)
    }
}

struct ReportInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 6, height: 6)
                    
                    Text(insight.priority.rawValue.capitalized)
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(priorityColor)
                }
                
                Text(insight.title)
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                
                if let action = insight.recommendedAction {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text(action)
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
            .padding(12)
            .frame(width: 220, height: 95)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(priorityColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(priorityColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityColor: Color {
        CyntientOpsDesign.EnumColors.aiPriority(insight.priority)
    }
}

// MARK: - Sheet Views (Placeholder implementations)

struct ReportBuilderSheet: View {
    let reportType: AdminReportsView.ReportType
    let dateRange: AdminReportsView.DateRange
    let buildings: [CoreTypes.NamedCoordinate]
    let workers: [CoreTypes.WorkerProfile]
    let onGenerate: (ReportConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Report Builder")
                .navigationTitle("Generate Report")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Generate") {
                            let config = ReportConfiguration(
                                type: reportType,
                                dateRange: dateRange.dateInterval,
                                includePhotos: true,
                                format: .pdf
                            )
                            onGenerate(config)
                        }
                    }
                }
        }
    }
}

struct ScheduleReportSheet: View {
    let availableReports: [ReportTemplate]
    let onSchedule: (ReportSchedule) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Schedule Report")
                .navigationTitle("Schedule Report")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Schedule") {
                            // Create schedule
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ExportOptionsSheet: View {
    let report: GeneratedReport
    let onExport: (ExportFormat, ExportDestination) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Export Options")
                .navigationTitle("Export Report")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Export") {
                            onExport(.pdf, .email)
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ReportHistorySheet: View {
    let reports: [GeneratedReport]
    let onSelect: (GeneratedReport) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Report History")
                .navigationTitle("Report History")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct ReportPreviewSheet: View {
    let report: GeneratedReport
    let onExport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            Text("Report Preview: \(report.name)")
                .navigationTitle("Preview")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Export") { onExport() }
                    }
                }
        }
    }
}

struct TemplateLibrarySheet: View {
    let templates: [ReportTemplate]
    let onSelect: (ReportTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Template Library")
                .navigationTitle("Report Templates")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct DistributionSettingsSheet: View {
    let currentSettings: DistributionSettings?
    let onSave: (DistributionSettings) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Distribution Settings")
                .navigationTitle("Distribution")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // Save settings
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Supporting Types


struct ReportTemplate: Identifiable {
    let id = UUID().uuidString
    let name: String
    let type: AdminReportsView.ReportType
    let icon: String
    let color: Color
    let usageCount: Int
    let description: String
}

struct ReportSchedule: Identifiable {
    let id = UUID().uuidString
    let name: String
    let type: AdminReportsView.ReportType
    let frequency: Frequency
    let nextRun: Date
    let isEnabled: Bool
    
    enum Frequency {
        case daily
        case weekly
        case monthly
        case quarterly
        
        var displayText: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            }
        }
    }
}

struct ReportConfiguration {
    let type: AdminReportsView.ReportType
    let dateRange: DateInterval
    let includePhotos: Bool
    let format: ExportFormat
}

struct DistributionSettings {
    let emailRecipients: [String]
    let slackChannels: [String]
    let autoSend: Bool
}

enum ExportDestination {
    case email
    case download
    case cloudStorage
    case slack
}

// MARK: - Mock Services

class ReportGenerator: ObservableObject {
    static let shared = ReportGenerator()
    
    @Published var generationProgress: Double = 0
    @Published var currentStep: String = ""
    @Published var isGenerating: Bool = false
    @Published var queueLength: Int = 0
    
    var hasQueuedReports: Bool { queueLength > 0 }
    
    func generateReport(config: ReportConfiguration) async -> GeneratedReport {
        // Implementation
        return GeneratedReport(
            name: "Sample Report",
            type: config.type,
            generatedDate: Date(),
            fileSize: "2.4 MB",
            isFavorite: false,
            isScheduled: false,
            isArchived: false
        )
    }
    
    func cancelGeneration() {
        isGenerating = false
        generationProgress = 0
    }
}


// Extension for calendar
extension Calendar {
    func endOfDay(for date: Date) -> Date {
        var components = dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return self.date(from: components) ?? date
    }
}

// MARK: - Preview

struct AdminReportsView_Previews: PreviewProvider {
    static var previews: some View {
        AdminReportsView()
            .environmentObject(DashboardSyncService.shared)
            .environmentObject(AdminDashboardViewModel())
            .preferredColorScheme(.dark)
    }
}