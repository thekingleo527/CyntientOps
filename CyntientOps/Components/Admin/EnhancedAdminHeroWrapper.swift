//
//  EnhancedAdminHeroWrapper.swift
//  CyntientOps v6.0
//
//  🎯 ENHANCED ADMIN HERO CARD WITH OPERATIONAL INTELLIGENCE
//  ✅ Operational metrics integration (routine completion, vendor access)
//  ✅ Smart routing to intelligence panel tabs
//  ✅ Real-time operational status tracking
//  ✅ Collapsible design for space management
//  ✅ Pressing tasks preview with smart navigation
//

import SwiftUI

struct EnhancedAdminHeroWrapper: View {
    // MARK: - Binding Properties
    @Binding var isCollapsed: Bool
    
    // MARK: - Data Properties
    let portfolio: CoreTypes.PortfolioMetrics
    let activeWorkers: [CoreTypes.WorkerProfile]
    let pressingTasks: [CoreTypes.ContextualTask]
    let operationalMetrics: AdminOperationalMetrics?
    
    // MARK: - Callback Properties
    let onWorkersTap: () -> Void
    let onTasksTap: () -> Void
    let onPortfolioTap: () -> Void
    let onComplianceTap: () -> Void
    let onAnalyticsTap: () -> Void
    
    // MARK: - Private State
    @State private var showingDetails = false
    @State private var selectedMetric: MetricType?
    
    // MARK: - Supporting Types
    enum MetricType: String, CaseIterable {
        case workers = "Workers"
        case tasks = "Tasks"
        case routines = "Routines"
        case compliance = "Compliance"
        case vendors = "Vendors"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                CollapsedHeroView()
            } else {
                ExpandedHeroView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
        .background(
            HeroBackgroundGradient()
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Collapsed Hero View
    private func CollapsedHeroView() -> some View {
        HStack(spacing: 16) {
            // Quick Status Indicator
            VStack(alignment: .leading, spacing: 4) {
                Text("Admin Overview")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let opMetrics = operationalMetrics {
                    Text(opMetrics.operationalEfficiency.rawValue)
                        .font(.caption)
                        .foregroundColor(opMetrics.operationalEfficiency.color)
                } else {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Quick Metrics Row
            HStack(spacing: 12) {
                QuickMetricBubble(
                    value: "\(activeWorkers.count)",
                    label: "Active",
                    color: .blue,
                    action: onWorkersTap
                )
                
                QuickMetricBubble(
                    value: "\(pressingTasks.count)",
                    label: "Urgent",
                    color: pressingTasks.count > 3 ? .red : .orange,
                    action: onTasksTap
                )
                
                if let opMetrics = operationalMetrics {
                    QuickMetricBubble(
                        value: opMetrics.completionPercentage,
                        label: "Complete",
                        color: opMetrics.operationalEfficiency.color,
                        action: onAnalyticsTap
                    )
                }
            }
            
            // Expand Button
            Button(action: { isCollapsed = false }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Expanded Hero View
    private func ExpandedHeroView() -> some View {
        VStack(spacing: 20) {
            // Header Section
            HeroHeaderSection()
            
            // Main Metrics Grid
            HeroMetricsGrid()
            
            // Pressing Tasks Preview
            if !pressingTasks.isEmpty {
                PressingTasksPreview()
            }
            
            // Operational Intelligence Summary
            if let opMetrics = operationalMetrics {
                OperationalIntelligenceSection(metrics: opMetrics)
            }
        }
        .padding(20)
    }
    
    // MARK: - Header Section
    private func HeroHeaderSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Admin Command Center")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let opMetrics = operationalMetrics {
                    HStack(spacing: 8) {
                        Image(systemName: opMetrics.operationalEfficiency == .excellent ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundColor(opMetrics.operationalEfficiency.color)
                        
                        Text(opMetrics.operationalEfficiency.rawValue)
                            .font(.subheadline)
                            .foregroundColor(opMetrics.operationalEfficiency.color)
                    }
                } else {
                    Text("Initializing operational intelligence...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Collapse Button
            Button(action: { isCollapsed = true }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Metrics Grid
    private func HeroMetricsGrid() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            // Workers Metric
            MetricCard(
                icon: "person.2.fill",
                title: "Active Workers",
                value: "\(activeWorkers.count)",
                subtitle: "of \(portfolio.totalBuildings) buildings",
                color: .blue,
                trend: nil,
                action: onWorkersTap
            )
            
            // Pressing Tasks Metric
            MetricCard(
                icon: "exclamationmark.triangle.fill",
                title: "Urgent Tasks",
                value: "\(pressingTasks.count)",
                subtitle: "require attention",
                color: pressingTasks.count > 3 ? .red : .orange,
                trend: nil,
                action: onTasksTap
            )
            
            // Portfolio Completion
            MetricCard(
                icon: "chart.pie.fill",
                title: "Portfolio",
                value: "\(Int(portfolio.overallCompletionRate * 100))%",
                subtitle: "completion rate",
                color: portfolio.overallCompletionRate > 0.8 ? .green : .orange,
                trend: .stable,
                action: onPortfolioTap
            )
            
            // Compliance Score
            MetricCard(
                icon: "shield.checkered",
                title: "Compliance",
                value: "\(Int(portfolio.complianceScore))%",
                subtitle: "score",
                color: portfolio.complianceScore > 80 ? .green : .orange,
                trend: portfolio.complianceScore > 85 ? .up : .stable,
                action: onComplianceTap
            )
            
            // Operational Intelligence
            if let opMetrics = operationalMetrics {
                MetricCard(
                    icon: "brain.head.profile",
                    title: "Routines",
                    value: opMetrics.completionPercentage,
                    subtitle: "completed today",
                    color: opMetrics.operationalEfficiency.color,
                    trend: opMetrics.routineCompletionRate > 0.9 ? .up : .stable,
                    action: onAnalyticsTap
                )
                
                MetricCard(
                    icon: "building.2.fill",
                    title: "Buildings",
                    value: "\(opMetrics.buildingsWithFullCompletion)",
                    subtitle: "fully complete",
                    color: .cyan,
                    trend: nil,
                    action: onPortfolioTap
                )
            }
        }
    }
    
    // MARK: - Pressing Tasks Preview
    private func PressingTasksPreview() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pressing Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    onTasksTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(pressingTasks.prefix(4)) { task in
                        PressingTaskCard(task: task) {
                            onTasksTap()
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Operational Intelligence Section
    private func OperationalIntelligenceSection(metrics: AdminOperationalMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Operations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Intelligence Panel") {
                    onAnalyticsTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                OperationalStat(
                    icon: "checkmark.circle.fill",
                    label: "Tasks Completed",
                    value: "\(metrics.completedTasksToday)",
                    color: .green
                )
                
                OperationalStat(
                    icon: "bell.fill",
                    label: "Reminders",
                    value: "\(metrics.pendingRemindersCount)",
                    color: metrics.criticalRemindersCount > 0 ? .red : .orange
                )
                
                OperationalStat(
                    icon: "person.badge.key.fill",
                    label: "Vendor Access",
                    value: "\(metrics.recentVendorAccessCount)",
                    color: .cyan
                )
                
                if metrics.criticalAlertsCount > 0 {
                    OperationalStat(
                        icon: "exclamationmark.triangle.fill",
                        label: "Alerts",
                        value: "\(metrics.criticalAlertsCount)",
                        color: .red
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct QuickMetricBubble: View {
    let value: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 48, height: 40)
            .background(color.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let trend: CoreTypes.TrendDirection?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let trend = trend {
                        Image(systemName: trendIcon(for: trend))
                            .font(.system(size: 12))
                            .foregroundColor(trendColor(for: trend))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func trendIcon(for trend: CoreTypes.TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    private func trendColor(for trend: CoreTypes.TrendDirection) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

struct PressingTaskCard: View {
    let task: CoreTypes.ContextualTask
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: urgencyIcon)
                        .font(.system(size: 14))
                        .foregroundColor(urgencyColor)
                    
                    Spacer()
                }
                
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let buildingName = task.buildingName {
                    Text(buildingName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(width: 120, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(urgencyColor.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(urgencyColor.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var urgencyIcon: String {
        switch task.urgency {
        case .critical, .emergency: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        default: return "clock.fill"
        }
    }
    
    private var urgencyColor: Color {
        switch task.urgency {
        case .critical, .emergency: return .red
        case .high: return .orange
        default: return .blue
        }
    }
}

struct OperationalStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HeroBackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.08),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview
#if DEBUG
struct EnhancedAdminHeroWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let mockPortfolio = CoreTypes.PortfolioMetrics(
            totalBuildings: 18,
            activeWorkers: 7,
            overallCompletionRate: 0.87,
            criticalIssues: 2,
            complianceScore: 92.0
        )
        
        let mockWorkers = [
            CoreTypes.WorkerProfile(id: "1", name: "John Doe", email: "john@example.com", role: "worker", isActive: true),
            CoreTypes.WorkerProfile(id: "2", name: "Jane Smith", email: "jane@example.com", role: "worker", isActive: true)
        ]
        
        let mockTasks = [
            CoreTypes.ContextualTask(id: "1", title: "Bin Retrieval Overdue", description: "Bins not retrieved from curbside", status: .pending, urgency: .high, buildingName: "123 Main St"),
            CoreTypes.ContextualTask(id: "2", title: "DSNY Bin Placement", description: "Place bins for collection", status: .pending, urgency: .critical, buildingName: "456 Oak Ave")
        ]
        
        let mockOpMetrics = AdminOperationalMetrics(
            totalBuildingsTracked: 18,
            routineCompletionRate: 0.87,
            completedTasksToday: 124,
            pendingRemindersCount: 5,
            criticalRemindersCount: 2,
            recentVendorAccessCount: 3,
            criticalAlertsCount: 1,
            buildingsWithFullCompletion: 12
        )
        
        EnhancedAdminHeroWrapper(
            isCollapsed: .constant(false),
            portfolio: mockPortfolio,
            activeWorkers: mockWorkers,
            pressingTasks: mockTasks,
            operationalMetrics: mockOpMetrics,
            onWorkersTap: {},
            onTasksTap: {},
            onPortfolioTap: {},
            onComplianceTap: {},
            onAnalyticsTap: {}
        )
        .frame(height: 400)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif