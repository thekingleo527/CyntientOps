//
//  IntelligencePanelModel.swift
//  CyntientOps v6.0
//
//  ✅ LEGACY: Generic intelligence panel model used by previews
//  ✅ NOTE: Runtime panels are role-specific and wired directly to their VMs
//

import Foundation
import SwiftUI
import Combine

// MARK: - Panel Mode

public enum IntelligencePanelMode: CaseIterable {
    case mini       // Tab bar at bottom
    case expanded   // Accordion cards
    case full       // Full-screen (for map)
    
    var description: String {
        switch self {
        case .mini: return "Mini"
        case .expanded: return "Expanded"
        case .full: return "Full Screen"
        }
    }
}

// MARK: - Intelligence Tab

public struct IntelligenceTab: Identifiable, Hashable {
    public let id = UUID()
    public let key: String
    public let title: String
    public let icon: String
    public let badgeCount: Int?
    public let isEnabled: Bool
    
    public init(key: String, title: String, icon: String, badgeCount: Int? = nil, isEnabled: Bool = true) {
        self.key = key
        self.title = title
        self.icon = icon
        self.badgeCount = badgeCount
        self.isEnabled = isEnabled
    }
}

// MARK: - Role-Based Tab Configurations

public extension IntelligenceTab {
    
    // Worker tabs: Routines, Tasks, Portfolio, Analytics, Site Departure (optional)
    static let workerTabs: [IntelligenceTab] = [
        IntelligenceTab(key: "routines", title: "Routines", icon: "repeat", badgeCount: nil),
        IntelligenceTab(key: "tasks", title: "Tasks", icon: "list.bullet", badgeCount: nil),
        IntelligenceTab(key: "portfolio", title: "Portfolio", icon: "building.2", badgeCount: nil),
        IntelligenceTab(key: "analytics", title: "Analytics", icon: "chart.bar", badgeCount: nil),
        IntelligenceTab(key: "site_departure", title: "Site Dep.", icon: "location.slash", badgeCount: nil)
    ]
    
    // Client tabs: Priorities, Workers, Portfolio, Compliance, Analytics
    static let clientTabs: [IntelligenceTab] = [
        IntelligenceTab(key: "priorities", title: "Priorities", icon: "exclamationmark.triangle", badgeCount: nil),
        IntelligenceTab(key: "workers", title: "Workers", icon: "person.2", badgeCount: nil),
        IntelligenceTab(key: "portfolio", title: "Portfolio", icon: "building.2", badgeCount: nil),
        IntelligenceTab(key: "compliance", title: "Compliance", icon: "checkmark.shield", badgeCount: nil),
        IntelligenceTab(key: "analytics", title: "Analytics", icon: "chart.bar", badgeCount: nil)
    ]
    
    // Admin tabs: Priorities, Workers, Buildings, Compliance, Analytics
    static let adminTabs: [IntelligenceTab] = [
        IntelligenceTab(key: "priorities", title: "Priorities", icon: "exclamationmark.triangle.fill", badgeCount: nil),
        IntelligenceTab(key: "workers", title: "Workers", icon: "person.3", badgeCount: nil),
        IntelligenceTab(key: "buildings", title: "Buildings", icon: "building.columns", badgeCount: nil),
        IntelligenceTab(key: "compliance", title: "Compliance", icon: "checkmark.shield.fill", badgeCount: nil),
        IntelligenceTab(key: "analytics", title: "Analytics", icon: "chart.line.uptrend.xyaxis", badgeCount: nil)
    ]
}

// MARK: - Tab Data Content

public struct TabContentData {
    public let summary: String
    public let items: [TabItem]
    public let actions: [TabAction]
    
    public init(summary: String = "", items: [TabItem] = [], actions: [TabAction] = []) {
        self.summary = summary
        self.items = items
        self.actions = actions
    }
}

public struct TabItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let value: String?
    public let icon: String?
    public let color: Color?
    public let isHighlighted: Bool
    
    public init(title: String, subtitle: String? = nil, value: String? = nil, icon: String? = nil, color: Color? = nil, isHighlighted: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.color = color
        self.isHighlighted = isHighlighted
    }
}

public struct TabAction: Identifiable {
    public let id = UUID()
    public let title: String
    public let icon: String?
    public let isPrimary: Bool
    public let action: () -> Void
    
    public init(title: String, icon: String? = nil, isPrimary: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isPrimary = isPrimary
        self.action = action
    }
}

// MARK: - Intelligence Panel Model

@MainActor
public class IntelligencePanelModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var mode: IntelligencePanelMode = .mini
    @Published public var currentTab: String = ""
    @Published public var isMapFullScreen: Bool = false
    @Published public var lastPanelMode: IntelligencePanelMode = .mini
    
    // MARK: - Configuration
    
    public let userRole: CoreTypes.UserRole
    public var availableTabs: [IntelligenceTab] {
        switch userRole {
        case .worker:
            return IntelligenceTab.workerTabs
        case .client:
            return IntelligenceTab.clientTabs
        case .admin, .superAdmin:
            return IntelligenceTab.adminTabs
        case .manager:
            return IntelligenceTab.adminTabs // Managers get admin-level access
        }
    }
    
    // MARK: - Tab Data
    
    @Published public var tabData: [String: TabContentData] = [:]
    @Published public var tabExpansion: [String: Bool] = [:]
    
    // MARK: - Services
    
    private weak var serviceContainer: ServiceContainer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(userRole: CoreTypes.UserRole, serviceContainer: ServiceContainer? = nil) {
        self.userRole = userRole
        self.serviceContainer = serviceContainer
        
        // Set default tab
        self.currentTab = availableTabs.first?.key ?? ""
        
        // Initialize tab expansion states
        for tab in availableTabs {
            tabExpansion[tab.key] = false
        }
        
        setupDataSources()
    }
    
    // MARK: - Public Methods
    
    public func selectTab(_ tabKey: String) {
        guard availableTabs.contains(where: { $0.key == tabKey }) else { return }
        currentTab = tabKey
        
        // Auto-expand when tab is selected (accordion behavior)
        if mode == .expanded {
            expandTab(tabKey)
        }
    }
    
    public func setMode(_ newMode: IntelligencePanelMode) {
        if newMode == .full {
            // Save current mode to restore later
            lastPanelMode = mode
        }
        mode = newMode
    }
    
    public func toggleMapFullScreen() {
        if isMapFullScreen {
            // Exit full-screen map
            isMapFullScreen = false
            mode = lastPanelMode
        } else {
            // Enter full-screen map
            isMapFullScreen = true
            setMode(.mini)
        }
    }
    
    public func expandTab(_ tabKey: String) {
        // Collapse all other tabs (accordion behavior)
        for key in tabExpansion.keys {
            tabExpansion[key] = (key == tabKey)
        }
        currentTab = tabKey
    }
    
    public func toggleTabExpansion(_ tabKey: String) {
        let isCurrentlyExpanded = tabExpansion[tabKey] ?? false
        if isCurrentlyExpanded {
            // Collapse current tab
            tabExpansion[tabKey] = false
        } else {
            // Expand this tab, collapse others
            expandTab(tabKey)
        }
    }
    
    // MARK: - Tab Actions
    
    public func openMapFullScreen() {
        toggleMapFullScreen()
    }
    
    public func viewAllItems(for tabKey: String) {
        // Handle navigation to detailed view
        print("Navigate to detailed view for \(tabKey)")
    }
    
    // MARK: - Data Sources Setup
    
    private func setupDataSources() {
        // Set up reactive data sources based on user role
        switch userRole {
        case .worker:
            setupWorkerDataSources()
        case .client:
            setupClientDataSources()
        case .admin, .superAdmin:
            setupAdminDataSources()
        case .manager:
            setupAdminDataSources() // Managers use admin data sources
        }
    }
    
    private func setupWorkerDataSources() {
        // Initialize with default data, replace with real data sources
        updateTabData("routines", TabContentData(
            summary: "Today's routines",
            items: [
                TabItem(title: "Morning Building Check", subtitle: "7:00 AM", icon: "building", color: .blue),
                TabItem(title: "Sidewalk Cleaning", subtitle: "9:00 AM", icon: "broom", color: .green)
            ],
            actions: [
                TabAction(title: "Weekly Schedule", icon: "calendar") { self.viewAllItems(for: "routines") }
            ]
        ))
        
        updateTabData("tasks", TabContentData(
            summary: "3 urgent tasks",
            items: [
                TabItem(title: "Garbage Collection", subtitle: "High Priority", value: "Due 2h", color: .red, isHighlighted: true),
                TabItem(title: "Window Cleaning", subtitle: "Medium Priority", value: "Due 4h", color: .orange),
                TabItem(title: "Floor Mopping", subtitle: "Low Priority", value: "Due 6h", color: .green)
            ],
            actions: [
                TabAction(title: "Task History", icon: "clock.arrow.circlepath") { self.viewAllItems(for: "tasks") }
            ]
        ))
        
        updateTabData("portfolio", TabContentData(
            summary: "5 assigned buildings",
            items: [
                TabItem(title: "148 Chambers Street", subtitle: "Distance: 0.2 mi", icon: "building.2", color: .blue),
                TabItem(title: "Rubin Museum", subtitle: "Distance: 1.1 mi", icon: "building.columns", color: .purple)
            ],
            actions: [
                TabAction(title: "Open Map", icon: "map", isPrimary: true) { self.openMapFullScreen() }
            ]
        ))
        
        updateTabData("analytics", TabContentData(
            summary: "92% efficiency",
            items: [
                TabItem(title: "Completion Rate", value: "92%", color: .green),
                TabItem(title: "Average Time", value: "24 min", color: .blue),
                TabItem(title: "Tasks Completed", value: "47", color: .purple)
            ]
        ))
    }
    
    private func setupClientDataSources() {
        updateTabData("priorities", TabContentData(
            summary: "2 critical items",
            items: [
                TabItem(title: "Overdue Inspection", subtitle: "148 Chambers St", color: .red, isHighlighted: true),
                TabItem(title: "Compliance Issue", subtitle: "Rubin Museum", color: .orange)
            ]
        ))
        
        updateTabData("workers", TabContentData(
            summary: "4 active workers",
            items: [
                TabItem(title: "Kevin Dutan", subtitle: "148 Chambers St", value: "Active", color: .green),
                TabItem(title: "Edwin Lema", subtitle: "Rubin Museum", value: "Active", color: .green)
            ]
        ))
        
        updateTabData("portfolio", TabContentData(
            summary: "17 properties",
            items: [
                TabItem(title: "Total Properties", value: "17", color: .blue),
                TabItem(title: "Compliance Rate", value: "92%", color: .green)
            ],
            actions: [
                TabAction(title: "Open Map", icon: "map", isPrimary: true) { self.openMapFullScreen() }
            ]
        ))
        
        updateTabData("analytics", TabContentData(
            summary: "Portfolio health: 92%",
            items: [
                TabItem(title: "Compliance Score", value: "92%", color: .green),
                TabItem(title: "Monthly Budget", value: "$10,000", color: .blue),
                TabItem(title: "Current Spend", value: "$8,200", color: .orange)
            ]
        ))
    }
    
    private func setupAdminDataSources() {
        updateTabData("priorities", TabContentData(
            summary: "5 critical issues",
            items: [
                TabItem(title: "DSNY Violations", value: "3", color: .red, isHighlighted: true),
                TabItem(title: "Missed Inspections", value: "2", color: .orange)
            ]
        ))
        
        updateTabData("workers", TabContentData(
            summary: "7 workers active",
            items: [
                TabItem(title: "Clock Issues", value: "2", color: .orange),
                TabItem(title: "Late Starts", value: "1", color: .yellow),
                TabItem(title: "Missing Photos", value: "3", color: .red)
            ]
        ))
        
        updateTabData("buildings", TabContentData(
            summary: "21 buildings managed",
            items: [
                TabItem(title: "Compliant", value: "18", color: .green),
                TabItem(title: "Issues", value: "3", color: .red, isHighlighted: true)
            ],
            actions: [
                TabAction(title: "View Map", icon: "map") { self.openMapFullScreen() }
            ]
        ))
        
        updateTabData("analytics", TabContentData(
            summary: "Org performance: 87%",
            items: [
                TabItem(title: "Completion Rate", value: "87%", color: .green),
                TabItem(title: "Worker Efficiency", value: "82%", color: .blue),
                TabItem(title: "Budget Utilization", value: "89%", color: .purple)
            ]
        ))
    }
    
    private func updateTabData(_ tabKey: String, _ data: TabContentData) {
        tabData[tabKey] = data
    }
}

// MARK: - Preview Data

#if DEBUG
public extension IntelligencePanelModel {
    static func preview(role: CoreTypes.UserRole) -> IntelligencePanelModel {
        return IntelligencePanelModel(userRole: role)
    }
}
#endif
