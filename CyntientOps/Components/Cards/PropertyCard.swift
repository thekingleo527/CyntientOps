//
//  PropertyCard.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Glass morphism effects using CyntientOpsDesign
//  ✅ FIXED: Consistent dark theme styling
//  ✅ ALIGNED: With CoreTypes.BuildingMetrics properties
//

import SwiftUI

struct PropertyCard: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let mode: PropertyCardMode
    let onTap: () -> Void
    
    enum PropertyCardMode {
        case worker
        case admin
        case client
    }
    
    @State private var isPressed = false
    private let imageSize: CGFloat = 60
    
    var body: some View {
        Button(action: {
            withAnimation(CyntientOpsDesign.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(CyntientOpsDesign.Animations.quick) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: CyntientOpsDesign.Spacing.md) {
                buildingImage
                buildingContent
                Spacer()
                chevron
            }
            .francoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                    .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                            .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            )
            .francoShadow(CyntientOpsDesign.Shadow.sm)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buildingImage: some View {
        Group {
            if let image = UIImage(named: buildingImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .cornerRadius(CyntientOpsDesign.CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                            .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            } else {
                // Fallback placeholder with gradient
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: CyntientOpsDesign.DashboardColors.workerHeroGradient.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: imageSize * 0.4))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                            .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            }
        }
    }
    
    private var buildingContent: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            Text(building.name)
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(2)
            
            switch mode {
            case .worker:
                workerContent
            case .admin:
                adminContent
            case .client:
                clientContent
            }
        }
    }
    
    private var workerContent: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            if let metrics = metrics {
                HStack {
                    Label("Portfolio", systemImage: "building.2.fill")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text(metrics.pendingTasks > 0 ? "\(metrics.pendingTasks) remaining" : "All complete")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(metrics.pendingTasks > 0 ?
                            CyntientOpsDesign.DashboardColors.info :
                            CyntientOpsDesign.DashboardColors.success
                        )
                }
                
                // Progress bar
                FrancoMetricsProgress(value: metrics.completionRate, role: .worker)
                    .frame(height: CyntientOpsDesign.MetricsDisplay.progressBarHeight)
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
        }
    }
    
    private var adminContent: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            if let metrics = metrics {
                HStack {
                    Label("Efficiency", systemImage: "chart.line.uptrend.xyaxis")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(metrics.maintenanceEfficiency * 100))%")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(efficiencyColor)
                }
                
                HStack {
                    Label("Workers", systemImage: "person.3.fill")
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                    
                    Text("\(metrics.activeWorkers)")
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                
                if metrics.overdueTasks > 0 {
                    HStack {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                        
                        Spacer()
                        
                        Text("\(metrics.overdueTasks)")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                    }
                }
            } else {
                FrancoLoadingView(message: "Loading metrics...", role: .admin)
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var clientContent: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            if let metrics = metrics {
                HStack {
                    Label("Compliance", systemImage: "checkmark.shield.fill")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text(metrics.isCompliant ? "Compliant" : "Review Needed")
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(metrics.isCompliant ?
                            CyntientOpsDesign.DashboardColors.compliant :
                            CyntientOpsDesign.DashboardColors.warning
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((metrics.isCompliant ?
                                    CyntientOpsDesign.DashboardColors.compliant :
                                    CyntientOpsDesign.DashboardColors.warning
                                ).opacity(0.15))
                        )
                }
                
                HStack {
                    Label("Score", systemImage: "star.fill")
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(
                                    index < Int(metrics.overallScore) ?
                                    CyntientOpsDesign.DashboardColors.warning :
                                    CyntientOpsDesign.DashboardColors.inactive
                                )
                        }
                        Text(String(format: "%.1f", metrics.overallScore))
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                }
                
                if metrics.urgentTasksCount > 0 {
                    HStack {
                        Label("Urgent", systemImage: "flag.fill")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                        
                        Spacer()
                        
                        Text("\(metrics.urgentTasksCount)")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                    }
                }
            } else {
                FrancoLoadingView(message: "Loading compliance...", role: .client)
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            .padding(8)
            .background(
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
            )
    }
    
    // MARK: - Helper Properties
    
    private var buildingImageName: String {
        switch building.id {
        case "1": return "12_West_18th_Street"
        case "2": return "29_East_20th_Street"
        case "3": return "135West17thStreet"
        case "4": return "104_Franklin_Street"
        case "5": return "138West17thStreet"
        case "6": return "68_Perry_Street"
        case "7": return "112_West_18th_Street"
        case "8": return "41_Elizabeth_Street"
        case "9": return "117_West_17th_Street"
        case "10": return "131_Perry_Street"
        case "11": return "123_1st_Avenue"
        case "13": return "136_West_17th_Street"
        case "14": return "Rubin_Museum_142_148_West_17th_Street"
        case "15": return "133_East_15th_Street"
        case "16": return "Stuyvesant_Cove_Park"
        case "17": return "178_Spring_Street"
        case "18": return "36_Walker_Street"
        case "19": return "115_7th_Avenue"
        case "20": return "CyntientOps_HQ"
        default:
            print("⚠️ No image found for building ID: \(building.id)")
            return "building_placeholder"
        }
    }
    
    private var efficiencyColor: Color {
        guard let metrics = metrics else { return CyntientOpsDesign.DashboardColors.inactive }
        return CyntientOpsDesign.EnumColors.trendDirection(
            metrics.maintenanceEfficiency >= 0.9 ? .up :
            metrics.maintenanceEfficiency >= 0.7 ? .stable : .down
        )
    }
}

// MARK: - Mini Property Card (for lists)

struct MiniPropertyCard: View {
    let building: NamedCoordinate
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: CyntientOpsDesign.Spacing.sm) {
                // Building icon
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryAction)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(CyntientOpsDesign.DashboardColors.secondaryAction.opacity(0.15))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.name)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(CyntientOpsDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                    .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

struct PropertyCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                // Worker mode
                PropertyCard(
                    building: NamedCoordinate(
                        id: "14",
                        name: "Rubin Museum of Art",
                        latitude: 40.7401,
                        longitude: -73.9978
                    ),
                    metrics: BuildingMetrics(
                        buildingId: "14",
                        completionRate: 0.75,
                        overdueTasks: 1,
                        totalTasks: 12,
                        activeWorkers: 2,
                        overallScore: 4.2,
                        pendingTasks: 3,
                        urgentTasksCount: 1
                    ),
                    mode: .worker,
                    onTap: {}
                )
                
                // Admin mode
                PropertyCard(
                    building: NamedCoordinate(
                        id: "1",
                        name: "12 West 18th Street",
                        latitude: 40.7389,
                        longitude: -73.9936
                    ),
                    metrics: BuildingMetrics(
                        buildingId: "1",
                        completionRate: 0.92,
                        overdueTasks: 0,
                        totalTasks: 8,
                        activeWorkers: 3,
                        overallScore: 4.8,
                        pendingTasks: 1,
                        urgentTasksCount: 0,
                        maintenanceEfficiency: 0.88
                    ),
                    mode: .admin,
                    onTap: {}
                )
                
                // Client mode
                PropertyCard(
                    building: NamedCoordinate(
                        id: "16",
                        name: "Stuyvesant Cove Park",
                        latitude: 40.7335,
                        longitude: -73.9745
                    ),
                    metrics: BuildingMetrics(
                        buildingId: "16",
                        completionRate: 1.0,
                        overdueTasks: 0,
                        totalTasks: 5,
                        activeWorkers: 1,
                        isCompliant: true,
                        overallScore: 5.0,
                        pendingTasks: 0,
                        urgentTasksCount: 0
                    ),
                    mode: .client,
                    onTap: {}
                )
                
                // Loading state
                PropertyCard(
                    building: NamedCoordinate(
                        id: "999",
                        name: "Loading Building",
                        latitude: 0,
                        longitude: 0
                    ),
                    metrics: nil,
                    mode: .worker,
                    onTap: {}
                )
                
                // Mini cards
                VStack(spacing: 8) {
                    Text("Mini Cards")
                        .francoTypography(CyntientOpsDesign.Typography.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    MiniPropertyCard(
                        building: NamedCoordinate(
                            id: "1",
                            name: "12 West 18th Street",
                            latitude: 40.7389,
                            longitude: -73.9936
                        ),
                        subtitle: "3 tasks remaining",
                        onTap: {}
                    )
                    
                    MiniPropertyCard(
                        building: NamedCoordinate(
                            id: "14",
                            name: "Rubin Museum",
                            latitude: 40.7401,
                            longitude: -73.9978
                        ),
                        subtitle: "All tasks complete",
                        onTap: {}
                    )
                }
                .padding(.top)
            }
            .padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
