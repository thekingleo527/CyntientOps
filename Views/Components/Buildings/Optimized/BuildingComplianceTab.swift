//
//  BuildingComplianceTab.swift
//  CyntientOps
//
//  ⚖️ COMPLIANCE FOCUSED: NYC regulations and violations
//  🚀 PERFORMANCE: Cached data with smart refresh
//

import SwiftUI

@MainActor
struct BuildingComplianceTab: View {
    let building: CoreTypes.NamedCoordinate
    let container: ServiceContainer
    
    @State private var complianceData: ComplianceData?
    @State private var isLoading = true
    @State private var lastRefresh = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading compliance data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let data = complianceData {
                    complianceContent(data)
                } else {
                    errorState
                }
            }
            .navigationTitle("Compliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task { await refreshCompliance() }
                    }
                }
            }
        }
        .task {
            await loadComplianceData()
        }
    }
    
    @ViewBuilder
    private func complianceContent(_ data: ComplianceData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                complianceOverview(data)
                violationsList(data)
                upcomingDeadlines(data)
            }
            .padding()
        }
        .refreshable {
            await refreshCompliance()
        }
    }
    
    @ViewBuilder
    private func complianceOverview(_ data: ComplianceData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compliance Overview")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ComplianceStatusCard(
                    title: "LL97 Emissions",
                    status: data.ll97Status,
                    dueDate: data.ll97NextDue
                )
                
                ComplianceStatusCard(
                    title: "LL11 Facade",
                    status: data.ll11Status,
                    dueDate: data.ll11NextDue
                )
                
                ComplianceStatusCard(
                    title: "Active Violations",
                    status: data.activeViolations == 0 ? "compliant" : "violations",
                    subtitle: "\(data.activeViolations) open"
                )
                
                ComplianceStatusCard(
                    title: "HPD Violations",
                    status: data.hpdViolations == 0 ? "compliant" : "violations",
                    subtitle: "\(data.hpdViolations) active"
                )
            }
        }
    }
    
    @ViewBuilder
    private func violationsList(_ data: ComplianceData) -> some View {
        if !data.violations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Violations")
                    .font(.headline)
                
                ForEach(data.violations.prefix(5), id: \.id) { violation in
                    ViolationRow(violation: violation)
                }
                
                if data.violations.count > 5 {
                    NavigationLink("View All Violations (\(data.violations.count))") {
                        ViolationsListView(
                            buildingId: building.id,
                            container: container
                        )
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private func upcomingDeadlines(_ data: ComplianceData) -> some View {
        if !data.upcomingDeadlines.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming Deadlines")
                    .font(.headline)
                
                ForEach(data.upcomingDeadlines.prefix(3), id: \.requirement) { deadline in
                    DeadlineRow(deadline: deadline)
                }
            }
        }
    }
    
    @ViewBuilder
    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to Load Compliance Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Check your connection and try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                Task { await refreshCompliance() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadComplianceData() async {
        await refreshCompliance()
    }
    
    private func refreshCompliance() async {
        isLoading = true
        
        do {
            // Load violations
            let violationRows = try await container.database.query("""
                SELECT v.id, v.violation_type, v.issue_date, v.department, 
                       v.description, v.fine_amount, v.status
                FROM violations v
                WHERE v.building_id = ? AND v.status = 'open'
                ORDER BY v.issue_date DESC
                LIMIT 20
            """, [building.id])
            
            let violations = violationRows.compactMap { row -> ComplianceViolation? in
                guard let id = row["id"] as? String,
                      let type = row["violation_type"] as? String else { return nil }
                
                return ComplianceViolation(
                    id: id,
                    type: type,
                    department: row["department"] as? String ?? "Unknown",
                    issueDate: parseDate(row["issue_date"]) ?? Date(),
                    description: row["description"] as? String,
                    fineAmount: row["fine_amount"] as? Double ?? 0.0,
                    status: row["status"] as? String ?? "open"
                )
            }
            
            // Load compliance status from NYC API cache
            let ll97Status = await container.nycCompliance.getLL97Status(for: building.id)
            let ll11Status = await container.nycCompliance.getLL11Status(for: building.id)
            
            let data = ComplianceData(
                ll97Status: ll97Status.isCompliant ? "compliant" : "pending",
                ll97NextDue: ll97Status.nextDueDate,
                ll11Status: ll11Status.isCompliant ? "compliant" : "pending", 
                ll11NextDue: ll11Status.nextDueDate,
                activeViolations: violations.count,
                hpdViolations: violations.filter { $0.department.lowercased().contains("hpd") }.count,
                violations: violations,
                upcomingDeadlines: generateUpcomingDeadlines()
            )
            
            await MainActor.run {
                self.complianceData = data
                self.isLoading = false
                self.lastRefresh = Date()
            }
        } catch {
            await MainActor.run {
                self.complianceData = nil
                self.isLoading = false
            }
        }
    }
    
    private func generateUpcomingDeadlines() -> [ComplianceDeadline] {
        // Generate sample deadlines - would be calculated from real compliance data
        [
            ComplianceDeadline(
                requirement: "LL97 Energy Report",
                dueDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
                priority: "high"
            ),
            ComplianceDeadline(
                requirement: "Facade Inspection",
                dueDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
                priority: "medium"
            )
        ]
    }
    
    private func parseDate(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

private struct ComplianceData {
    let ll97Status: String
    let ll97NextDue: Date?
    let ll11Status: String
    let ll11NextDue: Date?
    let activeViolations: Int
    let hpdViolations: Int
    let violations: [ComplianceViolation]
    let upcomingDeadlines: [ComplianceDeadline]
}

private struct ComplianceViolation {
    let id: String
    let type: String
    let department: String
    let issueDate: Date
    let description: String?
    let fineAmount: Double
    let status: String
}

private struct ComplianceDeadline {
    let requirement: String
    let dueDate: Date
    let priority: String
}

private struct ComplianceStatusCard: View {
    let title: String
    let status: String
    let dueDate: Date?
    let subtitle: String?
    
    init(title: String, status: String, dueDate: Date? = nil, subtitle: String? = nil) {
        self.title = title
        self.status = status
        self.dueDate = dueDate
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            StatusIndicator(status: status)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if let dueDate = dueDate {
                Text(dueDate.formatted(.dateTime.month().day()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatusIndicator: View {
    let status: String
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay(
                Text(status == "compliant" ? "✓" : "!")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "compliant":
            return .green
        case "violations", "pending":
            return .red
        default:
            return .orange
        }
    }
}

private struct ViolationRow: View {
    let violation: ComplianceViolation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(violation.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(violation.department)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            
            if let description = violation.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text(violation.issueDate.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if violation.fineAmount > 0 {
                    Text("$\(Int(violation.fineAmount))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

private struct DeadlineRow: View {
    let deadline: ComplianceDeadline
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.requirement)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(deadline.dueDate.formatted(.dateTime.weekday().month().day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            PriorityBadge(priority: deadline.priority)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PriorityBadge: View {
    let priority: String
    
    var body: some View {
        Text(priority.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch priority.lowercased() {
        case "high":
            return .red
        case "medium":
            return .orange
        case "low":
            return .green
        default:
            return .gray
        }
    }
}

// Placeholder for full violations list
private struct ViolationsListView: View {
    let buildingId: String
    let container: ServiceContainer
    
    var body: some View {
        Text("Full violations list for building \(buildingId)")
            .navigationTitle("All Violations")
            .navigationBarTitleDisplayMode(.inline)
    }
}