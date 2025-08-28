//
//  WorkerIntelligencePanel.swift
//  CyntientOps
//
//  Worker-focused intelligence panel with tabs:
//  - Operations: day/week/month routines and upcoming sequences
//  - Compliance: sanitation/compliance summary (worker-centric)
//  - Performance: aggregates (reuses PerformanceMetricsView)
//  - Portfolio: opens full-screen map of portfolio buildings
//

import SwiftUI
import MapKit

enum WorkerIntelTab: String, CaseIterable {
    case operations = "Operations"
    case compliance = "Compliance"
    case performance = "Performance"
    case portfolio = "Portfolio"
}

struct WorkerIntelligencePanel: View {
    let container: ServiceContainer
    @ObservedObject var dashboardVM: WorkerDashboardViewModel
    @ObservedObject var profileVM: WorkerProfileViewModel
    @EnvironmentObject private var auth: NewAuthManager

    @State private var selectedTab: WorkerIntelTab = .operations
    @State private var showingPortfolioMap = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tabs
            HStack(spacing: 8) {
                ForEach(WorkerIntelTab.allCases, id: \.self) { tab in
                    Button(action: { withAnimation { selectedTab = tab } }) {
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }

            // Content
            Group {
                switch selectedTab {
                case .operations:
                    OperationsPanel(container: container, dashboardVM: dashboardVM)
                case .compliance:
                    CompliancePanel(container: container, dashboardVM: dashboardVM)
                case .performance:
                    PerformanceMetricsView(viewModel: profileVM)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                case .portfolio:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Map")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("View all buildings and navigate quickly to details.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: { showingPortfolioMap = true }) {
                            Label("Open Portfolio Map", systemImage: "map")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingPortfolioMap) {
            PortfolioMapSheet(container: container)
        }
    }
}

private struct OperationsPanel: View {
    let container: ServiceContainer
    @ObservedObject var dashboardVM: WorkerDashboardViewModel
    @EnvironmentObject private var auth: NewAuthManager

    @State private var activeSequences: [RouteSequence] = []
    @State private var upcomingSequences: [RouteSequence] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Routines").font(.headline).foregroundColor(.white)
            if activeSequences.isEmpty && upcomingSequences.isEmpty {
                Text("No active routines right now.").font(.caption).foregroundColor(.gray)
            } else {
                if !activeSequences.isEmpty {
                    Text("Active").font(.subheadline).foregroundColor(.white)
                    ForEach(activeSequences, id: \.id) { seq in
                        HStack {
                            Text(seq.buildingName).foregroundColor(.white)
                            Spacer()
                            Text(seq.arrivalTime, style: .time).foregroundColor(.gray).font(.caption)
                        }
                        .font(.caption)
                    }
                }
                if !upcomingSequences.isEmpty {
                    Text("Upcoming").font(.subheadline).foregroundColor(.white)
                    ForEach(upcomingSequences, id: \.id) { seq in
                        HStack {
                            Text(seq.buildingName).foregroundColor(.white)
                            Spacer()
                            Text(seq.arrivalTime, style: .time).foregroundColor(.gray).font(.caption)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .task { await loadSequences() }
    }

    private func loadSequences() async {
        guard let wid = auth.workerId else { return }
        activeSequences = container.routes.getActiveSequences(for: wid)
        upcomingSequences = container.routes.getUpcomingSequences(for: wid, limit: 5)
    }
}

private struct CompliancePanel: View {
    let container: ServiceContainer
    @ObservedObject var dashboardVM: WorkerDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compliance Summary").font(.headline).foregroundColor(.white)
            // Worker-centric compliance snapshot; sanitation focus
            Text("Sanitation Tasks Today: \(dashboardVM.todaysTasks.filter { $0.category.lowercased().contains("sanitation") }.count)")
                .font(.caption).foregroundColor(.gray)
            Text("DSNY Bin Tasks: \(container.dsnyTaskManager.getBinTasks(for: dashboardVM.worker?.workerId ?? "").count)")
                .font(.caption).foregroundColor(.gray)
            Divider().background(Color.white.opacity(0.1))
            Text("Documentation").font(.subheadline).foregroundColor(.white)
            VStack(alignment: .leading, spacing: 6) {
                Label("Sanitation (DSNY) Guidance", systemImage: "doc.text")
                Label("Safety Procedures", systemImage: "shield")
                Label("Compliance Checklists", systemImage: "checkmark.seal")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
    }
}

