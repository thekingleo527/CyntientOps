//
//  IntelligencePreviewPanel.swift
//  CyntientOps v6.0
//
//  ✅ REFACTORED: Now supports both panel and compact bar modes
//  ✅ ELEGANT: Single component, two display modes
//  ✅ NAVIGATION: Compact mode acts as intelligent navigation
//  ✅ MAINTAINS: All existing functionality
//  ✅ PRODUCTION DATA: Uses real OperationalDataManager insights
//  ✅ ENHANCED: Swipe gestures, quick actions, expandable navigation
//  ✅ NOVA INTEGRATION: Uses actual Nova AI avatar instead of generic icons
//
//  Real-world operational context:
//  - 20 active buildings, 7 workers
//  - DSNY compliance: Set-out after 8 PM, pickup 6 AM - 12 PM
//  - Kevin Dutan: Rubin Museum specialist (38 tasks)
//  - Mercedes Inamagua: West 17th St glass cleaning circuit
//  - Edwin Lema: Stuyvesant Cove Park maintenance
//  - Angel Guiracocha: Evening DSNY operations
//

import SwiftUI

// MARK: - CyntientOps Production Data Reference
// Building IDs from CanonicalIDs:
// - "14": Rubin Museum (142-148 W 17th) - Kevin's primary
// - "10": 131 Perry Street
// - "6": 68 Perry Street
// - "3": 135-139 West 17th Street
// - "5": 138 West 17th Street
// - "9": 117 West 17th Street
// - "13": 136 West 17th Street
// - "16": Stuyvesant Cove Park - Edwin's territory
// - "11": 123 1st Avenue
// Worker assignments:
// - Kevin Dutan (ID: 4): Museum specialist, expanded duties
// - Mercedes Inamagua (ID: 5): Glass cleaning circuit
// - Edwin Lema (ID: 2): Park and East side maintenance
// - Angel Guiracocha (ID: 7): Evening DSNY operations
// - Luis Lopez (ID: 6): Perry St and downtown maintenance

struct IntelligencePreviewPanel: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onInsightTap: ((CoreTypes.IntelligenceInsight) -> Void)?
    let onRefresh: (() async -> Void)?
    var displayMode: DisplayMode = .panel
    var onNavigate: ((NavigationTarget) -> Void)?
    var contextEngine: WorkerContextEngine?
    
    @State private var isRefreshing = false
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var showingDetail = false
    @State private var currentInsightIndex = 0
    @State private var rotationTimer: Timer?
    
    // Enhanced states for gestures and expansion
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var showSwipeHint = false
    @State private var isNovaThinking = false
    
    // Display modes
    enum DisplayMode {
        case panel      // Full panel (existing)
        case compact    // Bottom bar navigation
    }
    
    // Enhanced Navigation targets
    enum NavigationTarget {
        // Existing targets
        case tasks(urgent: Int)
        case buildings(affected: [String])
        case compliance(deadline: Date?)
        case maintenance(overdue: Int)
        case fullInsights
        
        // NEW navigation targets
        case allTasks
        case taskDetail(id: String)
        case allBuildings
        case buildingDetail(id: String)
        case clockOut
        case profile
        case settings
        case dsnyTasks
        case routeOptimization
        case photoEvidence
        case emergencyContacts
    }
    
    init(
        insights: [CoreTypes.IntelligenceInsight],
        onInsightTap: ((CoreTypes.IntelligenceInsight) -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil,
        displayMode: DisplayMode = .panel,
        onNavigate: ((NavigationTarget) -> Void)? = nil,
        contextEngine: WorkerContextEngine? = nil
    ) {
        self.insights = insights
        self.onInsightTap = onInsightTap
        self.onRefresh = onRefresh
        self.displayMode = displayMode
        self.onNavigate = onNavigate
        self.contextEngine = contextEngine
    }
    
    var body: some View {
        switch displayMode {
        case .panel:
            panelView
        case .compact:
            enhancedCompactView
        }
    }
    
    // MARK: - Panel View (Original with Nova)
    
    private var panelView: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerWithNova
            
            if insights.isEmpty {
                emptyState
            } else {
                insightMetrics
                insightsList
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
    
    // MARK: - Enhanced Compact Navigation Bar View
    
    private var enhancedCompactView: some View {
        VStack(spacing: 0) {
            // Swipe indicator
            if !isExpanded {
                swipeIndicator
            }
            
            // Main compact panel content
            Button(action: handleCompactTap) {
                HStack(spacing: 0) {
                    // Nova AI avatar instead of generic indicator
                    compactNovaAvatar
                        .padding(.trailing, 12)
                    
                    // Dynamic content area
                    Spacer(minLength: 0)
                    
                    compactContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 0)
                    
                    // Enhanced quick actions
                    enhancedCompactActions
                        .padding(.leading, 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 60)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable navigation pills
            if isExpanded {
                quickNavigationPills
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .background(compactBackground)
        .frame(height: isExpanded ? 120 : 60)
        .offset(y: dragOffset)
        .gesture(swipeGesture)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
        .onAppear {
            startInsightRotation()
            // Show swipe hint briefly on first appearance
            if !UserDefaults.standard.bool(forKey: "hasSeenSwipeHint") {
                showSwipeHintBriefly()
            }
        }
        .onDisappear { stopInsightRotation() }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
        .overlay(alignment: .bottom) {
            if showSwipeHint {
                swipeHintOverlay
            }
        }
    }
    
    // MARK: - Swipe Components
    
    private var swipeIndicator: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 4)
                .padding(.bottom, 2)
            Spacer()
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation(.interactiveSpring()) {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if value.translation.height < -30 {
                        isExpanded = true
                    } else if value.translation.height > 30 && isExpanded {
                        isExpanded = false
                    }
                    dragOffset = 0
                }
            }
    }
    
    // MARK: - Quick Action Buttons
    
    private var enhancedCompactActions: some View {
        HStack(spacing: 8) {
            // Context-aware quick action buttons
            ForEach(getQuickActions(), id: \.id) { action in
                QuickActionButton(
                    icon: action.icon,
                    text: action.text,
                    color: action.color,
                    isCritical: action.isCritical
                ) {
                    onNavigate?(action.target)
                }
            }
            
            // Insight count badge (if no quick actions)
            if getQuickActions().isEmpty && insights.count > 0 {
                InsightCountBadge(
                    count: insights.count,
                    hasCritical: hasCritical
                )
            }
            
            // Chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .animation(.spring(response: 0.3), value: isExpanded)
        }
    }
    
    // MARK: - Quick Navigation Pills
    
    private var quickNavigationPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(getNavigationPills(), id: \.id) { pill in
                    NavigationPill(
                        icon: pill.icon,
                        label: pill.label,
                        badge: pill.badge
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded = false
                        }
                        onNavigate?(pill.target)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Context-Aware Quick Actions
    
    private func getQuickActions() -> [QuickAction] {
        var actions: [QuickAction] = []
        
        // Critical tasks action
        if let urgentCount = getUrgentTaskCount(), urgentCount > 0 {
            actions.append(QuickAction(
                id: "urgent_tasks",
                icon: "exclamationmark.triangle.fill",
                text: "\(urgentCount) Tasks",
                color: .orange,
                isCritical: urgentCount >= 3,
                target: .tasks(urgent: urgentCount)
            ))
        }
        
        // DSNY deadline action
        if hasComplianceDeadline {
            let dsnyCount = insights.filter {
                $0.type == .compliance &&
                $0.description.contains("DSNY")
            }.flatMap { $0.affectedBuildings }.count
            
            // Check if it's close to 8 PM
            let calendar = Calendar.current
            let now = Date()
            let hour = calendar.component(.hour, from: now)
            let isUrgent = hour >= 18 && hour < 20 // 6 PM to 8 PM
            
            actions.append(QuickAction(
                id: "dsny_deadline",
                icon: isUrgent ? "clock.fill" : "trash.fill",
                text: isUrgent ? "8:00 PM" : "\(dsnyCount) DSNY",
                color: isUrgent ? .red : .orange,
                isCritical: isUrgent,
                target: .dsnyTasks
            ))
        }
        
        // Current building action
        if let buildingId = contextEngine?.currentBuilding?.id,
           let buildingName = contextEngine?.currentBuilding?.name {
            let shortName = String(buildingName.prefix(8))
            actions.append(QuickAction(
                id: "current_building",
                icon: "building.2",
                text: shortName,
                color: .blue,
                isCritical: false,
                target: .buildingDetail(id: buildingId)
            ))
        }
        
        // Route optimization action
        if insights.contains(where: { $0.description.contains("optimization") }) {
            actions.append(QuickAction(
                id: "optimize_route",
                icon: "map",
                text: "Optimize",
                color: .green,
                isCritical: false,
                target: .routeOptimization
            ))
        }
        
        return Array(actions.prefix(3)) // Maximum 3 quick actions
    }
    
    // MARK: - Navigation Pills
    
    private func getNavigationPills() -> [NavigationPillData] {
        var pills: [NavigationPillData] = []
        
        // Always show these core navigation options
        pills.append(NavigationPillData(
            id: "all_tasks",
            icon: "checkmark.circle",
            label: "All Tasks",
            badge: contextEngine?.todaysTasks.filter { !$0.isCompleted }.count,
            target: .allTasks
        ))
        
        pills.append(NavigationPillData(
            id: "buildings",
            icon: "building.2",
            label: "Buildings",
            badge: contextEngine?.assignedBuildings.count,
            target: .allBuildings
        ))
        
        // Context-specific pills
        if contextEngine?.clockInStatus.isClockedIn ?? false {
            pills.append(NavigationPillData(
                id: "clock_out",
                icon: "clock.badge.checkmark",
                label: "Clock Out",
                badge: nil,
                target: .clockOut
            ))
        }
        
        if insights.contains(where: { $0.type == .compliance }) {
            pills.append(NavigationPillData(
                id: "photo_evidence",
                icon: "camera.fill",
                label: "Evidence",
                badge: nil,
                target: .photoEvidence
            ))
        }
        
        pills.append(NavigationPillData(
            id: "nova_chat",
            icon: "message.fill",
            label: "Nova Chat",
            badge: nil,
            target: .fullInsights
        ))
        
        pills.append(NavigationPillData(
            id: "more",
            icon: "ellipsis.circle",
            label: "More",
            badge: nil,
            target: .settings
        ))
        
        return pills
    }
    
    // MARK: - Swipe Hint
    
    private var swipeHintOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.caption)
                Text("Swipe up for quick navigation")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.8)))
            .padding(.bottom, 70)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func showSwipeHintBriefly() {
        withAnimation(.easeIn(duration: 0.3)) {
            showSwipeHint = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSwipeHint = false
                UserDefaults.standard.set(true, forKey: "hasSeenSwipeHint")
            }
        }
    }
    
    // MARK: - Nova Avatar Components
    
    private var compactNovaAvatar: some View {
        NovaAvatar(
            size: .small,
            isActive: !insights.isEmpty,
            hasUrgentInsights: hasCritical || hasComplianceDeadline,
            isBusy: isNovaThinking,
            onTap: handleCompactTap,
            onLongPress: {
                // Long press for voice activation in future
                print("Nova long press - future voice activation")
            }
        )
        .onChange(of: currentInsightIndex) { _, _ in
            // Brief thinking animation when insights rotate
            withAnimation(.easeInOut(duration: 0.3)) {
                isNovaThinking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNovaThinking = false
                }
            }
        }
    }
    
    private var headerWithNova: some View {
        HStack {
            // Nova Avatar for panel mode
            NovaAvatar(
                size: .medium,
                isActive: !insights.isEmpty,
                hasUrgentInsights: hasCritical,
                isBusy: isRefreshing,
                onTap: {
                    onNavigate?(.fullInsights)
                }
            )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Nova Intelligence")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !insights.isEmpty {
                        StatusPill(text: "LIVE", color: .green)
                    }
                }
                
                Text("Updated \(Date(), style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let onRefresh = onRefresh {
                Button(action: {
                    Task {
                        isRefreshing = true
                        await onRefresh()
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(.linear(duration: 1).repeatCount(isRefreshing ? .max : 0, autoreverses: false), value: isRefreshing)
                }
                .disabled(isRefreshing)
            }
        }
    }
    
    // MARK: - Compact View Components (Enhanced)
    
    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("Nova Intelligence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if !insights.isEmpty {
                    StatusPill(
                        text: getStatusText(),
                        color: getStatusColor()
                    )
                }
            }
            
            if !insights.isEmpty {
                Text(currentInsightText)
                    .font(.caption2)
                    .foregroundColor(currentInsightColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .animation(.easeInOut(duration: 0.3), value: currentInsightIndex)
            } else {
                Text("Analyzing operations...")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private func getStatusText() -> String {
        if hasCritical {
            return "CRITICAL"
        } else if hasComplianceDeadline {
            return "TIME SENSITIVE"
        } else {
            return "ACTIVE"
        }
    }
    
    private func getStatusColor() -> Color {
        if hasCritical {
            return .red
        } else if hasComplianceDeadline {
            return .orange
        } else {
            return .green
        }
    }
    
    private var compactBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Top edge indicator
            if hasCritical {
                VStack {
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 2)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Metrics Overview (Panel Mode)
    
    private var insightMetrics: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                IntelligenceMetricCard(
                    title: "Total Insights",
                    value: "\(insights.count)",
                    icon: "lightbulb.fill",
                    color: .blue,
                    onTap: { onNavigate?(.fullInsights) }
                )
                
                IntelligenceMetricCard(
                    title: "Critical",
                    value: "\(criticalInsightsCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    onTap: { handleCriticalTap() }
                )
                
                IntelligenceMetricCard(
                    title: "High Priority",
                    value: "\(highPriorityInsightsCount)",
                    icon: "flag.fill",
                    color: .orange,
                    onTap: { handleHighPriorityTap() }
                )
                
                IntelligenceMetricCard(
                    title: "Action Required",
                    value: "\(actionableInsightsCount)",
                    icon: "hand.tap.fill",
                    color: .green,
                    onTap: { handleActionRequiredTap() }
                )
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Insights List (Panel Mode)
    
    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if insights.count > 3 {
                    Button(action: { onNavigate?(.fullInsights) }) {
                        Text("+\(insights.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(insights.prefix(3)) { insight in
                    InsightRowView(insight: insight) {
                        selectedInsight = insight
                        showingDetail = true
                        onInsightTap?(insight)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            // Nova Avatar in inactive state
            NovaAvatar(
                size: .large,
                isActive: false,
                hasUrgentInsights: false,
                isBusy: false
            )
            
            Text("No Intelligence Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Nova is analyzing your building data...")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    // MARK: - Navigation Logic
    
    private func handleCompactTap() {
        if let critical = insights.first(where: { $0.priority == .critical }) {
            selectedInsight = critical
            showingDetail = true
        } else {
            onNavigate?(.fullInsights)
        }
    }
    
    private func handleCriticalTap() {
        if let critical = insights.first(where: { $0.priority == .critical }) {
            selectedInsight = critical
            showingDetail = true
        }
    }
    
    private func handleHighPriorityTap() {
        if let high = insights.first(where: { $0.priority == .high }) {
            selectedInsight = high
            showingDetail = true
        }
    }
    
    private func handleActionRequiredTap() {
        if let action = insights.first(where: { $0.actionRequired }) {
            selectedInsight = action
            showingDetail = true
        }
    }
    
    // MARK: - Helper Methods
    
    private var currentInsightText: String {
        guard !insights.isEmpty else { return "Analyzing..." }
        
        let sorted = insights.sorted { first, second in
            if first.priority == .critical && second.priority != .critical { return true }
            if first.actionRequired && !second.actionRequired { return true }
            return false
        }
        
        guard currentInsightIndex < sorted.count else {
            return sorted.first?.title ?? ""
        }
        
        return sorted[currentInsightIndex].title
    }
    
    private var currentInsightColor: Color {
        guard !insights.isEmpty,
              currentInsightIndex < insights.count else {
            return .white.opacity(0.6)
        }
        
        switch insights[currentInsightIndex].priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .white.opacity(0.8)
        }
    }
    
    private func startInsightRotation() {
        guard insights.count > 1, displayMode == .compact else { return }
        
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsightIndex = (currentInsightIndex + 1) % insights.count
            }
        }
    }
    
    private func stopInsightRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    private func getUrgentTaskCount() -> Int? {
        // Extract from insights mentioning urgent tasks
        for insight in insights {
            if insight.type == .operations || insight.type == .maintenance {
                if let match = insight.description.firstMatch(of: /(\d+)\s+(urgent|overdue|critical)/) {
                    return Int(match.1)
                }
            }
        }
        return nil
    }
    
    private func getOverdueMaintenanceCount() -> Int? {
        // Extract from maintenance insights
        for insight in insights where insight.type == .maintenance {
            if let match = insight.description.firstMatch(of: /(\d+)\s+.*\s*(overdue|scheduled|pending)/) {
                return Int(match.1)
            }
        }
        return nil
    }
    
    // MARK: - Computed Properties
    
    private var criticalInsightsCount: Int {
        insights.filter { $0.priority == .critical }.count
    }
    
    private var highPriorityInsightsCount: Int {
        insights.filter { $0.priority == .high }.count
    }
    
    private var actionableInsightsCount: Int {
        insights.filter { $0.actionRequired }.count
    }
    
    private var hasCritical: Bool {
        insights.contains { $0.priority == .critical }
    }
    
    private var hasActionRequired: Bool {
        insights.contains { $0.actionRequired }
    }
    
    private var hasComplianceDeadline: Bool {
        insights.contains { insight in
            insight.type == .compliance &&
            (insight.priority == .critical || insight.priority == .high) &&
            (insight.description.contains("DSNY") || insight.description.contains("8:00 PM") || insight.description.contains("set-out"))
        }
    }
}

// MARK: - Supporting Components


struct IntelligenceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let onTap: (() -> Void)?
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 100)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let isCritical: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                
                Text(text)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(isCritical ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCritical ? color : color.opacity(0.2))
            )
        }
    }
}

// MARK: - Navigation Pill

struct NavigationPill: View {
    let icon: String
    let label: String
    let badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(2)
                            .frame(minWidth: 14, minHeight: 14)
                            .background(Circle().fill(Color.red))
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(minWidth: 60)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct InsightCountBadge: View {
    let count: Int
    let hasCritical: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(hasCritical ? .red : .blue)
                .frame(width: 20, height: 20)
            
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Data Models

struct QuickAction: Identifiable {
    let id: String
    let icon: String
    let text: String
    let color: Color
    let isCritical: Bool
    let target: IntelligencePreviewPanel.NavigationTarget
}

struct NavigationPillData: Identifiable {
    let id: String
    let icon: String
    let label: String
    let badge: Int?
    let target: IntelligencePreviewPanel.NavigationTarget
}

// MARK: - Insight Row View

struct InsightRowView: View {
    let insight: CoreTypes.IntelligenceInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(priorityColor(for: insight.priority))
                    .frame(width: 8, height: 8)
                
                Image(systemName: insight.type.icon)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.EnumColors.insightCategory(insight.type))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(insight.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if insight.actionRequired {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func priorityColor(for priority: CoreTypes.AIPriority) -> Color {
        CyntientOpsDesign.EnumColors.aiPriority(priority)
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: CoreTypes.IntelligenceInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: insight.type.icon)
                                .font(.title2)
                                .foregroundColor(CyntientOpsDesign.EnumColors.insightCategory(insight.type))
                            
                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(insight.priority.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(priorityColor(for: insight.priority))
                                .cornerRadius(6)
                        }
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(insight.type.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Priority")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(insight.priority.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Action Required")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(insight.actionRequired ? "Yes" : "No")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    if !insight.affectedBuildings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Affected Buildings")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(insight.affectedBuildings, id: \.self) { buildingId in
                                HStack {
                                    Image(systemName: "building.2")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    
                                    Text("Building ID: \(buildingId)")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Intelligence Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func priorityColor(for priority: CoreTypes.AIPriority) -> Color {
        CyntientOpsDesign.EnumColors.aiPriority(priority)
    }
}

// MARK: - Preview

struct IntelligencePreviewPanel_Previews: PreviewProvider {
    static var previews: some View {
        // Real-world insights based on OperationalDataManager data
        let productionInsights: [CoreTypes.IntelligenceInsight] = [
            CoreTypes.IntelligenceInsight(
                title: "3 urgent museum tasks overdue",
                description: "Kevin's climate control check and security protocols at Rubin Museum require immediate attention",
                type: .operations,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: ["14"]
            ),
            
            CoreTypes.IntelligenceInsight(
                title: "DSNY set-out deadline 8:00 PM",
                description: "Kevin must place trash for 136, 138 West 17th St and Rubin Museum. Pickup window: 6 AM - 12 PM",
                type: .compliance,
                priority: .high,
                actionRequired: true,
                affectedBuildings: ["13", "5", "14"]
            ),
            
            CoreTypes.IntelligenceInsight(
                title: "Glass circuit optimization available",
                description: "Mercedes can save 20 minutes by reordering: 117 → 135-139 → 136 → 138 West 17th",
                type: .routing,
                priority: .medium,
                actionRequired: false,
                affectedBuildings: ["9", "3", "13", "5"]
            )
        ]
        
        VStack(spacing: 20) {
            // Panel mode with production data
            IntelligencePreviewPanel(
                insights: productionInsights,
                displayMode: .panel
            )
            
            Divider()
            
            // Compact mode - normal operations
            IntelligencePreviewPanel(
                insights: productionInsights,
                displayMode: .compact,
                onNavigate: { target in
                    print("Navigate to: \(target)")
                },
                contextEngine: WorkerContextEngine.shared
            )
            .frame(height: 60)
            
            // Empty state compact
            IntelligencePreviewPanel(
                insights: [],
                displayMode: .compact
            )
            .frame(height: 60)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
