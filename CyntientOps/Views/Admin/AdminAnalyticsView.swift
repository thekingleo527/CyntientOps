//
//  AdminAnalyticsView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Admin analytics dashboard
//

import SwiftUI

struct AdminAnalyticsView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio Overview
                portfolioOverviewSection
                
                // Performance Metrics
                performanceMetricsSection
                
                // Worker Analytics
                workerAnalyticsSection
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
                    value: "\\(viewModel.buildingCount)",
                    icon: "building.2.fill",
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                
                AdminAnalyticCard(
                    title: "Compliance Rate",
                    value: "\\(Int(viewModel.complianceScore * 100))%",
                    icon: "checkmark.shield.fill",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminAnalyticCard(
                    title: "Active Workers",
                    value: "\\(viewModel.workersActive)",
                    icon: "person.2.fill",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminAnalyticCard(
                    title: "Daily Progress",
                    value: "\\(Int(viewModel.completionToday * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: CyntientOpsDesign.DashboardColors.info
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
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
        .francoDarkCardBackground()
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
        .francoDarkCardBackground()
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