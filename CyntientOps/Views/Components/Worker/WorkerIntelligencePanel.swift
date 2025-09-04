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
    case tasks = "Maintenance" // Renamed from "Tasks"
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
    @State private var portfolioBuildings: [NamedCoordinate] = []
    @State private var currentBuildingId: String? = nil

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
                case .tasks:
                    TasksHistoryPanel(container: container)
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
                        Button(action: { Task { await openPortfolio() } }) {
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
            WorkerPortfolioMapRevealSheet(
                container: container,
                buildings: portfolioBuildings,
                currentBuildingId: currentBuildingId
            ) { tapped in
                // Navigate to Building Detail
                // For now, dismiss and rely on parent navigation via dashboard VM
                showingPortfolioMap = false
            }
        }
    }

    private func openPortfolio() async {
        // Load all buildings; set current building if clocked in
        if let list = try? await container.buildings.getAllBuildings() {
            portfolioBuildings = list
        } else {
            portfolioBuildings = []
        }
        if let wid = auth.workerId, let status = container.clockIn.getClockInStatus(for: wid) {
            currentBuildingId = status.buildingId
        } else {
            currentBuildingId = nil
        }
        showingPortfolioMap = true
    }
}

private struct TasksHistoryPanel: View {
    let container: ServiceContainer
    @EnvironmentObject private var auth: NewAuthManager
    @State private var recentTasks: [CoreTypes.ContextualTask] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks & Maintenance History").font(.headline).foregroundColor(.white)
            if isLoading {
                ProgressView().tint(.white)
            } else if recentTasks.isEmpty {
                Text("No recent tasks").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(recentTasks, id: \.id) { task in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(color(for: task.urgency)).frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title).foregroundColor(.white).font(.subheadline)
                            if let when = task.dueDate { Text(when, style: .date).font(.caption2).foregroundColor(.gray) }
                            if let building = task.buildingName { Text(building).font(.caption2).foregroundColor(.gray) }
                        }
                        Spacer()
                        if task.isCompleted { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task { await loadTasks() }
    }

    private func loadTasks() async {
        guard let wid = auth.workerId else { isLoading = false; return }
        do {
            // Pull worker tasks; consider time filtering client-side for now
            let tasks = try await container.tasks.getTasksForWorker(wid)
            // Sort: most recent due/completed first
            let sorted = tasks.sorted { (a, b) in
                (a.dueDate ?? Date.distantPast) > (b.dueDate ?? Date.distantPast)
            }
            await MainActor.run {
                self.recentTasks = Array(sorted.prefix(20))
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }

    private func color(for urgency: CoreTypes.TaskUrgency?) -> Color {
        switch urgency ?? .normal {
        case .low: return .green
        case .medium, .normal: return .blue
        case .high: return .orange
        case .urgent, .critical, .emergency: return .red
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
