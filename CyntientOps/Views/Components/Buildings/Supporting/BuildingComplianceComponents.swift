
//  BuildingComplianceComponents.swift
//  CyntientOps v6.0
//
//  🛡️ COMPLIANCE: Real-time compliance tracking and reporting
//  📋 INSPECTIONS: Schedule and track regulatory inspections
//  🚨 VIOLATIONS: Monitor and resolve compliance violations
//  🗽 DSNY: NYC sanitation compliance integration
//

import SwiftUI
import Combine

// MARK: - Compliance Status Card

struct ComplianceStatusCard: View {
    let buildingId: String
    @State private var complianceData: LocalBuildingComplianceData?
    @State private var isLoading = true
    @State private var showingDetailSheet = false
    @EnvironmentObject private var serviceContainer: ServiceContainer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Compliance Status", systemImage: "checkmark.shield")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let data = complianceData {
                    ComplianceScoreBadge(score: data.complianceScore)
                }
            }
            
            if isLoading {
                ProgressView("Loading compliance data...")
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if let data = complianceData {
                // Compliance overview
                VStack(spacing: 12) {
                    // Status indicators
                    HStack(spacing: 16) {
                        ComplianceIndicator(
                            title: "Safety",
                            status: data.safetyStatus,
                            icon: "shield.fill"
                        )
                        
                        ComplianceIndicator(
                            title: "Sanitation",
                            status: data.sanitationStatus,
                            icon: "trash.fill"
                        )
                        
                        ComplianceIndicator(
                            title: "Environmental",
                            status: data.environmentalStatus,
                            icon: "leaf.fill"
                        )
                    }
                    
                    // Critical issues
                    if data.criticalIssues > 0 {
                        CriticalIssuesAlert(
                            count: data.criticalIssues,
                            onTap: { showingDetailSheet = true }
                        )
                    }
                    
                    // Next inspection
                    if let nextInspection = data.nextInspection {
                        NextInspectionRow(inspection: nextInspection)
                    }
                    
                    // View details button
                    Button(action: { showingDetailSheet = true }) {
                        HStack {
                            Text("View Compliance Details")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                    }
                }
            } else {
                Text("No compliance data available")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadComplianceData()
        }
        .sheet(isPresented: $showingDetailSheet) {
            ComplianceDetailSheet(buildingId: buildingId)
        }
    }
    
    private func loadComplianceData() async {
        do {
            // Load compliance data from services
            let complianceOverview = try await serviceContainer.compliance.getComplianceOverview()
            let complianceIssues = try await serviceContainer.compliance.getComplianceIssues(for: buildingId)
            
            // Create compliance data
            complianceData = LocalBuildingComplianceData(
                complianceScore: Int(complianceOverview.overallScore * 100),
                safetyStatus: .compliant,
                sanitationStatus: .compliant,
                environmentalStatus: .compliant,
                criticalIssues: complianceIssues.filter { $0.severity == .critical }.count,
                nextInspection: nil
            )
            
            isLoading = false
            
        } catch {
            print("❌ Error loading compliance data: \(error)")
            isLoading = false
        }
    }
    
}

// MARK: - Compliance Checklist View

struct ComplianceChecklistView: View {
    let buildingId: String
    let complianceType: ComplianceChecklistType
    @State private var checklistItems: [ComplianceChecklistItem] = []
    @State private var isLoading = true
    @State private var showingAddItem = false
    @EnvironmentObject private var serviceContainer: ServiceContainer
    
    enum ComplianceChecklistType: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case annual = "Annual"
        
        var icon: String {
            switch self {
            case .daily: return "calendar.circle"
            case .weekly: return "calendar.badge.7"
            case .monthly: return "calendar.badge.30"
            case .annual: return "calendar.badge.365"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("\(complianceType.rawValue) Compliance", systemImage: complianceType.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Completion percentage
                if !checklistItems.isEmpty {
                    Text("\(completionPercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(completionColor)
                }
            }
            
            // Progress bar
            if !checklistItems.isEmpty {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(completionColor)
                            .frame(width: geometry.size.width * (Double(completedCount) / Double(checklistItems.count)))
                            .animation(.easeInOut(duration: 0.3), value: completedCount)
                    }
                }
                .frame(height: 8)
            }
            
            // Checklist items
            if isLoading {
                ProgressView("Loading checklist...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if checklistItems.isEmpty {
                EmptyChecklistView(type: complianceType)
                    .onTapGesture {
                        if getUserRole() == .admin {
                            showingAddItem = true
                        }
                    }
            } else {
                VStack(spacing: 8) {
                    ForEach(checklistItems) { item in
                        ComplianceChecklistRow(
                            item: item,
                            onToggle: { toggleItem(item) },
                            onAddNote: { addNote(to: item) }
                        )
                    }
                }
            }
            
            // Add item button (admin only)
            if getUserRole() == .admin && !checklistItems.isEmpty {
                Button(action: { showingAddItem = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Checklist Item")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadChecklist()
        }
        .sheet(isPresented: $showingAddItem) {
            AddComplianceItemSheet(
                buildingId: buildingId,
                type: complianceType,
                onSave: { newItem in
                    checklistItems.append(newItem)
                }
            )
        }
    }
    
    private var completedCount: Int {
        checklistItems.filter { $0.isCompleted }.count
    }
    
    private var completionPercentage: Int {
        guard !checklistItems.isEmpty else { return 0 }
        return Int(Double(completedCount) / Double(checklistItems.count) * 100)
    }
    
    private var completionColor: Color {
        switch completionPercentage {
        case 90...100: return .green
        case 70..<90: return .yellow
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    private func getUserRole() -> CoreTypes.UserRole? {
        // Get from auth manager or dashboard sync
        return .admin // Placeholder
    }
    
    private func loadChecklist() async {
        // Load checklist items based on type
        // Mock data for now
        switch complianceType {
        case .daily:
            checklistItems = [
                ComplianceChecklistItem(
                    id: "1",
                    title: "Sidewalk Clear (18\" from curb)",
                    category: "sanitation",
                    isCompleted: false,
                    isRequired: true,
                    dueTime: "6:00 AM",
                    photoRequired: true
                ),
                ComplianceChecklistItem(
                    id: "2",
                    title: "Trash Bins Stored Properly",
                    category: "sanitation",
                    isCompleted: false,
                    isRequired: true,
                    dueTime: "After Collection",
                    photoRequired: false
                ),
                ComplianceChecklistItem(
                    id: "3",
                    title: "Emergency Exits Clear",
                    category: "safety",
                    isCompleted: false,
                    isRequired: true,
                    dueTime: "All Day",
                    photoRequired: false
                )
            ]
        case .weekly:
            checklistItems = [
                ComplianceChecklistItem(
                    id: "4",
                    title: "Fire Extinguisher Check",
                    category: "safety",
                    isCompleted: false,
                    isRequired: true,
                    dueTime: "Monday",
                    photoRequired: true
                ),
                ComplianceChecklistItem(
                    id: "5",
                    title: "Recycling Compliance",
                    category: "environmental",
                    isCompleted: false,
                    isRequired: true,
                    dueTime: "Collection Day",
                    photoRequired: false
                )
            ]
        default:
            checklistItems = []
        }
        
        isLoading = false
    }
    
    private func toggleItem(_ item: ComplianceChecklistItem) {
        guard let index = checklistItems.firstIndex(where: { $0.id == item.id }) else { return }
        
        checklistItems[index].isCompleted.toggle()
        checklistItems[index].completedBy = checklistItems[index].isCompleted ? "Current User" : nil
        checklistItems[index].completedAt = checklistItems[index].isCompleted ? Date() : nil
        
        // Broadcast update
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .complianceStatusChanged,
            buildingId: buildingId,
            workerId: "",
            data: [
                "itemId": item.id,
                "itemTitle": item.title,
                "isCompleted": String(checklistItems[index].isCompleted),
                "complianceType": complianceType.rawValue
            ]
        )
        serviceContainer.dashboardSync.broadcastWorkerUpdate(update)
    }
    
    private func addNote(to item: ComplianceChecklistItem) {
        // Show note editor
    }
}

// MARK: - Violation Alert Banner

struct ViolationAlertBanner: View {
    let violations: [ComplianceViolation]
    @State private var showingDetails = false
    
    var body: some View {
        if !violations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Violations")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("\(violations.count) violation\(violations.count == 1 ? "" : "s") require immediate attention")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: { showingDetails = true }) {
                        Text("View")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                
                // Most critical violation
                if let critical = violations.first(where: { $0.severity == .critical }) {
                    ViolationSummaryRow(violation: critical)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.red.opacity(0.15))
            .cornerRadius(12)
            .sheet(isPresented: $showingDetails) {
                ViolationDetailsSheet(violations: violations)
            }
        }
    }
}

// MARK: - Compliance Document List

struct ComplianceDocumentList: View {
    let buildingId: String
    @State private var documents: [ComplianceDocument] = []
    @State private var isLoading = true
    @State private var selectedCategory: DocumentCategory = .all
    @State private var showingUpload = false
    
    enum DocumentCategory: String, CaseIterable {
        case all = "All"
        case certificates = "Certificates"
        case permits = "Permits"
        case inspections = "Inspections"
        case policies = "Policies"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Compliance Documents", systemImage: "doc.badge.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingUpload = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DocumentCategory.allCases, id: \.self) { category in
                        DocumentCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
            
            // Document list
            if isLoading {
                ProgressView("Loading documents...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if filteredDocuments.isEmpty {
                Text("No documents found")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredDocuments) { document in
                        ComplianceDocumentRow(
                            document: document,
                            onView: { viewDocument(document) },
                            onDownload: { downloadDocument(document) }
                        )
                    }
                }
            }
            
            // Expiring documents alert
            if hasExpiringDocuments {
                ExpiringDocumentsAlert(
                    documents: expiringDocuments,
                    onRenew: { document in
                        // Handle renewal
                    }
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadDocuments()
        }
        .sheet(isPresented: $showingUpload) {
            DocumentUploadSheet(
                buildingId: buildingId,
                onUpload: { newDocument in
                    documents.append(newDocument)
                }
            )
        }
    }
    
    private var filteredDocuments: [ComplianceDocument] {
        if selectedCategory == .all {
            return documents
        }
        return documents.filter { $0.category == selectedCategory.rawValue }
    }
    
    private var hasExpiringDocuments: Bool {
        expiringDocuments.count > 0
    }
    
    private var expiringDocuments: [ComplianceDocument] {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return documents.filter { document in
            guard let expiry = document.expiryDate else { return false }
            return expiry <= thirtyDaysFromNow && expiry > Date()
        }
    }
    
    private func loadDocuments() async {
        // Load from database
        // Mock data for now
        documents = [
            ComplianceDocument(
                id: "1",
                title: "Fire Safety Certificate",
                category: "certificates",
                type: "PDF",
                uploadDate: Date().addingTimeInterval(-2592000), // 30 days ago
                expiryDate: Date().addingTimeInterval(2592000), // 30 days from now
                fileSize: 1024 * 250, // 250 KB
                uploadedBy: "Admin"
            ),
            ComplianceDocument(
                id: "2",
                title: "Building Permit 2024",
                category: "permits",
                type: "PDF",
                uploadDate: Date().addingTimeInterval(-7776000), // 90 days ago
                expiryDate: Date().addingTimeInterval(23328000), // 270 days from now
                fileSize: 1024 * 500, // 500 KB
                uploadedBy: "Admin"
            )
        ]
        isLoading = false
    }
    
    private func viewDocument(_ document: ComplianceDocument) {
        // Open document viewer
    }
    
    private func downloadDocument(_ document: ComplianceDocument) {
        // Download document
    }
}

// MARK: - Inspection Schedule Card

struct InspectionScheduleCard: View {
    let buildingId: String
    @State private var inspections: [ScheduledInspection] = []
    @State private var isLoading = true
    @State private var showingScheduler = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Inspection Schedule", systemImage: "calendar.badge.exclamationmark")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingScheduler = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if isLoading {
                ProgressView("Loading inspections...")
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if inspections.isEmpty {
                Text("No scheduled inspections")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 12) {
                    // Next inspection highlight
                    if let nextInspection = inspections.first {
                        NextInspectionCard(inspection: nextInspection)
                    }
                    
                    // Upcoming inspections
                    if inspections.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upcoming")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(inspections.dropFirst()) { inspection in
                                InspectionRow(inspection: inspection)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadInspections()
        }
        .sheet(isPresented: $showingScheduler) {
            ScheduleInspectionSheet(
                buildingId: buildingId,
                onSchedule: { newInspection in
                    inspections.append(newInspection)
                    inspections.sort { $0.date < $1.date }
                }
            )
        }
    }
    
    private func loadInspections() async {
        // Load from database
        // Mock data for now
        inspections = [
            ScheduledInspection(
                id: "1",
                type: "Fire Safety",
                date: Date().addingTimeInterval(604800), // 1 week
                inspector: "NYC Fire Department",
                notes: "Annual fire safety inspection"
            ),
            ScheduledInspection(
                id: "2",
                type: "Building Code",
                date: Date().addingTimeInterval(2592000), // 30 days
                inspector: "NYC Buildings Department",
                notes: "Routine compliance check"
            )
        ]
        isLoading = false
    }
}

// MARK: - Compliance Report Generator

struct ComplianceReportGenerator: View {
    let buildingId: String
    @State private var reportType = ComplianceReportType.monthly
    @State private var dateRange = DateRangeSelection.lastMonth
    @State private var includePhotos = true
    @State private var includeViolations = true
    @State private var includeInspections = true
    @State private var isGenerating = false
    @State private var generatedReport: GeneratedReport?
    
    enum ComplianceReportType: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case annual = "Annual"
        case custom = "Custom"
    }
    
    enum DateRangeSelection: String, CaseIterable {
        case today = "Today"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case lastYear = "Last Year"
        case custom = "Custom Range"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Label("Generate Compliance Report", systemImage: "doc.badge.arrow.up")
                .font(.headline)
                .foregroundColor(.white)
            
            // Report type
            VStack(alignment: .leading, spacing: 8) {
                Text("Report Type")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Picker("Report Type", selection: $reportType) {
                    ForEach(ComplianceReportType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Date range
            if reportType == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date Range")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(DateRangeSelection.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Include options
            VStack(alignment: .leading, spacing: 12) {
                Text("Include in Report")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Toggle("Photo Evidence", isOn: $includePhotos)
                Toggle("Violations History", isOn: $includeViolations)
                Toggle("Inspection Records", isOn: $includeInspections)
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            // Generate button
            Button(action: generateReport) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "doc.badge.arrow.up")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Report")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isGenerating ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(isGenerating)
            
            // Generated report
            if let report = generatedReport {
                GeneratedReportCard(report: report)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func generateReport() {
        isGenerating = true
        
        Task {
            // Simulate report generation
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            generatedReport = GeneratedReport(
                id: UUID().uuidString,
                type: reportType.rawValue,
                generatedAt: Date(),
                fileSize: 1024 * 1024 * 2, // 2 MB
                pages: 12
            )
            
            isGenerating = false
        }
    }
}

// MARK: - DSNY Compliance Tracker

struct DSNYComplianceTracker: View {
    let buildingId: String
    @State private var dsnyData: DSNYComplianceData?
    @State private var isLoading = true
    @State private var showingSchedule = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("DSNY Compliance", systemImage: "trash.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let data = dsnyData {
                    DSNYStatusBadge(status: data.currentStatus)
                }
            }
            
            if isLoading {
                ProgressView("Loading DSNY data...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let data = dsnyData {
                VStack(spacing: 16) {
                    // Collection schedule
                    DSNYScheduleCard(
                        schedule: data.collectionSchedule,
                        onViewSchedule: { showingSchedule = true }
                    )
                    
                    // Current status
                    DSNYStatusCard(
                        setOutTime: data.setOutTime,
                        collectionWindow: data.collectionWindow,
                        lastCollection: data.lastCollection,
                        nextCollection: data.nextCollection
                    )
                    
                    // Compliance checklist
                    DSNYChecklistCard(
                        checklist: data.complianceChecklist,
                        onToggle: { item in
                            toggleDSNYItem(item)
                        }
                    )
                    
                    // Recent violations
                    if !data.recentViolations.isEmpty {
                        DSNYViolationsCard(violations: data.recentViolations)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadDSNYData()
        }
        .sheet(isPresented: $showingSchedule) {
            DSNYScheduleDetailSheet(buildingId: buildingId)
        }
    }
    
    private func loadDSNYData() async {
        // Load DSNY compliance data
        // Mock data for now
        dsnyData = DSNYComplianceData(
            currentStatus: .compliant,
            collectionSchedule: DSNYSchedule(
                days: ["Monday", "Wednesday", "Friday"],
                recycleDays: ["Wednesday"],
                organicsDays: ["Monday", "Friday"]
            ),
            setOutTime: "After 8:00 PM",
            collectionWindow: "6:00 AM - 12:00 PM",
            lastCollection: Date().addingTimeInterval(-86400), // Yesterday
            nextCollection: Date().addingTimeInterval(86400), // Tomorrow
            complianceChecklist: [
                DSNYChecklistItem(
                    id: "1",
                    title: "Bins stored properly after collection",
                    isCompleted: true,
                    isRequired: true
                ),
                DSNYChecklistItem(
                    id: "2",
                    title: "Sidewalk clear (18\" from curb)",
                    isCompleted: true,
                    isRequired: true
                ),
                DSNYChecklistItem(
                    id: "3",
                    title: "Recycling properly separated",
                    isCompleted: false,
                    isRequired: true
                )
            ],
            recentViolations: []
        )
        isLoading = false
    }
    
    private func toggleDSNYItem(_ item: DSNYChecklistItem) {
        // Update checklist item
    }
}

// MARK: - Compliance Photo Requirements

struct CompliancePhotoRequirements: View {
    let buildingId: String
    let requirementType: PhotoRequirementType
    @State private var requirements: [PhotoRequirement] = []
    @State private var capturedPhotos: [String: UIImage] = [:]
    @State private var selectedRequirement: PhotoRequirement?
    @State private var showingPhotoCapture = false
    
    enum PhotoRequirementType: String, CaseIterable {
        case daily = "Daily"
        case incident = "Incident"
        case inspection = "Inspection"
        case violation = "Violation Resolution"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("\(requirementType.rawValue) Photo Requirements", systemImage: "camera.badge.ellipsis")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Progress
                if !requirements.isEmpty {
                    Text("\(capturedPhotos.count) of \(requirements.count)")
                        .font(.caption)
                        .foregroundColor(isComplete ? .green : .orange)
                }
            }
            
            // Requirements list
            VStack(spacing: 12) {
                ForEach(requirements) { requirement in
                    PhotoRequirementRow(
                        requirement: requirement,
                        capturedPhoto: capturedPhotos[requirement.id],
                        onCapture: {
                            selectedRequirement = requirement
                            showingPhotoCapture = true
                        },
                        onView: { photo in
                            // View captured photo
                        }
                    )
                }
            }
            
            // Submit button
            if isComplete {
                Button(action: submitPhotos) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit Compliance Photos")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            } else {
                Text("Capture all required photos to submit")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .onAppear {
            loadRequirements()
        }
        .sheet(isPresented: $showingPhotoCapture) {
            if let requirement = selectedRequirement {
                CompliancePhotoCaptureView(
                    requirement: requirement,
                    buildingId: buildingId,
                    onCapture: { image in
                        capturedPhotos[requirement.id] = image
                    }
                )
            }
        }
    }
    
    private var isComplete: Bool {
        !requirements.isEmpty && capturedPhotos.count == requirements.count
    }
    
    private func loadRequirements() {
        // Load photo requirements based on type
        switch requirementType {
        case .daily:
            requirements = [
                PhotoRequirement(
                    id: "1",
                    title: "Building Entrance",
                    description: "Clear view of main entrance and sidewalk",
                    angle: "Front-facing, include full entrance"
                ),
                PhotoRequirement(
                    id: "2",
                    title: "Trash Area",
                    description: "Show bins properly stored",
                    angle: "Wide angle showing all bins"
                ),
                PhotoRequirement(
                    id: "3",
                    title: "Sidewalk Compliance",
                    description: "18 inches clear from curb",
                    angle: "Side angle showing clearance"
                )
            ]
        case .incident:
            requirements = [
                PhotoRequirement(
                    id: "4",
                    title: "Incident Overview",
                    description: "Wide shot of incident area",
                    angle: "Multiple angles required"
                ),
                PhotoRequirement(
                    id: "5",
                    title: "Close-up Details",
                    description: "Show specific damage or issue",
                    angle: "Close-up with good lighting"
                )
            ]
        default:
            requirements = []
        }
    }
    
    private func submitPhotos() {
        // Submit compliance photos
        print("Submitting \(capturedPhotos.count) compliance photos")
    }
}

// MARK: - Supporting Views

struct ComplianceScoreBadge: View {
    let score: Int
    
    private var scoreColor: Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .yellow
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    private var scoreGrade: String {
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(score)%")
                .font(.caption)
                .fontWeight(.bold)
            Text(scoreGrade)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(scoreColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(scoreColor.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ComplianceIndicator: View {
    let title: String
    let status: CoreTypes.ComplianceStatus
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .compliant: return .green
        case .nonCompliant: return .red
        case .warning: return .orange
        case .pending: return .gray
        case .needsReview: return .gray
        default: return .gray
        }
    }
}

struct CriticalIssuesAlert: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) Critical Issue\(count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Immediate attention required")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.6))
            }
            .padding()
            .background(Color.red.opacity(0.15))
            .cornerRadius(12)
        }
    }
}

struct NextInspectionRow: View {
    let inspection: ScheduledInspection
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Inspection: \(inspection.type)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    Label(inspection.date.formatted(date: .abbreviated, time: .omitted), 
                          systemImage: "calendar")
                    
                    if let inspector = inspection.inspector {
                        Text("•")
                        Text(inspector)
                    }
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Days until
            VStack {
                Text("\(daysUntil)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(urgencyColor)
                Text("days")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var daysUntil: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: inspection.date).day ?? 0
        return max(0, days)
    }
    
    private var urgencyColor: Color {
        switch daysUntil {
        case 0...7: return .red
        case 8...30: return .orange
        default: return .green
        }
    }
}

struct ComplianceChecklistRow: View {
    let item: ComplianceChecklistItem
    let onToggle: () -> Void
    let onAddNote: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(item.isCompleted ? .green : .white.opacity(0.5))
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .strikethrough(item.isCompleted)
                    
                    if item.isRequired {
                        Text("Required")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    if let dueTime = item.dueTime {
                        Label(dueTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if item.photoRequired {
                        Label("Photo", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    
                    if item.isCompleted, let completedBy = item.completedBy {
                        Text("• \(completedBy)")
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Note button
            Button(action: onAddNote) {
                Image(systemName: item.notes != nil ? "note.text" : "note.text.badge.plus")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(item.isCompleted ? Color.green.opacity(0.05) : Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct EmptyChecklistView: View {
    let type: ComplianceChecklistView.ComplianceChecklistType
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.3))
            
            Text("No \(type.rawValue.lowercased()) checklist items")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            Text("Tap to add items")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct ViolationSummaryRow: View {
    let violation: ComplianceViolation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(violation.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(violation.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let dueDate = violation.resolutionDueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Due")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text(dueDate, format: .dateTime.day().month())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
}

struct DocumentCategoryChip: View {
    let category: ComplianceDocumentList.DocumentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
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

struct ComplianceDocumentRow: View {
    let document: ComplianceDocument
    let onView: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        HStack {
            // Document icon
            Image(systemName: documentIcon)
                .font(.title3)
                .foregroundColor(documentColor)
                .frame(width: 40, height: 40)
                .background(documentColor.opacity(0.2))
                .cornerRadius(8)
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(document.type)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    if let size = document.fileSize {
                        Text(formatFileSize(size))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if let expiry = document.expiryDate {
                        if isExpiringSoon(expiry) {
                            Label("Expires soon", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onView) {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                }
                
                Button(action: onDownload) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private var documentIcon: String {
        switch document.type.uppercased() {
        case "PDF": return "doc.text.fill"
        case "DOC", "DOCX": return "doc.fill"
        case "XLS", "XLSX": return "tablecells.fill"
        case "IMG", "PNG", "JPG": return "photo.fill"
        default: return "doc.fill"
        }
    }
    
    private var documentColor: Color {
        switch document.category {
        case "certificates": return .green
        case "permits": return .blue
        case "inspections": return .purple
        case "policies": return .orange
        default: return .gray
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return date <= thirtyDaysFromNow && date > Date()
    }
}

struct ExpiringDocumentsAlert: View {
    let documents: [ComplianceDocument]
    let onRenew: (ComplianceDocument) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("\(documents.count) document\(documents.count == 1 ? "" : "s") expiring soon")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            ForEach(documents.prefix(3)) { document in
                HStack {
                    Text(document.title)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let expiry = document.expiryDate {
                        Text(expiry, format: .dateTime.day().month())
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Button("Renew") {
                        onRenew(document)
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
    }
}

struct NextInspectionCard: View {
    let inspection: ScheduledInspection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Inspection")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(inspection.type)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(daysUntil)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(urgencyColor)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            HStack(spacing: 12) {
                Label(inspection.date.formatted(date: .complete, time: .shortened), 
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                if let inspector = inspection.inspector {
                    Text("•")
                        .foregroundColor(.white.opacity(0.4))
                    
                    Label(inspector, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            if let notes = inspection.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(urgencyColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var daysUntil: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: inspection.date).day ?? 0
        return max(0, days)
    }
    
    private var urgencyColor: Color {
        switch daysUntil {
        case 0...7: return .red
        case 8...30: return .orange
        default: return .green
        }
    }
}

struct InspectionRow: View {
    let inspection: ScheduledInspection
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(inspection.type)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(inspection.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if let inspector = inspection.inspector {
                Text(inspector)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

struct GeneratedReportCard: View {
    let report: GeneratedReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.badge.checkmark")
                    .font(.title3)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Report Generated")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(report.type) Report • \(report.pages) pages")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: { }) {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { }) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                    }
                    
                    Button(action: { }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Label(report.generatedAt.formatted(date: .abbreviated, time: .shortened), 
                      systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                if let size = report.fileSize {
                    Text("•")
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(formatFileSize(size))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct DSNYScheduleCard: View {
    let schedule: DSNYSchedule
    let onViewSchedule: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Collection Schedule")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Button(action: onViewSchedule) {
                    Text("View Full")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Trash", systemImage: "trash.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(schedule.days.joined(separator: ", "))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                if !schedule.recycleDays.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Recycle", systemImage: "arrow.3.trianglepath")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(schedule.recycleDays.joined(separator: ", "))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                if !schedule.organicsDays.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Organics", systemImage: "leaf.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(schedule.organicsDays.joined(separator: ", "))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct DSNYStatusCard: View {
    let setOutTime: String
    let collectionWindow: String
    let lastCollection: Date?
    let nextCollection: Date?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set-Out Time")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text(setOutTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Collection Window")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text(collectionWindow)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            
            if let next = nextCollection {
                HStack {
                    Label("Next Collection", systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(next.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isCollectionToday(next) ? .orange : .white)
                }
                .padding(8)
                .background(isCollectionToday(next) ? Color.orange.opacity(0.15) : Color.white.opacity(0.03))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private func isCollectionToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct DSNYChecklistCard: View {
    let checklist: [DSNYChecklistItem]
    let onToggle: (DSNYChecklistItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compliance Checklist")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                ForEach(checklist) { item in
                    HStack {
                        Button(action: { onToggle(item) }) {
                            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundColor(item.isCompleted ? .green : .white.opacity(0.5))
                        }
                        
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .strikethrough(item.isCompleted)
                        
                        Spacer()
                        
                        if item.isRequired {
                            Text("Required")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct DSNYViolationsCard: View {
    let violations: [DSNYViolation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Violations", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("\(violations.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                ForEach(violations.prefix(3)) { violation in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(violation.description)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(violation.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        if let fine = violation.fineAmount {
                            Text("$\(fine)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct DSNYStatusBadge: View {
    let status: DSNYComplianceStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
            Text(status.rawValue)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .compliant: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .violation: return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .compliant: return .green
        case .warning: return .orange
        case .violation: return .red
        }
    }
}

struct PhotoRequirementRow: View {
    let requirement: PhotoRequirement
    let capturedPhoto: UIImage?
    let onCapture: () -> Void
    let onView: (UIImage) -> Void
    
    var body: some View {
        HStack {
            // Status icon
            Image(systemName: capturedPhoto != nil ? "checkmark.circle.fill" : "circle")
                .foregroundColor(capturedPhoto != nil ? .green : .gray)
            
            // Requirement details
            VStack(alignment: .leading, spacing: 4) {
                Text(requirement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(requirement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if let angle = requirement.angle {
                    Label(angle, systemImage: "camera.viewfinder")
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Action button
            if let photo = capturedPhoto {
                Button(action: { onView(photo) }) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Button(action: onCapture) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CompliancePhotoCaptureView: View {
    let requirement: PhotoRequirement
    let buildingId: String
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Placeholder - would show camera interface
        Text("Camera capture for: \(requirement.title)")
            .onAppear {
                // Simulate photo capture
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Create mock image
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
                    let image = renderer.image { context in
                        UIColor.systemBlue.setFill()
                        context.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
                    }
                    onCapture(image)
                    dismiss()
                }
            }
    }
}

// MARK: - Sheet Views

struct ComplianceDetailSheet: View {
    let buildingId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Compliance score overview
                    ComplianceScoreOverview(buildingId: buildingId)
                    
                    // Compliance by category
                    ComplianceCategoryBreakdown(buildingId: buildingId)
                    
                    // Recent activity
                    RecentComplianceActivity(buildingId: buildingId)
                    
                    // Action items
                    ComplianceActionItems(buildingId: buildingId)
                }
                .padding()
            }
            .navigationTitle("Compliance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ComplianceScoreOverview: View {
    let buildingId: String
    
    var body: some View {
        // Implementation details
        Text("Compliance Score Overview")
    }
}

struct ComplianceCategoryBreakdown: View {
    let buildingId: String
    
    var body: some View {
        // Implementation details
        Text("Category Breakdown")
    }
}

struct RecentComplianceActivity: View {
    let buildingId: String
    
    var body: some View {
        // Implementation details
        Text("Recent Activity")
    }
}

struct ComplianceActionItems: View {
    let buildingId: String
    
    var body: some View {
        // Implementation details
        Text("Action Items")
    }
}

struct ViolationDetailsSheet: View {
    let violations: [ComplianceViolation]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(violations) { violation in
                ViolationDetailRow(violation: violation)
            }
            .navigationTitle("Active Violations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ViolationDetailRow: View {
    let violation: ComplianceViolation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(violation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ComplianceSeverityBadge(severity: violation.severity)
            }
            
            Text(violation.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Label(violation.dateIssued.formatted(date: .abbreviated, time: .omitted), 
                      systemImage: "calendar")
                    .font(.caption2)
                
                if let due = violation.resolutionDueDate {
                    Text("•")
                    Label("Due \(due.formatted(date: .abbreviated, time: .omitted))", 
                          systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                if let fine = violation.fineAmount {
                    Text("•")
                    Text("$\(fine)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ComplianceSeverityBadge: View {
    let severity: CoreTypes.ComplianceSeverity
    
    var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(severityColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(severityColor.opacity(0.2))
            .cornerRadius(4)
    }
    
    private var severityColor: Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct AddComplianceItemSheet: View {
    let buildingId: String
    let type: ComplianceChecklistView.ComplianceChecklistType
    let onSave: (ComplianceChecklistItem) -> Void
    
    @State private var title = ""
    @State private var category = "general"
    @State private var isRequired = true
    @State private var photoRequired = false
    @State private var dueTime = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $category) {
                        Text("General").tag("general")
                        Text("Safety").tag("safety")
                        Text("Sanitation").tag("sanitation")
                        Text("Environmental").tag("environmental")
                    }
                    
                    Toggle("Required", isOn: $isRequired)
                    Toggle("Photo Required", isOn: $photoRequired)
                    
                    TextField("Due Time (optional)", text: $dueTime)
                }
            }
            .navigationTitle("Add Checklist Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let item = ComplianceChecklistItem(
                            id: UUID().uuidString,
                            title: title,
                            category: category,
                            isCompleted: false,
                            isRequired: isRequired,
                            dueTime: dueTime.isEmpty ? nil : dueTime,
                            photoRequired: photoRequired
                        )
                        onSave(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct DocumentUploadSheet: View {
    let buildingId: String
    let onUpload: (ComplianceDocument) -> Void
    
    @State private var documentTitle = ""
    @State private var category = "certificates"
    @State private var expiryDate: Date?
    @State private var hasExpiry = false
    @State private var selectedDocument: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Information")) {
                    TextField("Document Title", text: $documentTitle)
                    
                    Picker("Category", selection: $category) {
                        Text("Certificate").tag("certificates")
                        Text("Permit").tag("permits")
                        Text("Inspection").tag("inspections")
                        Text("Policy").tag("policies")
                    }
                    
                    Toggle("Has Expiry Date", isOn: $hasExpiry)
                    
                    if hasExpiry {
                        DatePicker("Expiry Date", 
                                 selection: Binding(
                                    get: { expiryDate ?? Date() },
                                    set: { expiryDate = $0 }
                                 ),
                                 displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Upload Document")) {
                    Button(action: selectDocument) {
                        HStack {
                            Image(systemName: selectedDocument != nil ? "doc.badge.checkmark" : "doc.badge.plus")
                            Text(selectedDocument != nil ? "Document Selected" : "Select Document")
                        }
                    }
                }
            }
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload") {
                        uploadDocument()
                    }
                    .fontWeight(.semibold)
                    .disabled(documentTitle.isEmpty || selectedDocument == nil)
                }
            }
        }
    }
    
    private func selectDocument() {
        // Document picker implementation
    }
    
    private func uploadDocument() {
        let document = ComplianceDocument(
            id: UUID().uuidString,
            title: documentTitle,
            category: category,
            type: "PDF", // Determine from file
            uploadDate: Date(),
            expiryDate: hasExpiry ? expiryDate : nil,
            fileSize: 1024 * 500, // Mock size
            uploadedBy: "Current User"
        )
        onUpload(document)
        dismiss()
    }
}

struct ScheduleInspectionSheet: View {
    let buildingId: String
    let onSchedule: (ScheduledInspection) -> Void
    
    @State private var inspectionType = ""
    @State private var date = Date()
    @State private var inspector = ""
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Inspection Details")) {
                    TextField("Inspection Type", text: $inspectionType)
                    
                    DatePicker("Date & Time", selection: $date)
                    
                    TextField("Inspector/Agency", text: $inspector)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Schedule Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        let inspection = ScheduledInspection(
                            id: UUID().uuidString,
                            type: inspectionType,
                            date: date,
                            inspector: inspector.isEmpty ? nil : inspector,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onSchedule(inspection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(inspectionType.isEmpty)
                }
            }
        }
    }
}

struct DSNYScheduleDetailSheet: View {
    let buildingId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Full DSNY schedule details
                    Text("DSNY Schedule Details")
                        .font(.headline)
                    
                    // Collection calendar
                    // Compliance requirements
                    // Contact information
                    // Violation history
                }
                .padding()
            }
            .navigationTitle("DSNY Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Data Models

struct LocalBuildingComplianceData {
    let complianceScore: Int
    let safetyStatus: CoreTypes.ComplianceStatus
    let sanitationStatus: CoreTypes.ComplianceStatus
    let environmentalStatus: CoreTypes.ComplianceStatus
    let criticalIssues: Int
    let nextInspection: ScheduledInspection?
}

struct ComplianceChecklistItem: Identifiable {
    let id: String
    let title: String
    let category: String
    var isCompleted: Bool
    let isRequired: Bool
    let dueTime: String?
    let photoRequired: Bool
    var completedBy: String?
    var completedAt: Date?
    var notes: String?
}

struct ComplianceViolation: Identifiable {
    let id: String
    let title: String
    let description: String
    let severity: CoreTypes.ComplianceSeverity
    let dateIssued: Date
    let resolutionDueDate: Date?
    let fineAmount: Int?
    let status: String
}

struct ComplianceDocument: Identifiable {
    let id: String
    let title: String
    let category: String
    let type: String
    let uploadDate: Date
    let expiryDate: Date?
    let fileSize: Int?
    let uploadedBy: String
}

struct ScheduledInspection: Identifiable {
    let id: String
    let type: String
    let date: Date
    let inspector: String?
    let notes: String?
}

struct GeneratedReport {
    let id: String
    let type: String
    let generatedAt: Date
    let fileSize: Int?
    let pages: Int
}

struct DSNYComplianceData {
    let currentStatus: DSNYComplianceStatus
    let collectionSchedule: DSNYSchedule
    let setOutTime: String
    let collectionWindow: String
    let lastCollection: Date?
    let nextCollection: Date?
    let complianceChecklist: [DSNYChecklistItem]
    let recentViolations: [DSNYViolation]
}

struct DSNYSchedule {
    let days: [String]
    let recycleDays: [String]
    let organicsDays: [String]
}

struct DSNYChecklistItem: Identifiable {
    let id: String
    let title: String
    var isCompleted: Bool
    let isRequired: Bool
}

struct DSNYViolation: Identifiable {
    let id: String
    let description: String
    let date: Date
    let fineAmount: Int?
}

enum DSNYComplianceStatus: String {
    case compliant = "Compliant"
    case warning = "Warning"
    case violation = "Violation"
}

struct PhotoRequirement: Identifiable {
    let id: String
    let title: String
    let description: String
    let angle: String?
}
