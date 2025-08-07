//
//  BuildingStatsGlassCard.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Integrated with CyntientOpsDesign color system
//  ✅ IMPROVED: Glass effects optimized for dark theme
//  ✅ FIXED: All exhaustive switch errors resolved
//

import SwiftUI

struct BuildingStatsGlassCard: View {
    let pendingTasksCount: Int
    let completedTasksCount: Int
    let assignedWorkersCount: Int
    let weatherRisk: WeatherRiskLevel
    
    @State private var isAnimating = false
    
    enum WeatherRiskLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
        
        var color: Color {
            switch self {
            case .low:
                return CyntientOpsDesign.DashboardColors.success
            case .medium:
                return CyntientOpsDesign.DashboardColors.warning
            case .high:
                return CyntientOpsDesign.DashboardColors.warning
            case .extreme:
                return CyntientOpsDesign.DashboardColors.critical
            }
        }
        
        var icon: String {
            switch self {
            case .low:
                return "sun.max.fill"
            case .medium:
                return "cloud.sun.fill"
            case .high:
                return "cloud.rain.fill"
            case .extreme:
                return "cloud.bolt.rain.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Stats Grid
            statsGrid
            
            // Progress breakdown
            if pendingTasksCount > 0 {
                priorityBreakdown
            }
            
            // Bottom stats
            bottomStats
        }
        .padding(20)
        .background(darkGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(glassOverlayBorder)
        .shadow(
            color: CyntientOpsDesign.DashboardColors.baseBackground.opacity(0.3),
            radius: 15,
            x: 0,
            y: 8
        )
        .onAppear {
            withAnimation(CyntientOpsDesign.Animations.spring.delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        HStack {
            Text("Building Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
            
            weatherIndicator
        }
    }
    
    private var weatherIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: weatherRisk.icon)
                .font(.caption)
                .foregroundColor(weatherRisk.color)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(weatherRisk.color)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(weatherRisk.color.opacity(0.3), lineWidth: 8)
                            .scaleEffect(1.5)
                            .opacity(isAnimating ? 0.6 : 0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    )
                
                Text(weatherRisk.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(weatherRisk.color.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatItemView(
                title: "Pending",
                value: "\(pendingTasksCount)",
                color: pendingTasksColor,
                icon: "clock.fill"
            )
            
            StatItemView(
                title: "Completed",
                value: "\(completedTasksCount)",
                color: CyntientOpsDesign.DashboardColors.success,
                icon: "checkmark.circle.fill"
            )
        }
    }
    
    private var priorityBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority Breakdown")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            HStack(spacing: 12) {
                PriorityItem(
                    count: getHighPriorityCount(),
                    label: "High",
                    color: CyntientOpsDesign.DashboardColors.critical
                )
                
                PriorityItem(
                    count: getMediumPriorityCount(),
                    label: "Med",
                    color: CyntientOpsDesign.DashboardColors.warning
                )
                
                PriorityItem(
                    count: getLowPriorityCount(),
                    label: "Low",
                    color: CyntientOpsDesign.DashboardColors.info
                )
            }
        }
        .padding(12)
        .background(CyntientOpsDesign.DashboardColors.glassOverlay)
        .cornerRadius(12)
    }
    
    private var bottomStats: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                
                Text("Workers: \(assignedWorkersCount)")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                CircularProgressIndicator(progress: getCompletionProgress())
                
                Text("\(getCompletionRate())% Complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
        }
    }
    
    // MARK: - Background Components
    
    private var darkGlassBackground: some View {
        ZStack {
            // Dark base
            RoundedRectangle(cornerRadius: 20)
                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.9))
            
            // Glass material
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.3))
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.2),
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var glassOverlayBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Computed Properties
    
    private var pendingTasksColor: Color {
        switch pendingTasksCount {
        case 0:
            return CyntientOpsDesign.DashboardColors.success
        case 1...3:
            return .orange // Amber
        case 4...8:
            return CyntientOpsDesign.DashboardColors.warning
        default:
            return CyntientOpsDesign.DashboardColors.critical
        }
    }
    
    private func getHighPriorityCount() -> Int {
        max(1, pendingTasksCount / 4)
    }
    
    private func getMediumPriorityCount() -> Int {
        max(1, pendingTasksCount / 2)
    }
    
    private func getLowPriorityCount() -> Int {
        pendingTasksCount - getHighPriorityCount() - getMediumPriorityCount()
    }
    
    private func getCompletionRate() -> Int {
        let total = pendingTasksCount + completedTasksCount
        guard total > 0 else { return 0 }
        return Int((Double(completedTasksCount) / Double(total)) * 100)
    }
    
    private func getCompletionProgress() -> Double {
        let total = pendingTasksCount + completedTasksCount
        guard total > 0 else { return 0 }
        return Double(completedTasksCount) / Double(total)
    }
}

// MARK: - Sub-component Views

struct StatItemView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color.opacity(0.8))
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct PriorityItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
    }
}

struct CircularProgressIndicator: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(CyntientOpsDesign.DashboardColors.glassOverlay, lineWidth: 2)
                .frame(width: 16, height: 16)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress > 0.8 ? CyntientOpsDesign.DashboardColors.success :
                    progress > 0.5 ? CyntientOpsDesign.DashboardColors.warning :
                    CyntientOpsDesign.DashboardColors.critical,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Preview

struct BuildingStatsGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                BuildingStatsGlassCard(
                    pendingTasksCount: 8,
                    completedTasksCount: 12,
                    assignedWorkersCount: 3,
                    weatherRisk: .medium
                )
                
                BuildingStatsGlassCard(
                    pendingTasksCount: 2,
                    completedTasksCount: 15,
                    assignedWorkersCount: 1,
                    weatherRisk: .low
                )
                
                BuildingStatsGlassCard(
                    pendingTasksCount: 15,
                    completedTasksCount: 5,
                    assignedWorkersCount: 4,
                    weatherRisk: .extreme
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
