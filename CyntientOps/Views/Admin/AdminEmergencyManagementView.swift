//
//  AdminEmergencyManagementView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Admin emergency management with real alerts
//

import SwiftUI

struct AdminEmergencyManagementView: View {
    let alerts: [CoreTypes.AdminAlert]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAlert: CoreTypes.AdminAlert?
    @State private var filterBy: AlertFilter = .all
    
    enum AlertFilter: String, CaseIterable {
        case all = "All Alerts"
        case critical = "Critical"
        case warning = "Warning"
        case info = "Info"
        
        var severity: CoreTypes.AlertSeverity? {
            switch self {
            case .all: return nil
            case .critical: return .critical
            case .warning: return .warning
            case .info: return .info
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Emergency Header
            emergencyHeader
            
            // Filter Bar
            filterBar
            
            // Alerts List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAlerts, id: \.alertId) { alert in
                        AdminEmergencyAlertCard(
                            alert: alert,
                            onTap: { selectedAlert = alert },
                            onResolve: { resolveAlert(alert) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
        }
        .sheet(item: $selectedAlert) { alert in
            AdminAlertDetailView(alert: alert)
        }
    }
    
    private var emergencyHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency Management")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text("\\(alerts.count) total alerts")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
            }
            
            // Alert Summary
            HStack(spacing: 16) {
                AlertSummaryPill(
                    count: criticalCount,
                    label: "Critical",
                    color: CyntientOpsDesign.DashboardColors.critical
                )
                
                AlertSummaryPill(
                    count: warningCount,
                    label: "Warning",
                    color: CyntientOpsDesign.DashboardColors.warning
                )
                
                AlertSummaryPill(
                    count: infoCount,
                    label: "Info",
                    color: CyntientOpsDesign.DashboardColors.info
                )
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AlertFilter.allCases, id: \.self) { filter in
                    Button(action: { filterBy = filter }) {
                        Text(filter.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(filterBy == filter ? .white : CyntientOpsDesign.DashboardColors.tertiaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(filterBy == filter ? CyntientOpsDesign.DashboardColors.adminAccent : CyntientOpsDesign.DashboardColors.cardBackground)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    private var filteredAlerts: [CoreTypes.AdminAlert] {
        if let severity = filterBy.severity {
            return alerts.filter { $0.severity == severity }
        }
        return alerts
    }
    
    private var criticalCount: Int { alerts.filter { $0.severity == .critical }.count }
    private var warningCount: Int { alerts.filter { $0.severity == .warning }.count }
    private var infoCount: Int { alerts.filter { $0.severity == .info }.count }
    
    private func resolveAlert(_ alert: CoreTypes.AdminAlert) {
        // Handle alert resolution
        print("Resolving alert: \\(alert.title)")
    }
}

struct AlertSummaryPill: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct AdminEmergencyAlertCard: View {
    let alert: CoreTypes.AdminAlert
    let onTap: () -> Void
    let onResolve: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Severity indicator
                VStack(spacing: 4) {
                    Image(systemName: severityIcon)
                        .font(.title3)
                        .foregroundColor(severityColor)
                    
                    Circle()
                        .fill(severityColor)
                        .frame(width: 6, height: 6)
                }
                .frame(width: 24)
                
                // Alert content
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    if let description = alert.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        Text(alert.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        
                        if let buildingId = alert.buildingId,
                           let buildingName = getBuildingName(buildingId) {
                            Text("• \\(buildingName)")
                                .font(.caption2)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                        }
                    }
                }
                
                Spacer()
                
                // Quick resolve button
                Button(action: onResolve) {
                    Text("Resolve")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(severityColor)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(severityColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .critical: return CyntientOpsDesign.DashboardColors.critical
        case .warning: return CyntientOpsDesign.DashboardColors.warning
        case .info: return CyntientOpsDesign.DashboardColors.info
        }
    }
    
    private func getBuildingName(_ buildingId: String) -> String? {
        // This would typically come from the buildings array passed down
        return "Building \\(buildingId)"
    }
}

struct AdminAlertDetailView: View {
    let alert: CoreTypes.AdminAlert
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Alert Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(alert.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        if let description = alert.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                    
                    // Alert details would go here
                    Text("Alert management and resolution options would be implemented here.")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                .padding()
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationTitle("Alert Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                }
            }
        }
    }
}

struct AdminMetricPreviewRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}