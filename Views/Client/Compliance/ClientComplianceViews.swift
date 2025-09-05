import SwiftUI

struct ClientHPDComplianceView: View {
    let violations: [String: [HPDViolation]]
    let buildings: [CoreTypes.NamedCoordinate]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ComplianceSummaryCard(title: "HPD Housing Violations", totalCount: total, activeCount: active, icon: "building.fill", color: .orange)
                ForEach(buildings, id: \.id) { b in
                    if let v = violations[b.id], !v.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(b.name).font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            ForEach(v, id: \.violationId) { HPDViolationRow(violation: $0) }
                        }.padding().cyntientOpsDarkCardBackground()
                    }
                }
            }.padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Back") { dismiss() }.foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary) } }
    }
    private var total: Int { violations.values.flatMap { $0 }.count }
    private var active: Int { violations.values.flatMap { $0 }.filter { $0.isActive }.count }
}

struct ClientDOBComplianceView: View {
    let permits: [String: [DOBPermit]]
    let buildings: [CoreTypes.NamedCoordinate]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ComplianceSummaryCard(title: "DOB Permits & Inspections", totalCount: total, activeCount: expired, icon: "hammer.fill", color: .blue)
                ForEach(buildings, id: \.id) { b in
                    if let p = permits[b.id], !p.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(b.name).font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            ForEach(p, id: \.jobNumber) { DOBPermitRow(permit: $0) }
                        }.padding().cyntientOpsDarkCardBackground()
                    }
                }
            }.padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Back") { dismiss() }.foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary) } }
    }
    private var total: Int { permits.values.flatMap { $0 }.count }
    private var expired: Int { permits.values.flatMap { $0 }.filter { $0.isExpired }.count }
}

struct ClientDSNYComplianceView: View {
    let schedules: [String: [DSNYRoute]]
    let violations: [String: [DSNYViolation]]
    let buildings: [CoreTypes.NamedCoordinate]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ComplianceSummaryCard(
                    title: "DSNY Sanitation",
                    totalCount: totalViolations,
                    activeCount: activeViolations,
                    icon: "trash.fill",
                    color: .green
                )
                dsnyViolationsSummary
                dsnySchedulesSection
            }
            .padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Back") { dismiss() }.foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary) } }
    }
    private var totalViolations: Int { violations.values.flatMap { $0 }.count }
    private var activeViolations: Int { violations.values.flatMap { $0 }.filter { $0.isActive }.count }
    private var dsnyViolationsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sanitation Violations").font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            ForEach(buildings, id: \.id) { b in
                if let v = violations[b.id], !v.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(b.name).font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        ForEach(v.prefix(5)) { DSNYViolationRow(violation: $0) }
                        if v.count > 5 { Text("+ \(v.count - 5) more violations").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText).padding(.top, 4) }
                    }.padding().cyntientOpsDarkCardBackground()
                }
            }
        }
    }
    private var dsnySchedulesSection: some View {
        Group {
            if !schedules.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection Schedules").font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    ForEach(buildings, id: \CoreTypes.NamedCoordinate.id) { b in
                        if let s = schedules[b.id], !s.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(b.name).font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                ForEach(Array(s.prefix(2)), id: \.id) { sched in
                                    DSNYScheduleRowInline(
                                        day: sched.dayOfWeek,
                                        time: sched.time, 
                                        items: sched.serviceType,
                                        isToday: sched.isToday
                                    )
                                }
                            }
                        }
                    }
                }.padding().cyntientOpsDarkCardBackground()
            }
        }
    }
}

struct ClientLL97ComplianceView: View {
    let emissions: [String: [LL97Emission]]
    let buildings: [CoreTypes.NamedCoordinate]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ComplianceSummaryCard(title: "Local Law 97 Emissions", totalCount: total, activeCount: noncomp, icon: "leaf.fill", color: .cyan)
                ForEach(buildings, id: \.id) { b in
                    if let e = emissions[b.id], !e.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(b.name).font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            ForEach(e, id: \.id) { LL97EmissionRow(emission: $0) }
                        }.padding().cyntientOpsDarkCardBackground()
                    }
                }
            }.padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Back") { dismiss() }.foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary) } }
    }
    private var total: Int { emissions.values.flatMap { $0 }.count }
    private var noncomp: Int { emissions.values.flatMap { $0 }.filter { !$0.isCompliant }.count }
}

// Shared compliance UI components
struct ComplianceSummaryCard: View {
    let title: String; let totalCount: Int; let activeCount: Int; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.title).foregroundColor(color).frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) { Text("\(totalCount)").font(.title2).fontWeight(.bold).foregroundColor(color); Text("Total").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText) }
                    VStack(alignment: .leading, spacing: 2) { Text("\(activeCount)").font(.title2).fontWeight(.bold).foregroundColor(activeCount > 0 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success); Text("Active").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText) }
                }
            }
            Spacer()
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

struct HPDViolationRow: View { let violation: HPDViolation
    var body: some View { HStack(spacing: 12) { Circle().fill(violation.isActive ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success).frame(width: 8, height: 8); VStack(alignment: .leading, spacing: 2) { Text(violation.novDescription).font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText); Text("Violation #\(violation.violationId)").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText) }; Spacer(); Text(violation.isActive ? "Active" : "Resolved").font(.caption).fontWeight(.medium).foregroundColor(violation.isActive ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success).padding(.horizontal, 8).padding(.vertical, 4).background((violation.isActive ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success).opacity(0.2)).cornerRadius(6) }.padding(.vertical, 4) }
}

struct DOBPermitRow: View { let permit: DOBPermit
    var body: some View { HStack(spacing: 12) { Circle().fill(permit.isExpired ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).frame(width: 8, height: 8); VStack(alignment: .leading, spacing: 2) { Text(permit.permitType ?? permit.workType).font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText); Text("Job #\(permit.jobNumber)").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText) }; Spacer(); Text(permit.isExpired ? "Expired" : "Valid").font(.caption).fontWeight(.medium).foregroundColor(permit.isExpired ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).padding(.horizontal, 8).padding(.vertical, 4).background((permit.isExpired ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).opacity(0.2)).cornerRadius(6) }.padding(.vertical, 4) }
}

struct DSNYViolationRow: View { let violation: DSNYViolation
    var body: some View { HStack(spacing: 12) { Circle().fill(violation.isActive ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).frame(width: 8, height: 8); VStack(alignment: .leading, spacing: 2) { Text(violation.violationType).font(.subheadline).fontWeight(.medium).foregroundColor(violation.isActive ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.primaryText); Text("Issued: \(violation.issueDate)").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText); if let details = violation.violationDetails { Text(details).font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText).lineLimit(1) } }; Spacer(); VStack(alignment: .trailing, spacing: 2) { if let fine = violation.fineAmount { Text("$\(Int(fine))").font(.caption).fontWeight(.bold).foregroundColor(CyntientOpsDesign.DashboardColors.critical) }; Text(violation.status.uppercased()).font(.caption).fontWeight(.medium).foregroundColor(violation.isActive ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success) } }.padding(.vertical, 4) }
}

struct LL97EmissionRow: View { let emission: LL97Emission
    var body: some View { HStack(spacing: 12) { Circle().fill(emission.isCompliant ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning).frame(width: 8, height: 8); VStack(alignment: .leading, spacing: 2) { Text("Carbon Emissions Report").font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText); Text("Report \(emission.reportingYear)").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText) }; Spacer(); Text(emission.isCompliant ? "Compliant" : "Review Needed").font(.caption).fontWeight(.medium).foregroundColor(emission.isCompliant ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning).padding(.horizontal, 8).padding(.vertical, 4).background((emission.isCompliant ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning).opacity(0.2)).cornerRadius(6) }.padding(.vertical, 4) }
}

struct DSNYScheduleRowInline: View {
    let day: String
    let time: String
    let items: String
    let isToday: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day)
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isToday ? CyntientOpsDesign.DashboardColors.secondaryAction : CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(items)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                if isToday {
                    Text("Today")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryAction)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(CyntientOpsDesign.DashboardColors.secondaryAction.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.8) : CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.4))
        )
    }
}
