//
//  AdminHeroMetricsCard.swift
//  CyntientOps Phase 4
//
//  Hero metrics card showing key portfolio performance indicators
//  Fixed height 200px
//

import SwiftUI

struct AdminHeroMetricsCard: View {
    let portfolioSummary: AdminPortfolioSummary
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onDrillDown: () -> Void
    
    private var overallCompletion: Double {
        let metrics = Array(buildingMetrics.values)
        guard !metrics.isEmpty else { return 0.0 }
        return metrics.map { $0.completionRate }.reduce(0, +) / Double(metrics.count)
    }
    
    private var averageEfficiency: Double {
        let metrics = Array(buildingMetrics.values)
        guard !metrics.isEmpty else { return 0.0 }
        return metrics.map { $0.efficiency }.reduce(0, +) / Double(metrics.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Portfolio Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Overview")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(portfolioSummary.efficiencyDescription)
                        .font(.caption)
                        .foregroundColor(portfolioSummary.efficiencyStatus.color)
                }
                
                Spacer()
                
                Button(action: onDrillDown) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Main Metrics Grid
            HStack(spacing: 16) {
                // Completion Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: overallCompletion)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(overallCompletion * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Key Metrics
                VStack(spacing: 12) {
                    AdminHeroMetric(
                        icon: "checkmark.circle.fill",
                        title: "Tasks Today",
                        value: "\(portfolioSummary.completedTasks)",
                        subtitle: "Completed",
                        color: .green
                    )
                    
                    AdminHeroMetric(
                        icon: "shield.checkered",
                        title: "Compliance",
                        value: "\(Int(portfolioSummary.complianceScore * 100))%",
                        subtitle: "Score",
                        color: portfolioSummary.complianceScore > 0.8 ? .green : .orange
                    )
                }
                
                VStack(spacing: 12) {
                    AdminHeroMetric(
                        icon: "camera.fill",
                        title: "Photo Evidence",
                        value: "\(portfolioSummary.todaysPhotoCount)",
                        subtitle: "Today",
                        color: .blue
                    )
                    
                    AdminHeroMetric(
                        icon: "bolt.fill",
                        title: "Efficiency",
                        value: "\(Int(averageEfficiency * 100))%",
                        subtitle: "Average",
                        color: averageEfficiency > 0.8 ? .green : .orange
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
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AdminHeroMetric: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(subtitle) \(title)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
struct AdminHeroMetricsCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockSummary = AdminPortfolioSummary(
            totalBuildings: 18,
            totalWorkers: 8,
            activeWorkers: 6,
            totalTasks: 150,
            completedTasks: 124,
            pendingTasks: 26,
            criticalInsights: 3,
            completionRate: 0.78,
            averageTaskTime: 45.0,
            overdueTasks: 4,
            complianceScore: 0.85,
            completionPercentage: "78%",
            efficiencyDescription: "Operating efficiently across all buildings",
            efficiencyStatus: AdminPortfolioSummary.EfficiencyStatus(
                icon: "checkmark.circle.fill",
                color: .green,
                description: "Excellent performance"
            ),
            todaysPhotoCount: 89
        )
        
        let mockMetrics = [
            "1": CoreTypes.BuildingMetrics(
                buildingId: "1",
                completionRate: 0.85,
                overdueTasks: 1,
                totalTasks: 10,
                activeWorkers: 2,
                overallScore: 0.85,
                pendingTasks: 2,
                urgentTasksCount: 1,
                criticalIssues: 0
            ),
            "2": CoreTypes.BuildingMetrics(
                buildingId: "2", 
                completionRate: 0.72,
                overdueTasks: 3,
                totalTasks: 15,
                activeWorkers: 1,
                overallScore: 0.72,
                pendingTasks: 4,
                urgentTasksCount: 3,
                criticalIssues: 1
            )
        ]
        
        AdminHeroMetricsCard(
            portfolioSummary: mockSummary,
            buildingMetrics: mockMetrics,
            onDrillDown: {}
        )
        .frame(height: 200)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif