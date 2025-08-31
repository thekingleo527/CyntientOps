//
//  AdminComplianceOverviewView.swift
//  CyntientOps v6.0
//
//  Comprehensive compliance management for administrators
//  Shows violations, inspection schedules, and compliance scoring
//

import SwiftUI

struct AdminComplianceOverviewView: View {
    @EnvironmentObject private var container: ServiceContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: ComplianceTab = .overview
    @State private var searchText = ""
    @State private var showingViolationDetail = false
    @State private var selectedViolation: CoreTypes.ComplianceViolation?
    
    enum ComplianceTab: String, CaseIterable {
        case overview = "Overview"
        case violations = "Violations"
        case inspections = "Inspections"
        case reports = "Reports"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .violations: return "exclamationmark.triangle.fill"
            case .inspections: return "calendar"
            case .reports: return "doc.text"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Bar
                tabBarView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .violations:
                            violationsContent
                        case .inspections:
                            inspectionsContent
                        case .reports:
                            reportsContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedViolation) { violation in
            ComplianceViolationDetailView(violation: violation)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Compliance Center")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { /* Export functionality */ }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }
    
    private var tabBarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(ComplianceTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.caption)
                                Text(tab.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    private var overviewContent: some View {
        VStack(spacing: 16) {
            // Compliance Score
            ComplianceScoreCard(score: 84.5)
            
            // Quick Stats
            HStack(spacing: 12) {
                ComplianceStatCard(
                    title: "Active Violations",
                    value: "3",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                ComplianceStatCard(
                    title: "Inspections Due",
                    value: "2",
                    color: .orange,
                    icon: "calendar"
                )
                
                ComplianceStatCard(
                    title: "Photo Compliance",
                    value: "92%",
                    color: .green,
                    icon: "camera.fill"
                )
            }
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ComplianceActivityRow(
                        icon: "checkmark.circle.fill",
                        title: "Inspection Completed",
                        subtitle: "123 1st Avenue - Score: 89%",
                        time: "2 hours ago",
                        color: .green
                    )
                    
                    ComplianceActivityRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Violation Reported",
                        subtitle: "68 Perry Street - Sanitation Issue",
                        time: "5 hours ago",
                        color: .red
                    )
                    
                    ComplianceActivityRow(
                        icon: "calendar",
                        title: "Inspection Scheduled",
                        subtitle: "104 Franklin Street - Tomorrow 2:00 PM",
                        time: "1 day ago",
                        color: .blue
                    )
                }
            }
        }
    }
    
    private var violationsContent: some View {
        VStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search violations...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            
            // Violations List
            VStack(spacing: 12) {
                ComplianceViolationCard(
                    violation: CoreTypes.ComplianceViolation(
                        id: "v1",
                        buildingId: "b1",
                        buildingName: "68 Perry Street",
                        violationType: "Sanitation",
                        severity: "High",
                        description: "Inadequate waste disposal procedures",
                        reportedDate: Date().addingTimeInterval(-86400 * 2),
                        status: "Open",
                        assignedWorker: "Maria Santos",
                        photoRequired: true
                    ),
                    onTap: { violation in
                        selectedViolation = violation
                        showingViolationDetail = true
                    }
                )
                
                ComplianceViolationCard(
                    violation: CoreTypes.ComplianceViolation(
                        id: "v2",
                        buildingId: "b2",
                        buildingName: "123 1st Avenue",
                        violationType: "Safety",
                        severity: "Medium",
                        description: "Missing safety signage in common areas",
                        reportedDate: Date().addingTimeInterval(-86400 * 5),
                        status: "In Progress",
                        assignedWorker: "Carlos Rodriguez",
                        photoRequired: true
                    ),
                    onTap: { violation in
                        selectedViolation = violation
                        showingViolationDetail = true
                    }
                )
            }
        }
    }
    
    private var inspectionsContent: some View {
        VStack(spacing: 16) {
            Text("Inspection Schedule")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Upcoming Inspections
            VStack(spacing: 12) {
                InspectionCard(
                    buildingName: "104 Franklin Street",
                    inspectionType: "Quarterly Review",
                    scheduledDate: Date().addingTimeInterval(86400),
                    inspector: "NYC Inspector Johnson",
                    status: "Scheduled"
                )
                
                InspectionCard(
                    buildingName: "131 Perry Street",
                    inspectionType: "Follow-up Inspection",
                    scheduledDate: Date().addingTimeInterval(86400 * 3),
                    inspector: "NYC Inspector Martinez",
                    status: "Scheduled"
                )
            }
        }
    }
    
    private var reportsContent: some View {
        VStack(spacing: 16) {
            Text("Compliance Reports")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ReportCard(
                    title: "Monthly Compliance Report",
                    subtitle: "January 2025",
                    icon: "doc.text.fill",
                    onTap: { /* Generate report */ }
                )
                
                ReportCard(
                    title: "Violation Summary",
                    subtitle: "Last 30 days",
                    icon: "chart.bar.fill",
                    onTap: { /* Generate report */ }
                )
                
                ReportCard(
                    title: "Photo Evidence Export",
                    subtitle: "All recent photos",
                    icon: "photo.stack.fill",
                    onTap: { /* Export photos */ }
                )
            }
        }
    }
}

// MARK: - Supporting Components

struct ComplianceScoreCard: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Overall Compliance Score")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("\(Int(score))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
            
            Text("Above Industry Average")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(scoreColor.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    private var scoreColor: Color {
        if score >= 90 { return .green }
        if score >= 70 { return .yellow }
        return .red
    }
}

struct ComplianceStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ComplianceActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

struct ComplianceViolationCard: View {
    let violation: CoreTypes.ComplianceViolation
    let onTap: (CoreTypes.ComplianceViolation) -> Void
    
    var body: some View {
        Button(action: { onTap(violation) }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(violation.violationType)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(violation.buildingName)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(violation.severity)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(severityColor)
                        
                        Text(violation.status)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Text(violation.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack {
                    Text("Assigned: \(violation.assignedWorker)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    if violation.photoRequired {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(severityColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch violation.severity.lowercased() {
        case "high", "critical": return .red
        case "medium": return .orange
        case "low": return .yellow
        default: return .gray
        }
    }
}

struct InspectionCard: View {
    let buildingName: String
    let inspectionType: String
    let scheduledDate: Date
    let inspector: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(buildingName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(scheduledDate.formatted(.dateTime.month().day()))
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Text(inspectionType)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            HStack {
                Text("Inspector: \(inspector)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(status)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ReportCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComplianceViolationDetailView: View {
    let violation: CoreTypes.ComplianceViolation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Violation Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Building: \(violation.buildingName)")
                        .foregroundColor(.white)
                    Text("Type: \(violation.violationType)")
                        .foregroundColor(.white)
                    Text("Severity: \(violation.severity)")
                        .foregroundColor(.red)
                    Text("Description: \(violation.description)")
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#if DEBUG
struct AdminComplianceOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        AdminComplianceOverviewView()
            .environmentObject(ServiceContainer())
            .preferredColorScheme(.dark)
    }
}
#endif