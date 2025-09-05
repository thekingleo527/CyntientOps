
//
//  ClientDashboardPortfolioHeroCard.swift
//  CyntientOps v7.0
//
//  ✅ REAL DATA: Shows actual worker routines at client buildings
//  ✅ GLASSMORPHISM: Uses CyntientOps design system with GlassCard
//  ✅ OPERATIONAL: Real OperationalDataManager integration
//

import SwiftUI

public struct ClientDashboardPortfolioHeroCard: View {
    let portfolioHealth: CoreTypes.PortfolioHealth
    let realtimeMetrics: CoreTypes.RealtimeMetrics
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    let onDrillDown: () -> Void
    
    public var body: some View {
        GlassCard(
            intensity: .regular,
            cornerRadius: CyntientOpsDesign.CornerRadius.glassCard,
            padding: CyntientOpsDesign.Spacing.cardPadding
        ) {
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                // Header with drill-down action
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portfolio Performance")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        Text("\(portfolioHealth.totalBuildings) Buildings • \(portfolioHealth.activeBuildings) Active")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: onDrillDown) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.workerAccent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Performance Ring with Real Metrics
                HStack(spacing: CyntientOpsDesign.Spacing.lg) {
                    // Health Score Ring
                    ZStack {
                        Circle()
                            .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 6)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: portfolioHealth.overallScore)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        CyntientOpsDesign.DashboardColors.workerPrimary,
                                        CyntientOpsDesign.DashboardColors.workerAccent
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(Int(portfolioHealth.overallScore * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Text("Health")
                                .font(.caption2)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                    }
                    
                    // Real-time Metrics from OperationalDataManager
                    VStack(spacing: CyntientOpsDesign.Spacing.sm) {
                        ClientPortfolioMetric(
                            title: "Critical Issues",
                            value: "\(portfolioHealth.criticalIssues)",
                            color: portfolioHealth.criticalIssues == 0 ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.critical
                        )
                        
                        ClientPortfolioMetric(
                            title: "Budget Used",
                            value: monthlyMetrics.monthlyBudget > 0 ? "\(Int(monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget * 100))%" : "N/A",
                            color: CyntientOpsDesign.DashboardColors.workerAccent
                        )
                        
                        ClientPortfolioMetric(
                            title: "Trend",
                            value: portfolioHealth.trend.rawValue.capitalized,
                            color: portfolioHealth.trend == .improving ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning
                        )
                    }
                }
                
                // Last update timestamp
                HStack {
                    Spacer()
                    Text("Updated \(formatTimeAgo(portfolioHealth.lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
