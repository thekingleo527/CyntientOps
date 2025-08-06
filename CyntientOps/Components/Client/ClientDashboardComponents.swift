//
//  ClientDashboardComponents.swift
//  CyntientOps Phase 4
//
//  All Client Dashboard Components in one file for efficiency
//

import SwiftUI

// MARK: - Client Dashboard Header (70px)

struct ClientDashboardHeader: View {
    let clientName: String
    let portfolioValue: Double
    let activeBuildings: Int
    let complianceScore: Int
    let onProfileTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Client Info
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(clientName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Portfolio Owner")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Key Metrics
            HStack(spacing: 16) {
                ClientHeaderMetric(
                    icon: "building.2",
                    value: "\(activeBuildings)",
                    label: "Buildings",
                    color: .blue
                )
                
                ClientHeaderMetric(
                    icon: "shield.checkered",
                    value: "\(complianceScore)%",
                    label: "Compliance",
                    color: complianceScore >= 90 ? .green : .orange
                )
                
                ClientHeaderMetric(
                    icon: "dollarsign.circle",
                    value: "$\(Int(portfolioValue/1000))K",
                    label: "Budget",
                    color: .cyan
                )
            }
            
            // Profile Button
            Button(action: onProfileTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct ClientHeaderMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Portfolio Hero Card (240px)

struct ClientDashboardPortfolioHeroCard: View {
    let portfolioHealth: CoreTypes.PortfolioHealth
    let realtimeMetrics: CoreTypes.RealtimePortfolioMetrics
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    let onDrillDown: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Performance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(portfolioHealth.totalBuildings) Buildings • \(portfolioHealth.activeBuildings) Active")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onDrillDown) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            
            // Main Performance Ring
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: portfolioHealth.overallScore)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(portfolioHealth.overallScore * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Health")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(spacing: 12) {
                    ClientPortfolioMetric(
                        title: "Active Alerts",
                        value: "\(realtimeMetrics.activeAlerts)",
                        color: realtimeMetrics.activeAlerts > 0 ? .red : .green
                    )
                    
                    ClientPortfolioMetric(
                        title: "Monthly Spend",
                        value: "\(Int(monthlyMetrics.currentSpend/1000))K",
                        color: .cyan
                    )
                    
                    ClientPortfolioMetric(
                        title: "Trend",
                        value: portfolioHealth.trend.rawValue.capitalized,
                        color: portfolioHealth.trend == .improving ? .green : .orange
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct ClientPortfolioMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Building Grid Section

struct ClientBuildingGridSection: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onBuildingTap: (CoreTypes.NamedCoordinate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Building Performance")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(text: "\(buildings.count)", color: .blue, style: .outlined)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(buildings.prefix(4)) { building in
                    ClientBuildingCard(
                        building: building,
                        metrics: buildingMetrics[building.id],
                        onTap: { onBuildingTap(building) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}


// MARK: - Compliance Section

struct ClientComplianceSection: View {
    let complianceOverview: CoreTypes.ComplianceOverview
    let criticalAlerts: [CoreTypes.ClientAlert]
    let onComplianceDetail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compliance & Alerts")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(
                    text: "\(Int(complianceOverview.overallScore * 100))%",
                    color: complianceOverview.overallScore >= 0.9 ? .green : .orange,
                    style: .filled
                )
                
                Spacer()
                
                Button(action: onComplianceDetail) {
                    Text("Details")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(complianceOverview.criticalViolations)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(complianceOverview.criticalViolations > 0 ? .red : .green)
                    
                    Text("Critical Violations")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(criticalAlerts.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(criticalAlerts.count > 0 ? .orange : .green)
                    
                    Text("Active Alerts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(complianceOverview.overallScore >= 0.9 ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Cost Analysis Section

struct ClientCostAnalysisSection: View {
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    let costInsights: [CoreTypes.CostInsight]
    let estimatedSavings: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Analysis")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(Int(monthlyMetrics.currentSpend))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Current Spend")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("of $\(Int(monthlyMetrics.monthlyBudget)) budget")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if estimatedSavings > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(Int(estimatedSavings))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Potential Savings")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("per month")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Budget Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Budget Utilization")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int((monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget) * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cyan)
                            .frame(width: geometry.size.width * (monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#if DEBUG
struct ClientDashboardComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                ClientDashboardHeader(
                    clientName: "JM Realty Group",
                    portfolioValue: 125000,
                    activeBuildings: 9,
                    complianceScore: 94,
                    onProfileTap: {}
                )
                .frame(height: 70)
                
                ClientDashboardPortfolioHeroCard(
                    portfolioHealth: CoreTypes.PortfolioHealth(
                        overallScore: 0.85,
                        totalBuildings: 9,
                        activeBuildings: 9,
                        criticalIssues: 1,
                        trend: .improving,
                        lastUpdated: Date()
                    ),
                    realtimeMetrics: CoreTypes.RealtimePortfolioMetrics(
                        lastUpdateTime: Date(),
                        performanceTrend: [0.8, 0.82, 0.85],
                        recentActivities: [],
                        activeAlerts: 2,
                        pendingActions: 3
                    ),
                    monthlyMetrics: CoreTypes.MonthlyMetrics(
                        currentSpend: 45000,
                        monthlyBudget: 60000,
                        projectedSpend: 54000,
                        daysRemaining: 12
                    ),
                    onDrillDown: {}
                )
                .frame(height: 240)
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif