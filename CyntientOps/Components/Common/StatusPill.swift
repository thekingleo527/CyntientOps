//
//  StatusPill.swift
//  CyntientOps (formerly CyntientOps)
//
//  Extracted from CoverageInfoCard.swift - Reusable Status Indicator Component
//  ✅ RENAMED: From CoverageStatusPill to avoid conflicts
//  ✅ ENHANCED: Multiple styles, animations, predefined status types
//  ✅ INTEGRATED: CyntientOpsDesign system
//

import SwiftUI

public struct StatusPill: View {
    
    // MARK: - Properties
    
    let text: String
    let icon: String?
    let color: Color
    let style: PillStyle
    let showPulse: Bool
    
    // MARK: - State
    
    @State private var pulseAnimation = false
    
    // MARK: - Initialization
    
    public init(
        text: String,
        icon: String? = nil,
        color: Color,
        style: PillStyle = .filled,
        showPulse: Bool = false
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.style = style
        self.showPulse = showPulse
    }
    
    // Convenience initializer for predefined status types
    public init(_ status: StatusType) {
        self.text = status.displayText
        self.icon = status.icon
        self.color = status.color
        self.style = status.preferredStyle
        self.showPulse = status.shouldPulse
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 4) {
            // Icon (if provided)
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: style.iconSize))
                    .foregroundColor(iconColor)
            }
            
            // Status text
            Text(text)
                .francoTypography(style.typography)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, style.verticalPadding)
        .background(backgroundView)
        .overlay(overlayView)
        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
        .animation(
            showPulse ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .none,
            value: pulseAnimation
        )
        .onAppear {
            if showPulse {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var textColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined, .subtle:
            return color
        }
    }
    
    private var iconColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined, .subtle:
            return color
        }
    }
    
    private var backgroundView: some View {
        Capsule()
            .fill(backgroundColor)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return color
        case .outlined:
            return Color.clear
        case .subtle:
            return color.opacity(0.15)
        }
    }
    
    private var overlayView: some View {
        Group {
            switch style {
            case .outlined:
                Capsule()
                    .stroke(color.opacity(0.6), lineWidth: 1)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Pill Style

public enum PillStyle {
    case filled
    case outlined
    case subtle
    
    var typography: CyntientOpsDesign.Typography.FontStyle {
        return CyntientOpsDesign.Typography.caption2
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .filled: return 8
        case .outlined: return 8
        case .subtle: return 6
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .filled: return 4
        case .outlined: return 4
        case .subtle: return 3
        }
    }
    
    var iconSize: CGFloat {
        return 8
    }
}

// MARK: - Predefined Status Types

public enum StatusType {
    // Worker statuses
    case available
    case busy
    case clockedIn
    case clockedOut
    case onBreak
    case emergency
    
    // Task statuses
    case pending
    case inProgress
    case completed
    case overdue
    case cancelled
    
    // Building statuses  
    case operational
    case maintenance
    case offline
    case critical
    
    // Compliance statuses
    case compliant
    case warning
    case violation
    case expiring
    
    // System statuses
    case online
    case syncing
    case error
    case unknown
    
    var displayText: String {
        switch self {
        // Worker statuses
        case .available: return "Available"
        case .busy: return "Busy"
        case .clockedIn: return "Clocked In"
        case .clockedOut: return "Clocked Out"
        case .onBreak: return "On Break"
        case .emergency: return "Emergency"
            
        // Task statuses
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
            
        // Building statuses
        case .operational: return "Operational"
        case .maintenance: return "Maintenance"
        case .offline: return "Offline"
        case .critical: return "Critical"
            
        // Compliance statuses
        case .compliant: return "Compliant"
        case .warning: return "Warning"
        case .violation: return "Violation"
        case .expiring: return "Expiring"
            
        // System statuses
        case .online: return "Online"
        case .syncing: return "Syncing"
        case .error: return "Error"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String? {
        switch self {
        // Worker statuses
        case .available: return "circle.fill"
        case .busy: return "circle.fill"
        case .clockedIn: return "clock.fill"
        case .clockedOut: return "clock"
        case .onBreak: return "pause.circle.fill"
        case .emergency: return "exclamationmark.triangle.fill"
            
        // Task statuses
        case .pending: return "clock"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
            
        // Building statuses
        case .operational: return "checkmark.circle.fill"
        case .maintenance: return "wrench.fill"
        case .offline: return "wifi.slash"
        case .critical: return "exclamationmark.triangle.fill"
            
        // Compliance statuses
        case .compliant: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .violation: return "xmark.shield.fill"
        case .expiring: return "clock.badge.exclamationmark.fill"
            
        // System statuses
        case .online: return "wifi"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        // Worker statuses
        case .available, .clockedIn:
            return CyntientOpsDesign.DashboardColors.success
        case .busy, .onBreak:
            return CyntientOpsDesign.DashboardColors.warning
        case .clockedOut:
            return CyntientOpsDesign.DashboardColors.secondaryText
        case .emergency:
            return CyntientOpsDesign.DashboardColors.critical
            
        // Task statuses
        case .pending:
            return CyntientOpsDesign.DashboardColors.info
        case .inProgress:
            return CyntientOpsDesign.DashboardColors.warning
        case .completed:
            return CyntientOpsDesign.DashboardColors.success
        case .overdue, .cancelled:
            return CyntientOpsDesign.DashboardColors.critical
            
        // Building statuses
        case .operational:
            return CyntientOpsDesign.DashboardColors.success
        case .maintenance:
            return CyntientOpsDesign.DashboardColors.warning
        case .offline:
            return CyntientOpsDesign.DashboardColors.secondaryText
        case .critical:
            return CyntientOpsDesign.DashboardColors.critical
            
        // Compliance statuses
        case .compliant:
            return CyntientOpsDesign.DashboardColors.success
        case .warning, .expiring:
            return CyntientOpsDesign.DashboardColors.warning
        case .violation:
            return CyntientOpsDesign.DashboardColors.critical
            
        // System statuses
        case .online:
            return CyntientOpsDesign.DashboardColors.success
        case .syncing:
            return CyntientOpsDesign.DashboardColors.info
        case .error:
            return CyntientOpsDesign.DashboardColors.critical
        case .unknown:
            return CyntientOpsDesign.DashboardColors.tertiaryText
        }
    }
    
    var preferredStyle: PillStyle {
        switch self {
        case .emergency, .critical, .violation, .overdue, .error:
            return .filled
        case .warning, .expiring, .maintenance, .busy:
            return .subtle
        default:
            return .outlined
        }
    }
    
    var shouldPulse: Bool {
        switch self {
        case .emergency, .critical, .syncing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Status Pill Group (For displaying multiple statuses)

public struct StatusPillGroup: View {
    let statuses: [StatusType]
    let alignment: HorizontalAlignment
    
    public init(_ statuses: [StatusType], alignment: HorizontalAlignment = .leading) {
        self.statuses = statuses
        self.alignment = alignment
    }
    
    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80), spacing: 4)],
            alignment: alignment,
            spacing: 4
        ) {
            ForEach(Array(statuses.enumerated()), id: \.offset) { _, status in
                StatusPill(status)
            }
        }
    }
}

// MARK: - Extensions for Common Use Cases

extension StatusPill {
    
    /// Create a status pill for worker clock-in status
    public static func workerClockStatus(_ isClocked: Bool) -> Self {
        return Self(isClocked ? .clockedIn : .clockedOut)
    }
    
    /// Create a status pill for task completion status
    public static func taskStatus(_ isCompleted: Bool, isOverdue: Bool = false) -> Self {
        if isCompleted {
            return Self(.completed)
        } else if isOverdue {
            return Self(.overdue)
        } else {
            return Self(.pending)
        }
    }
    
    /// Create a status pill for building operational status
    public static func buildingStatus(_ isOperational: Bool, hasCriticalIssues: Bool = false) -> Self {
        if hasCriticalIssues {
            return Self(.critical)
        } else if isOperational {
            return Self(.operational)
        } else {
            return Self(.maintenance)
        }
    }
}

// MARK: - Preview

struct StatusPill_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.lg) {
            // Different styles
            VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.sm) {
                Text("Different Styles")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                
                HStack(spacing: CyntientOpsDesign.Spacing.sm) {
                    StatusPill(text: "Available", icon: "circle.fill", color: .green, style: .filled)
                    StatusPill(text: "Available", icon: "circle.fill", color: .green, style: .outlined)
                    StatusPill(text: "Available", icon: "circle.fill", color: .green, style: .subtle)
                }
            }
            
            // Predefined status types
            VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.sm) {
                Text("Worker Statuses")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                
                HStack(spacing: CyntientOpsDesign.Spacing.sm) {
                    StatusPill(.available)
                    StatusPill(.busy)
                    StatusPill(.clockedIn)
                    StatusPill(.emergency)
                }
            }
            
            // Task statuses
            VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.sm) {
                Text("Task Statuses")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                
                HStack(spacing: CyntientOpsDesign.Spacing.sm) {
                    StatusPill(.pending)
                    StatusPill(.inProgress)
                    StatusPill(.completed)
                    StatusPill(.overdue)
                }
            }
            
            // Status pill group
            VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.sm) {
                Text("Status Group")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                
                StatusPillGroup([.operational, .compliant, .online, .syncing])
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}