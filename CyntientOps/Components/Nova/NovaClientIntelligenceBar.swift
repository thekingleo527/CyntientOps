//
//  NovaClientIntelligenceBar.swift
//  CyntientOps Phase 4
//
//  Nova Intelligence Bar for Client Dashboard
//  Provides AI-powered portfolio insights and cost optimization
//

import SwiftUI

struct NovaClientIntelligenceBar: View {
    let container: ServiceContainer
    let clientContext: [String: Any]
    @ObservedObject var viewModel: ClientDashboardViewModel
    
    @State private var isExpanded = false
    @State private var currentInsight: String = "Analyzing portfolio performance..."
    @State private var animationPhase = 0
    
    // Tab state management
    @State private var selectedTab: NovaTab = .priorities
    @State private var selectedPortfolioTab: PortfolioSubTab = .overview
    @State private var selectedComplianceTab: ComplianceSubTab = .overview
    
    @ObservedObject var novaManager: NovaAIManager
    
    // MARK: - Tab Enums
    enum NovaTab: String, CaseIterable {
        case priorities = "Priorities"
        case portfolio = "Portfolio" 
        case compliance = "Compliance"
        case chat = "Chat"
        
        var icon: String {
            switch self {
            case .priorities: return "exclamationmark.triangle"
            case .portfolio: return "building.columns.fill"
            case .compliance: return "checkmark.shield.fill"
            case .chat: return "brain.head.profile"
            }
        }
    }
    
    enum PortfolioSubTab: String, CaseIterable {
        case overview = "Overview"
        case financial = "Financial" 
        case performance = "Performance"
        
        var icon: String {
            switch self {
            case .overview: return "building.2.fill"
            case .financial: return "dollarsign.circle.fill"
            case .performance: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    enum ComplianceSubTab: String, CaseIterable {
        case overview = "Overview"
        case hpd = "HPD"
        case dob = "DOB" 
        case dsny = "DSNY"
        case ll97 = "LL97"
        
        var icon: String {
            switch self {
            case .overview: return "shield.checkerboard"
            case .hpd: return "house.fill"
            case .dob: return "hammer.fill"
            case .dsny: return "trash.fill"
            case .ll97: return "leaf.fill"
            }
        }
    }
    
    private let clientInsights = [
        "Portfolio performance up 8% this quarter",
        "Cost savings opportunity: $12K/month identified",
        "Compliance score excellent at 94%",
        "Building efficiency optimized across 9 properties",
        "Recommend energy audit for additional savings"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Client Content
                expandedClientContent
                    .frame(height: 280)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.95),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Collapsed Bar
            collapsedClientBar
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.purple.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.purple.opacity(0.3)),
                    alignment: .top
                )
        }
        .onAppear {
            startClientInsightRotation()
        }
    }
    
    private var collapsedClientBar: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Nova Client Icon - Use NovaAvatar
                NovaAvatar(
                    size: .small,
                    isActive: true,
                    hasUrgentInsights: false,
                    isBusy: novaManager.isThinking,
                    onTap: { },
                    onLongPress: { }
                )
                .frame(width: 36, height: 36)
                
                // Current Client Insight
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nova AI • Portfolio Intelligence")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    
                    Text(currentInsight)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.3), value: currentInsight)
                }
                
                Spacer()
                
                // Client-specific indicators
                HStack(spacing: 8) {
                    // Cost savings indicator
                    if let savings = clientContext["estimatedSavings"] as? Double, savings > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            
                            Text("$\(Int(savings/1000))K")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Portfolio health
                    if let health = clientContext["portfolioHealth"] as? Double {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            
                            Text("\(Int(health * 100))%")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var expandedClientContent: some View {
        VStack(spacing: 0) {
            // Intelligence Header with status
            intelligenceHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            // Main Nova tabs
            novaTabsRow
                .padding(.horizontal, 16)
            
            // Tab content
            tabContentView
                .frame(maxHeight: 200)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
    
    // MARK: - Intelligence Header
    private var intelligenceHeader: some View {
        HStack {
            // Time-based greeting + LIVE indicator
            VStack(alignment: .leading, spacing: 4) {
                Text(timeOfDayGreeting)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(1)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                                animationPhase += 1
                            }
                        }
                    
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Nova Avatar in header
            NovaAvatar(
                size: .small,
                isActive: true,
                hasUrgentInsights: false,
                isBusy: novaManager.isThinking,
                onTap: { },
                onLongPress: { }
            )
            .frame(width: 32, height: 32)
            
            Spacer()
            
            // Overall status pills
            HStack(spacing: 8) {
                if let portfolioHealth = clientContext["portfolioHealth"] as? Double {
                    NovaStatusPill(
                        text: portfolioHealthStatus(portfolioHealth),
                        color: portfolioHealthColor(portfolioHealth)
                    )
                }
                
                if let violations = clientContext["criticalViolations"] as? Int, violations > 0 {
                    NovaStatusPill(
                        text: "\(violations) issues",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Nova Tabs Row
    private var novaTabsRow: some View {
        HStack(spacing: 0) {
            ForEach(NovaTab.allCases, id: \.rawValue) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                            .foregroundColor(selectedTab == tab ? .purple : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ?
                            Color.purple.opacity(0.2) : Color.clear
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Tab Content View
    @ViewBuilder
    private var tabContentView: some View {
        ScrollView {
            switch selectedTab {
            case .priorities:
                prioritiesContent
            case .portfolio:
                portfolioContent
            case .compliance:
                complianceContent
            case .chat:
                chatContent
            }
        }
    }
    
    private func startClientInsightRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsight = clientInsights.randomElement() ?? clientInsights[0]
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Hello"
        }
    }
    
    private func portfolioHealthStatus(_ health: Double) -> String {
        if health > 0.8 { return "Excellent" }
        else if health > 0.7 { return "Good" }
        else if health > 0.6 { return "Fair" }
        else { return "Needs Attention" }
    }
    
    private func portfolioHealthColor(_ health: Double) -> Color {
        if health > 0.8 { return .green }
        else if health > 0.7 { return .blue }
        else if health > 0.6 { return .yellow }
        else { return .red }
    }
    
    private func priorityIcon(_ priority: CoreTypes.Priority) -> String {
        switch priority {
        case .low: return "circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.3"
        }
    }
    
    private func priorityColor(_ priority: CoreTypes.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    private func getStrategicRecommendations() -> [StrategicRecommendation] {
        return [
            StrategicRecommendation(
                title: "Energy Efficiency Audit",
                description: "Schedule LL87 compliance audit for 3 buildings",
                priority: .high
            ),
            StrategicRecommendation(
                title: "HPD Violation Resolution",
                description: "Address 2 Class B violations this month",
                priority: .medium
            )
        ]
    }
    
    // MARK: - Portfolio Content Views
    
    @ViewBuilder
    private var portfolioOverviewContent: some View {
        VStack(spacing: 8) {
            ForEach(getPreviewBuildings(), id: \.name) { building in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(building.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("$\(building.value, specifier: "%.0f")K")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(building.occupancy)%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(building.occupancy > 90 ? .green : .yellow)
                        
                        Text("occupied")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            }
        }
    }
    
    @ViewBuilder
    private var portfolioFinancialContent: some View {
        VStack(spacing: 8) {
            ForEach(getPreviewBuildings(), id: \.name) { building in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(building.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Tax: $\(building.taxAmount, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(building.value, specifier: "%.0f")K")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text("assessed")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            }
        }
    }
    
    @ViewBuilder
    private var portfolioPerformanceContent: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Portfolio ROI")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("8.2%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Efficiency Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("92/100")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
        }
    }
    
    // MARK: - Compliance Content Views
    
    @ViewBuilder
    private var complianceOverviewContent: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("94%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Active Issues")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("3")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
        }
    }
    
    @ViewBuilder
    private var hpdComplianceContent: some View {
        VStack(spacing: 6) {
            let activeViolations = viewModel.hpdViolationsData.values.flatMap { $0 }.filter { $0.isActive }
            let criticalViolations = activeViolations.filter { $0.severity == .critical }
            
            Text("Violations: \(activeViolations.count) active")
                .font(.caption2)
                .foregroundColor(activeViolations.isEmpty ? .green : .orange)
            
            if criticalViolations.count > 0 {
                Text("Critical: \(criticalViolations.count) urgent")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else {
                Text("Registration: Current")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private var dobComplianceContent: some View {
        VStack(spacing: 6) {
            let allPermits = viewModel.dobPermitsData.values.flatMap { $0 }
            let expiredPermits = allPermits.filter { $0.isExpired }
            let pendingPermits = allPermits.filter { $0.permitStatus.lowercased().contains("pending") }
            
            Text("Permits: \(allPermits.count) total")
                .font(.caption2)
                .foregroundColor(.green)
            
            if expiredPermits.count > 0 {
                Text("Expired: \(expiredPermits.count) need renewal")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else if pendingPermits.count > 0 {
                Text("Pending: \(pendingPermits.count) in review")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            } else {
                Text("All permits current")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private var dsnyComplianceContent: some View {
        VStack(spacing: 6) {
            let dsnyViolations = viewModel.dsnyScheduleData.values.flatMap { $0 }.count
            Text("Routes: \(dsnyViolations) monitored")
                .font(.caption2)
                .foregroundColor(.green)
            
            Text("Collection: On schedule")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private var ll97ComplianceContent: some View {
        VStack(spacing: 6) {
            let ll97Issues = viewModel.ll97EmissionsData.values.flatMap { $0 }.filter { !$0.isCompliant }
            Text("Emissions: \(ll97Issues.count) over limit")
                .font(.caption2)
                .foregroundColor(ll97Issues.isEmpty ? .green : .orange)
            
            let totalFines = ll97Issues.compactMap { $0.potentialFine }.reduce(0, +)
            if totalFines > 0 {
                Text("Potential fines: $\(Int(totalFines))")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else {
                Text("No fines projected")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
    
    // MARK: - Main Tab Content Views
    
    @ViewBuilder
    private var prioritiesContent: some View {
        VStack(spacing: 8) {
            ForEach(getStrategicRecommendations(), id: \.title) { recommendation in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(recommendation.description)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: priorityIcon(recommendation.priority))
                        .font(.system(size: 12))
                        .foregroundColor(priorityColor(recommendation.priority))
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            }
        }
    }
    
    @ViewBuilder
    private var portfolioContent: some View {
        VStack(spacing: 0) {
            // Portfolio sub-tabs
            HStack(spacing: 0) {
                ForEach(PortfolioSubTab.allCases, id: \.rawValue) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPortfolioTab = tab
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10))
                                .foregroundColor(selectedPortfolioTab == tab ? .blue : .gray)
                            
                            Text(tab.rawValue)
                                .font(.caption2)
                                .foregroundColor(selectedPortfolioTab == tab ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            selectedPortfolioTab == tab ?
                                Color.blue.opacity(0.15) : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Portfolio sub-content
            switch selectedPortfolioTab {
            case .overview:
                portfolioOverviewContent
            case .financial:
                portfolioFinancialContent
            case .performance:
                portfolioPerformanceContent
            }
        }
    }
    
    @ViewBuilder
    private var complianceContent: some View {
        VStack(spacing: 0) {
            // Compliance sub-tabs
            HStack(spacing: 0) {
                ForEach(ComplianceSubTab.allCases, id: \.rawValue) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedComplianceTab = tab
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10))
                                .foregroundColor(selectedComplianceTab == tab ? .green : .gray)
                            
                            Text(tab.rawValue)
                                .font(.caption2)
                                .foregroundColor(selectedComplianceTab == tab ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            selectedComplianceTab == tab ?
                                Color.green.opacity(0.15) : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Compliance sub-content
            switch selectedComplianceTab {
            case .overview:
                complianceOverviewContent
            case .hpd:
                hpdComplianceContent
            case .dob:
                dobComplianceContent
            case .dsny:
                dsnyComplianceContent
            case .ll97:
                ll97ComplianceContent
            }
        }
    }
    
    @ViewBuilder
    private var chatContent: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                
                Text("Ask Nova about your portfolio")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(10)
            .background(Color.purple.opacity(0.15))
            .cornerRadius(8)
            
            VStack(spacing: 6) {
                Text("Popular Questions:")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text("• What buildings need attention?")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("• How can I reduce operating costs?")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("• What violations need resolution?")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
        }
    }
    
    // MARK: - Sample Data
    
    private func getPreviewBuildings() -> [SampleBuilding] {
        return [
            SampleBuilding(name: "Preview Building A", value: 2500, occupancy: 95, taxAmount: 45000),
            SampleBuilding(name: "Preview Building B", value: 1800, occupancy: 88, taxAmount: 32000),
            SampleBuilding(name: "Preview Building C", value: 3200, occupancy: 92, taxAmount: 58000)
        ]
    }
}

struct NovaClientInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(color.opacity(0.6))
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Types

struct NovaStatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .cornerRadius(8)
    }
}

struct StrategicRecommendation {
    let title: String
    let description: String
    let priority: CoreTypes.Priority
}

struct SampleBuilding {
    let name: String
    let value: Double
    let occupancy: Int
    let taxAmount: Double
}

// MARK: - CoreTypes Extensions

extension CoreTypes {
    enum Priority {
        case low, medium, high, critical
        
        var rawValue: String {
            switch self {
            case .low: return "low"
            case .medium: return "medium"
            case .high: return "high"
            case .critical: return "critical"
            }
        }
    }
}

// Preview removed
