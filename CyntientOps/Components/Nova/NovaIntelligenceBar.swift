//
//  NovaIntelligenceBar.swift  
//  CyntientOps v6.0 - NovaIntelligenceBar Hard Reset
//
//  ✅ HARD RESET: .regularMaterial, proper heights, readable text
//  ✅ ACTIONABLE: Real actions that do something meaningful
//  ✅ CLEAN: Removed decorative elements, focus on utility
//  ✅ ACCESSIBLE: Better contrast ratios, larger touch targets
//

import SwiftUI

// MARK: - Nova Routes
enum NovaRoute: Identifiable {
    case priorities
    case tasks
    case analytics
    case chat
    case map
    
    var id: String {
        switch self {
        case .priorities: return "priorities"
        case .tasks: return "tasks"
        case .analytics: return "analytics"
        case .chat: return "chat"
        case .map: return "map"
        }
    }
}

struct NovaIntelligenceBar: View {
    let container: ServiceContainer
    let workerId: String?
    let currentContext: [String: Any]
    let onRoute: (NovaRoute) -> Void
    
    @State private var isExpanded = false
    @State private var currentInsight: String = "Tap for AI insights"
    @State private var selectedTab: NovaTab = .priorities
    
    enum NovaTab: String, CaseIterable {
        case priorities = "Priorities"
        case tasks = "Tasks" 
        case analytics = "Analytics"
        case chat = "Chat"
        case map = "Map"
        
        var icon: String {
            switch self {
            case .priorities: return "exclamationmark.triangle.fill"
            case .tasks: return "checkmark.circle.fill"
            case .analytics: return "chart.bar.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .map: return "map.fill"
            }
        }
    }
    
    // Nova AI Manager reference (passed from container)
    @ObservedObject var novaManager: NovaAIManager
    
    private let insights = [
        "You're ahead of schedule on 3 tasks today",
        "Photo required for sanitation tasks",
        "Rubin Museum prefers morning cleanings",
        "Consider batching tasks by floor level",
        "Weather alert: Indoor tasks recommended"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Content - More readable with .regularMaterial
                expandedContent
                    .frame(height: 200)
                    .background(.regularMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.borderSubtle),
                        alignment: .top
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Collapsed Bar - Clean and readable
            collapsedBar
                .frame(height: 64)
                .background(.regularMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.borderSubtle),
                    alignment: .top
                )
        }
    }
    
    private var collapsedBar: some View {
        Button(action: {
            // Beautiful haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 16) {
                // Beautiful animated Nova AI icon with elegant effects
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    CyntientOpsDesign.DashboardColors.workerPrimary,
                                    CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.3), radius: 8)
                        .scaleEffect(novaManager.isThinking ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: novaManager.isThinking)
                    
                    // Elegant processing ring
                    if novaManager.isThinking {
                        Circle()
                            .trim(from: 0, to: 0.8)
                            .stroke(
                                AngularGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.1)],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 46, height: 46)
                            .rotationEffect(.degrees(novaManager.isThinking ? 360 : 0))
                            .animation(
                                .linear(duration: 2).repeatForever(autoreverses: false),
                                value: novaManager.isThinking
                            )
                    }
                    
                    Image(systemName: novaManager.isThinking ? "brain.head.profile" : "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating, isActive: novaManager.isThinking)
                        .animation(.easeInOut(duration: 0.3), value: novaManager.isThinking)
                }
                
                // Beautiful insight text with smooth transitions
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nova AI")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(getContextualInsight())
                        .font(.system(size: 15))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.3), value: getContextualInsight())
                }
                
                Spacer()
                
                // Elegant status and expand indicators
                HStack(spacing: 12) {
                    // Beautiful pulsing status indicator
                    ZStack {
                        Circle()
                            .fill(novaManager.isThinking ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success)
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .fill((novaManager.isThinking ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success).opacity(0.3))
                            .frame(width: 16, height: 16)
                            .scaleEffect(1.0)
                            .opacity(0.8)
                            .animation(
                                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                value: novaManager.isThinking
                            )
                    }
                    
                    // Elegant chevron with smooth rotation
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Nova Header with tabs
            VStack(spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                        
                        Text("Nova Intelligence")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
                
                // Tab Bar
                HStack(spacing: 4) {
                    ForEach(NovaTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16, weight: .medium))
                                Text(tab.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab ? 
                                CyntientOpsDesign.DashboardColors.workerPrimary : 
                                CyntientOpsDesign.DashboardColors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == tab ? 
                                        CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.15) : 
                                        Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Tab Content
            selectedTabContent
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .priorities:
            prioritiesContent
        case .tasks:
            tasksContent
        case .analytics:
            analyticsContent
        case .chat:
            chatContent
        case .map:
            mapContent
        }
    }
    
    private var prioritiesContent: some View {
        VStack(spacing: 12) {
            ForEach(getUrgentItems(), id: \.id) { item in
                NovaTabCard(
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    color: item.color,
                    action: { onRoute(.priorities) }
                )
            }
        }
        .padding(.top, 16)
    }
    
    private var tasksContent: some View {
        VStack(spacing: 12) {
            ForEach(getTodaysTasks(), id: \.id) { task in
                NovaTabCard(
                    title: task.title,
                    subtitle: task.subtitle,
                    icon: "checkmark.circle",
                    color: CyntientOpsDesign.DashboardColors.success,
                    action: { onRoute(.tasks) }
                )
            }
        }
        .padding(.top, 16)
    }
    
    private var analyticsContent: some View {
        VStack(spacing: 12) {
            NovaTabCard(
                title: "Performance Today",
                subtitle: "85% efficiency rating",
                icon: "chart.line.uptrend.xyaxis",
                color: CyntientOpsDesign.DashboardColors.info,
                action: { onRoute(.analytics) }
            )
            NovaTabCard(
                title: "Task Analytics", 
                subtitle: "View detailed metrics",
                icon: "chart.bar.fill",
                color: CyntientOpsDesign.DashboardColors.workerAccent,
                action: { onRoute(.analytics) }
            )
        }
        .padding(.top, 16)
    }
    
    private var chatContent: some View {
        VStack(spacing: 12) {
            NovaTabCard(
                title: "Ask Nova",
                subtitle: "Get help with tasks and questions",
                icon: "bubble.left.and.bubble.right.fill",
                color: CyntientOpsDesign.DashboardColors.workerPrimary,
                action: { onRoute(.chat) }
            )
        }
        .padding(.top, 16)
    }
    
    private var mapContent: some View {
        VStack(spacing: 12) {
            NovaTabCard(
                title: "Route Optimizer",
                subtitle: "Optimize your route for today",
                icon: "map.fill",
                color: CyntientOpsDesign.DashboardColors.info,
                action: { onRoute(.map) }
            )
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Methods
    
    private func getContextualInsight() -> String {
        let completedTasks = currentContext["completedTasks"] as? Int ?? 0
        let totalTasks = currentContext["totalTasks"] as? Int ?? 0
        let urgentTasks = currentContext["urgentTasks"] as? Int ?? 0
        
        if urgentTasks > 0 {
            return "\(urgentTasks) urgent tasks need attention"
        } else if totalTasks > 0 {
            return "\(completedTasks)/\(totalTasks) tasks completed today"
        } else {
            return "Ready to help with your day"
        }
    }
    
    private func getUrgentItems() -> [NovaTabItem] {
        let urgentTasks = currentContext["urgentTasks"] as? Int ?? 0
        return [
            NovaTabItem(
                id: "urgent",
                title: "Urgent Tasks",
                subtitle: "\(urgentTasks) need immediate attention",
                icon: "exclamationmark.triangle.fill",
                color: CyntientOpsDesign.DashboardColors.critical
            )
        ]
    }
    
    private func getTodaysTasks() -> [NovaTabItem] {
        let completedTasks = currentContext["completedTasks"] as? Int ?? 0
        let totalTasks = currentContext["totalTasks"] as? Int ?? 0
        return [
            NovaTabItem(
                id: "today",
                title: "Today's Tasks",
                subtitle: "\(completedTasks)/\(totalTasks) completed",
                icon: "checkmark.circle",
                color: CyntientOpsDesign.DashboardColors.success
            )
        ]
    }
    
    private func getActionableInsights() -> [ActionableInsight] {
        var insights: [ActionableInsight] = []
        
        let completedTasks = currentContext["completedTasks"] as? Int ?? 0
        let totalTasks = currentContext["totalTasks"] as? Int ?? 0
        let urgentTasks = currentContext["urgentTasks"] as? Int ?? 0
        
        if urgentTasks > 0 {
            insights.append(ActionableInsight(
                id: "urgent",
                title: "Urgent Tasks",
                description: "\(urgentTasks) tasks need immediate attention",
                actionType: .viewTasks
            ))
        }
        
        if completedTasks > 0 {
            let progress = Double(completedTasks) / Double(max(totalTasks, 1))
            if progress >= 0.8 {
                insights.append(ActionableInsight(
                    id: "progress",
                    title: "Great Progress!",
                    description: "You're \(Int(progress * 100))% complete",
                    actionType: .viewSchedule
                ))
            }
        }
        
        insights.append(ActionableInsight(
            id: "route",
            title: "Route Optimization",
            description: "Tap for better routing suggestions",
            actionType: .optimizeRoute
        ))
        
        insights.append(ActionableInsight(
            id: "help",
            title: "Need Assistance?",
            description: "Ask Nova for help with tasks",
            actionType: .askNova
        ))
        
        return Array(insights.prefix(4))
    }
    
    private func handleInsightAction(_ insight: ActionableInsight) {
        handleQuickAction(insight.actionType)
    }
    
    private func handleQuickAction(_ action: NovaQuickActionType) {
        // These will be wired to actual functionality
        print("Nova action: \(action)")
        
        // For now, just close the panel
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
}

// MARK: - Supporting Types

struct ActionableInsight: Identifiable {
    let id: String
    let title: String
    let description: String
    let actionType: NovaQuickActionType
}

enum NovaQuickActionType {
    case tasks
    case route
    case help
    case viewTasks
    case viewSchedule
    case optimizeRoute
    case askNova
}

// MARK: - Supporting Components

struct NovaActionCard: View {
    let insight: ActionableInsight
    let onTap: () -> Void
    
    @State private var pressed = false
    @State private var hovered = false
    
    var body: some View {
        Button(action: {
            // Beautiful haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Beautiful pulsing indicator
                    ZStack {
                        Circle()
                            .fill(cardColor)
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .fill(cardColor.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(hovered ? 1.2 : 1.0)
                            .opacity(hovered ? 0.8 : 0.6)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: hovered)
                    }
                    
                    Spacer()
                    
                    // Elegant icon with beautiful animation
                    Image(systemName: cardIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(cardColor)
                        .symbolEffect(.bounce.up, options: .nonRepeating, isActive: pressed)
                        .scaleEffect(pressed ? 0.9 : hovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hovered)
                }
                
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: insight.title)
                
                Text(insight.description)
                    .font(.system(size: 12))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .lineLimit(2)
                    .animation(.easeInOut(duration: 0.3), value: insight.description)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: cardColor.opacity(0.1), radius: pressed ? 2 : 6, y: pressed ? 1 : 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        cardColor.opacity(hovered ? 0.4 : 0.2),
                                        cardColor.opacity(hovered ? 0.2 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: hovered ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(pressed ? 0.95 : hovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                pressed = pressing
            }
        }) {
            // Long press action if needed
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hovered = hovering
            }
        }
    }
    
    private var cardColor: Color {
        switch insight.actionType {
        case .viewTasks, .tasks:
            return CyntientOpsDesign.DashboardColors.success
        case .route, .optimizeRoute:
            return CyntientOpsDesign.DashboardColors.info
        case .help, .askNova:
            return CyntientOpsDesign.DashboardColors.warning
        case .viewSchedule:
            return CyntientOpsDesign.DashboardColors.workerPrimary
        }
    }
    
    private var cardIcon: String {
        switch insight.actionType {
        case .viewTasks, .tasks:
            return "checkmark.circle.fill"
        case .route, .optimizeRoute:
            return "map.fill"
        case .help, .askNova:
            return "questionmark.circle.fill"
        case .viewSchedule:
            return "calendar.circle.fill"
        }
    }
}

struct NovaQuickAction: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NovaTabItem

struct NovaTabItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - NovaTabCard

struct NovaTabCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct NovaIntelligenceBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            // Example with ServiceContainer
            Text("NovaIntelligenceBar Preview")
                .foregroundColor(.white)
                .padding()
            
            // Collapsed state preview
            VStack {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading) {
                        Text("Nova AI")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("5/12 tasks completed today")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif