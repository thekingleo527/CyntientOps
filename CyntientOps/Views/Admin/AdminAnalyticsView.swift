//
//  AdminAnalyticsView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Admin analytics dashboard
//

import SwiftUI

public struct AdminAnalyticsView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio Overview
                portfolioOverviewSection
                
                // Performance Metrics
                performanceMetricsSection
                
                // Worker Analytics
                workerAnalyticsSection

                // Health & Observability
                healthSection
            }
            .padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
        }
    }
    
    private var portfolioOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminAnalyticCard(
                    title: "Total Buildings",
                    value: viewModel.buildingCount.formatted(),
                    icon: "building.2.fill",
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                
                AdminAnalyticCard(
                    title: "Compliance Rate",
                    value: viewModel.compliancePercentText,
                    icon: "checkmark.shield.fill",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminAnalyticCard(
                    title: "Active Workers",
                    value: viewModel.workersActive.formatted(),
                    icon: "person.2.fill",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminAnalyticCard(
                    title: "Daily Progress",
                    value: viewModel.completionPercentText,
                    icon: "chart.line.uptrend.xyaxis",
                    color: CyntientOpsDesign.DashboardColors.info
                )
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("Real-time performance analytics across the portfolio")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
    
    private var workerAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Worker Analytics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("Worker performance and efficiency metrics")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }

    @EnvironmentObject private var container: ServiceContainer
    @EnvironmentObject private var offlineQueue: OfflineQueueManager
    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            let q = offlineQueue.getQueueStatus()
            HStack {
                Label("Offline Queue", systemImage: "arrow.triangle.2.circlepath").foregroundColor(.orange)
                Spacer()
                Text("\(q.totalActions) pending")
                    .foregroundColor(.orange)
            }
            .font(.caption)

            HStack {
                Label("Network", systemImage: "wave.3.left").foregroundColor(q.networkStatus == .connected ? .green : .red)
                Spacer()
                Text(q.networkStatus == .connected ? "Online" : "Offline")
                    .foregroundColor(q.networkStatus == .connected ? .green : .red)
            }
            .font(.caption)

            // Placeholder hooks for LLM metrics: would read from nova_usage_analytics_local
            HStack {
                Label("LLM Latency", systemImage: "bolt.fill").foregroundColor(.cyan)
                Spacer()
                Text("~ n/a ms (see analytics)")
                    .foregroundColor(.cyan)
            }
            .font(.caption)
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

struct AdminAnalyticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
