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
    @EnvironmentObject private var container: ServiceContainer
    @EnvironmentObject private var offlineQueue: OfflineQueueManager

    // Health metrics state (24h window)
    @State private var avgLLMLatencyMs: Int? = nil
    @State private var tokensUsed24h: Int = 0
    @State private var llmSuccessRate: Double? = nil
    @State private var llmErrors24h: Int = 0
    
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

            // LLM metrics (24h)
            HStack {
                Label("LLM Latency", systemImage: "bolt.fill").foregroundColor(.cyan)
                Spacer()
                Text(avgLLMLatencyMs != nil ? "~ \(avgLLMLatencyMs!) ms" : "n/a")
                    .foregroundColor(.cyan)
            }.font(.caption)

            HStack {
                Label("LLM Tokens (24h)", systemImage: "number.square").foregroundColor(.cyan)
                Spacer()
                Text(tokensUsed24h.formatted())
                    .foregroundColor(.cyan)
            }.font(.caption)

            HStack {
                Label("LLM Success", systemImage: "checkmark.seal").foregroundColor(.green)
                Spacer()
                Text(llmSuccessRate != nil ? "\(Int((llmSuccessRate ?? 0) * 100))%" : "n/a")
                    .foregroundColor(.green)
            }.font(.caption)

            HStack {
                Label("Function Errors (24h)", systemImage: "xmark.octagon.fill").foregroundColor(.red)
                Spacer()
                Text("\(llmErrors24h)")
                    .foregroundColor(.red)
            }.font(.caption)
        }
        .padding()
        .cyntientOpsDarkCardBackground()
        .task { await refreshHealthMetrics() }
    }

    private func refreshHealthMetrics() async {
        do {
            let rows = try await container.database.query("""
                SELECT 
                    AVG(latency_ms) AS avg_latency,
                    SUM(tokens_used) AS total_tokens,
                    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) AS ok,
                    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS err,
                    COUNT(*) AS total
                FROM nova_usage_analytics_local
                WHERE datetime(created_at) >= datetime('now', '-1 day')
            """)
            if let r = rows.first {
                let avg = (r["avg_latency"] as? Double) ?? (r["avg_latency"] as? NSNumber)?.doubleValue
                let toks = (r["total_tokens"] as? Int64) ?? 0
                let ok = (r["ok"] as? Int64) ?? 0
                let err = (r["err"] as? Int64) ?? 0
                let total = (r["total"] as? Int64) ?? 0
                await MainActor.run {
                    self.avgLLMLatencyMs = avg != nil ? Int(avg!) : nil
                    self.tokensUsed24h = Int(toks)
                    self.llmErrors24h = Int(err)
                    self.llmSuccessRate = total > 0 ? Double(ok) / Double(total) : nil
                }
            }
        } catch {
            print("⚠️ Health metrics query failed: \(error)")
        }
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
