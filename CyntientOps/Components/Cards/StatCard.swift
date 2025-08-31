//
//
//  StatCard.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Glass morphism effects
//  ✅ ALIGNED: With CyntientOpsDesign system
//  ✅ IMPROVED: Trend indicators and animations
//  ✅ FIXED: Renamed to avoid redeclaration conflicts
//

import SwiftUI

// MARK: - Enhanced Stat Card (Renamed to avoid conflict)

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let trend: String?
    let icon: String
    var color: Color = CyntientOpsDesign.DashboardColors.primaryAction
    var trendDirection: CoreTypes.TrendDirection? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.sm) {
            // Header row
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.25), lineWidth: 1)
                            )
                    )
                
                Spacer()
                
                if let trend = trend {
                    trendIndicator(trend)
                } else if let direction = trendDirection {
                    advancedTrendIndicator(direction)
                }
            }
            
            // Value
            Text(value)
                .francoTypography(CyntientOpsDesign.Typography.largeTitle)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Title
            Text(title)
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .lineLimit(2)
        }
        .francoCardPadding()
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .animation(CyntientOpsDesign.Animations.quick, value: isPressed)
    }
    
    // Basic trend indicator (legacy support)
    private func trendIndicator(_ trend: String) -> some View {
        HStack(spacing: 4) {
            if trend.contains("↑") || trend.contains("up") {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            } else if trend.contains("↓") || trend.contains("down") {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
            } else {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            }
            
            Text(trend.replacingOccurrences(of: "↑", with: "")
                    .replacingOccurrences(of: "↓", with: "")
                    .trimmingCharacters(in: .whitespaces))
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .font(.caption)
    }
    
    // Advanced trend indicator using CoreTypes
    private func advancedTrendIndicator(_ direction: CoreTypes.TrendDirection) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon(for: direction))
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.EnumColors.trendDirection(direction))
            
            Text(direction.rawValue.capitalized)
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .foregroundColor(CyntientOpsDesign.EnumColors.trendDirection(direction))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(CyntientOpsDesign.EnumColors.trendDirection(direction).opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(CyntientOpsDesign.EnumColors.trendDirection(direction).opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    private func trendIcon(for direction: CoreTypes.TrendDirection) -> String {
        switch direction {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .improving: return "arrow.up.right.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Pressable Version

struct PressableStatCard: View {
    let title: String
    let value: String
    let trend: String?
    let icon: String
    var color: Color = CyntientOpsDesign.DashboardColors.primaryAction
    var trendDirection: CoreTypes.TrendDirection? = nil
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        EnhancedStatCard(
            title: title,
            value: value,
            trend: trend,
            icon: icon,
            color: color,
            trendDirection: trendDirection
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(CyntientOpsDesign.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(CyntientOpsDesign.Animations.quick) {
                    isPressed = false
                }
                onTap()
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Compact Version for Dashboards

struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = CyntientOpsDesign.DashboardColors.primaryAction
    
    var body: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(title)
                    .francoTypography(CyntientOpsDesign.Typography.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
        }
        .padding(CyntientOpsDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
        )
    }
}

// MARK: - Type Alias for Backward Compatibility
// If you have existing code using StatCard, you can uncomment this:
typealias StatCard = EnhancedStatCard

