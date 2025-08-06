//
//  WorkerAvatar.swift
//  CyntientOps (formerly CyntientOps)
//
//  Extracted from CoverageInfoCard.swift - Reusable Worker Avatar Component
//  ✅ ENHANCED: Multiple sizes, status indicators, customizable styling
//  ✅ INTEGRATED: CyntientOpsDesign system
//

import SwiftUI

public struct WorkerAvatar: View {
    
    // MARK: - Properties
    
    let workerName: String
    let size: AvatarSize
    let showStatus: Bool
    let status: CoreTypes.WorkerStatus?
    let customGradient: [Color]?
    
    // MARK: - Initialization
    
    public init(
        workerName: String,
        size: AvatarSize = .medium,
        showStatus: Bool = false,
        status: CoreTypes.WorkerStatus? = nil,
        customGradient: [Color]? = nil
    ) {
        self.workerName = workerName
        self.size = size
        self.showStatus = showStatus
        self.status = status
        self.customGradient = customGradient
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Main avatar circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.diameter, height: size.diameter)
            
            // Worker initials
            Text(workerInitials)
                .francoTypography(size.typography)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Status indicator overlay
            if showStatus, let status = status {
                statusIndicator(status)
            }
        }
        .francoShadow(size.shadow)
    }
    
    // MARK: - Private Computed Properties
    
    private var workerInitials: String {
        let components = workerName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if let first = components.first {
            return String(first.prefix(2))
        }
        return "?"
    }
    
    private var gradientColors: [Color] {
        if let custom = customGradient {
            return custom
        }
        
        // Generate consistent colors based on worker name
        return getWorkerGradient(for: workerName)
    }
    
    // MARK: - Status Indicator
    
    private func statusIndicator(_ status: CoreTypes.WorkerStatus) -> some View {
        HStack {
            Spacer()
            VStack {
                Circle()
                    .fill(status.color)
                    .frame(width: size.statusSize, height: size.statusSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: size.statusBorderWidth)
                    )
                Spacer()
            }
        }
    }
    
    // MARK: - Worker-Specific Gradients
    
    private func getWorkerGradient(for name: String) -> [Color] {
        switch name {
        case "Kevin Dutan":
            return [Color.blue, Color.cyan]  // Rubin Museum specialist - cool blues
            
        case "Edwin Lema":
            return [Color.green, Color.mint]  // Stuyvesant Cove - nature greens
            
        case "Mercedes Inamagua":
            return [Color.purple, Color.pink]  // Glass cleaning - elegant purples
            
        case "Luis Lopez":
            return [Color.orange, Color.yellow]  // Perry Street - warm oranges
            
        case "Angel Guiracocha":
            return [Color.indigo, Color.blue]  // Evening shift - night blues
            
        case "Shawn Magloire":
            return [Color.red, Color.orange]  // HVAC/Advanced - technical reds
            
        case "Greg Hutson":
            return [Color.gray, Color.secondary]  // Manager - neutral grays
            
        default:
            // Fallback to CyntientOps design gradient
            return CyntientOpsDesign.DashboardColors.workerHeroGradient
        }
    }
}

// MARK: - Avatar Size Configuration

public enum AvatarSize {
    case small
    case medium
    case large
    case extraLarge
    
    var diameter: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 60
        case .extraLarge: return 80
        }
    }
    
    var typography: CyntientOpsDesign.Typography.FontStyle {
        switch self {
        case .small: return CyntientOpsDesign.Typography.caption
        case .medium: return CyntientOpsDesign.Typography.callout
        case .large: return CyntientOpsDesign.Typography.title3
        case .extraLarge: return CyntientOpsDesign.Typography.title2
        }
    }
    
    var shadow: CyntientOpsDesign.Shadow.ShadowStyle {
        switch self {
        case .small: return CyntientOpsDesign.Shadow.sm
        case .medium: return CyntientOpsDesign.Shadow.md
        case .large: return CyntientOpsDesign.Shadow.lg
        case .extraLarge: return CyntientOpsDesign.Shadow.xl
        }
    }
    
    var statusSize: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 14
        case .extraLarge: return 18
        }
    }
    
    var statusBorderWidth: CGFloat {
        switch self {
        case .small: return 1.5
        case .medium: return 2
        case .large: return 2.5
        case .extraLarge: return 3
        }
    }
}

// MARK: - Worker Status

// Note: Using CoreTypes.WorkerStatus instead of local enum

// MARK: - Worker Avatar Group (For displaying multiple workers)

public struct WorkerAvatarGroup: View {
    let workers: [String]
    let maxVisible: Int
    let size: AvatarSize
    
    public init(workers: [String], maxVisible: Int = 3, size: AvatarSize = .medium) {
        self.workers = workers
        self.maxVisible = maxVisible
        self.size = size
    }
    
    public var body: some View {
        HStack(spacing: -8) {  // Overlapping effect
            ForEach(Array(workers.prefix(maxVisible).enumerated()), id: \.offset) { index, worker in
                WorkerAvatar(workerName: worker, size: size)
                    .zIndex(Double(maxVisible - index))  // Layer properly
            }
            
            // "+X more" indicator if there are additional workers
            if workers.count > maxVisible {
                moreWorkersIndicator
            }
        }
    }
    
    private var moreWorkersIndicator: some View {
        Circle()
            .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
            .frame(width: size.diameter, height: size.diameter)
            .overlay(
                Text("+\(workers.count - maxVisible)")
                    .francoTypography(size.typography)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            )
            .overlay(
                Circle()
                    .stroke(CyntientOpsDesign.DashboardColors.tertiaryText.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Worker Info Row (Extracted from CoverageInfoCard)

public struct WorkerInfoRow: View {
    let workerName: String
    let subtitle: String
    let status: CoreTypes.WorkerStatus?
    let showAvatar: Bool
    
    public init(
        workerName: String,
        subtitle: String = "Worker",
        status: CoreTypes.WorkerStatus? = nil,
        showAvatar: Bool = true
    ) {
        self.workerName = workerName
        self.subtitle = subtitle
        self.status = status
        self.showAvatar = showAvatar
    }
    
    public var body: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.sm) {
            // Worker avatar
            if showAvatar {
                WorkerAvatar(
                    workerName: workerName,
                    size: .medium,
                    showStatus: status != nil,
                    status: status
                )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workerName)
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(subtitle)
                    .francoTypography(CyntientOpsDesign.Typography.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            // Status text if available
            if let status = status {
                Text(status.displayText)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(status.color.opacity(0.15))
                    )
            }
        }
    }
}

// MARK: - Preview

struct WorkerAvatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.lg) {
            // Different sizes
            HStack(spacing: CyntientOpsDesign.Spacing.md) {
                WorkerAvatar(workerName: "Kevin Dutan", size: .small)
                WorkerAvatar(workerName: "Kevin Dutan", size: .medium)
                WorkerAvatar(workerName: "Kevin Dutan", size: .large)
                WorkerAvatar(workerName: "Kevin Dutan", size: .extraLarge)
            }
            
            // With status indicators
            HStack(spacing: CyntientOpsDesign.Spacing.md) {
                WorkerAvatar(workerName: "Edwin Lema", showStatus: true, status: .available)
                WorkerAvatar(workerName: "Mercedes Inamagua", showStatus: true, status: .clockedIn)
                WorkerAvatar(workerName: "Luis Lopez", showStatus: true, status: .offline)
                WorkerAvatar(workerName: "Angel Guiracocha", showStatus: true, status: .onBreak)
            }
            
            // Worker avatar group
            WorkerAvatarGroup(workers: ["Kevin Dutan", "Edwin Lema", "Mercedes Inamagua", "Luis Lopez", "Angel Guiracocha"])
            
            // Worker info row
            VStack(spacing: CyntientOpsDesign.Spacing.sm) {
                WorkerInfoRow(workerName: "Kevin Dutan", subtitle: "Rubin Museum Specialist", status: .clockedIn)
                WorkerInfoRow(workerName: "Edwin Lema", subtitle: "Stuyvesant Cove", status: .available)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}

// MARK: - CoreTypes.WorkerStatus Extensions

extension CoreTypes.WorkerStatus {
    var color: Color {
        switch self {
        case .available, .clockedIn:
            return CyntientOpsDesign.DashboardColors.success
        case .onBreak:
            return CyntientOpsDesign.DashboardColors.warning
        case .offline:
            return CyntientOpsDesign.DashboardColors.secondaryText
        }
    }
    
    var displayText: String {
        return self.rawValue
    }
}