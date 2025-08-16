import SwiftUI

struct ClientCriticalAlertsSheet: View {
    let alerts: [CoreTypes.CriticalAlert]
    let workers: [CoreTypes.WorkerSummary]
    let container: ServiceContainer
    
    @State private var selectedSeverity: CoreTypes.AlertSeverity = .low
    @State private var selectedType: CoreTypes.AlertType = .all
    @State private var resolvedAlerts: Set<String> = []
    
    var filteredAlerts: [CoreTypes.CriticalAlert] {
        alerts.filter { alert in
            (selectedType == .all || alert.type == selectedType)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Alert Summary Header
                alertSummarySection
                
                // Filter Controls
                alertFiltersSection
                
                // Critical Alerts List
                alertsListSection
                
                // Response Actions
                responseActionsSection
                
                // Alert Analytics
                alertAnalyticsSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private var alertSummarySection: some View {
        VStack(spacing: 12) {
            Text("Critical Operations Alerts")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                AlertSummaryCard(
                    title: "Critical", 
                    count: alerts.filter { $0.severity == .critical }.count,
                    color: .red
                )
                
                AlertSummaryCard(
                    title: "High", 
                    count: alerts.filter { $0.severity == .high }.count,
                    color: .orange
                )
                
                AlertSummaryCard(
                    title: "Medium", 
                    count: alerts.filter { $0.severity == .medium }.count,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var alertFiltersSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filters")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Severity Filter
                Picker("Severity", selection: $selectedSeverity) {
                    ForEach(CoreTypes.AlertSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(severity)
                    }
                }
                .pickerStyle(.menu)
                
                // Type Filter
                Picker("Type", selection: $selectedType) {
                    ForEach(CoreTypes.AlertType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var alertsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Alerts (\(filteredAlerts.count))")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(filteredAlerts, id: \.id) { alert in
                CriticalAlertCard(
                    alert: alert,
                    isResolved: resolvedAlerts.contains(alert.id),
                    onResolve: { resolveAlert(alert.id) },
                    onAssignWorker: { assignWorkerToAlert(alert) }
                )
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var responseActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Response")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Button("Dispatch All Workers") {
                    // Dispatch workers to handle critical alerts
                }
                .buttonStyle(.borderedProminent)
                .disabled(filteredAlerts.isEmpty)
                
                Button("Generate Response Plan") {
                    // Generate AI response plan
                }
                .buttonStyle(.bordered)
                .disabled(filteredAlerts.isEmpty)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var alertAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alert Analytics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Response Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("12 min avg")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading) {
                    Text("Resolution Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("94%")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("Escalated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("2")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func resolveAlert(_ alertId: String) {
        resolvedAlerts.insert(alertId)
        // Update OperationalDataManager
    }
    
    private func assignWorkerToAlert(_ alert: CoreTypes.CriticalAlert) {
        // Find best available worker and assign to alert
        let availableWorkers = workers.filter { $0.isActive }
        // Implementation would assign worker to handle alert
    }
}

// MARK: - Supporting Components

struct AlertSummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CriticalAlertCard: View {
    let alert: CoreTypes.CriticalAlert
    let isResolved: Bool
    let onResolve: () -> Void
    let onAssignWorker: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: getSeverityIcon(alert.severity))
                    .foregroundColor(getSeverityColor(alert.severity))
                
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let buildingId = alert.buildingId {
                Text("Location: Building \(buildingId)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 8) {
                Button(isResolved ? "Resolved" : "Resolve") {
                    if !isResolved { onResolve() }
                }
                .font(.caption)
                .foregroundColor(isResolved ? .green : .white)
                .disabled(isResolved)
                
                Button("Assign Worker") {
                    onAssignWorker()
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
        }
        .padding()
        .background(isResolved ? 
                   CyntientOpsDesign.DashboardColors.success.opacity(0.1) :
                   CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isResolved ? 0.6 : 1.0)
    }
    
    private func getSeverityIcon(_ severity: CoreTypes.AlertSeverity) -> String {
        switch severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "info.circle"
        case .all: return "info.circle"
        }
    }
    
    private func getSeverityColor(_ severity: CoreTypes.AlertSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .all: return .gray
        }
    }
}