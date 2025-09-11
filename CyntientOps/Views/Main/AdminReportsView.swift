//
//  AdminReportsView.swift (Production Only)
//  CyntientOps
//
//  Production reports screen using real data from the ServiceContainer
//  and ReportService. No mocks, no debug-only UI.
//

import SwiftUI
import UIKit

public struct AdminReportsView: View {
    private let container: ServiceContainer
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var reports: [AdminGeneratedReport] = []
    @State private var taxBills: [(buildingName: String, bill: DOFTaxBill)] = []
    @State private var taxLiens: [(buildingName: String, lien: DOFTaxLien)] = []
    @State private var showShareSheet: Bool = false
    @State private var shareURL: URL?

    @StateObject private var reportService = ReportService.shared

    public init(container: ServiceContainer) {
        self.container = container
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerBar

                        if isLoading {
                            ProgressView()
                                .tint(CyntientOpsDesign.DashboardColors.primaryAction)
                        } else if let errorMessage = errorMessage {
                            glassMessage(icon: "exclamationmark.triangle",
                                         color: CyntientOpsDesign.DashboardColors.warning,
                                         title: errorMessage,
                                         actionTitle: "Retry",
                                         action: loadReports)
                        } else if reports.isEmpty {
                            glassMessage(icon: "doc.text.magnifyingglass",
                                         color: CyntientOpsDesign.DashboardColors.tertiaryText,
                                         title: "No reports found",
                                         actionTitle: "Refresh",
                                         action: loadReports)
                        } else {
                            if !taxBills.isEmpty || !taxLiens.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Portfolio Tax History")
                                        .opsTypography(CyntientOpsDesign.Typography.headline)
                                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                    if !taxBills.isEmpty {
                                        ForEach(taxBills.prefix(5), id: \.bill.id) { item in
                                            taxBillRow(item.buildingName, item.bill)
                                        }
                                    }
                                    if !taxLiens.isEmpty {
                                        ForEach(taxLiens.prefix(3), id: \.lien.id) { item in
                                            taxLienRow(item.buildingName, item.lien)
                                        }
                                    }
                                }
                                .opsCardPadding()
                                .cyntientOpsDarkCardBackground()
                            }
                            VStack(spacing: 12) {
                                ForEach(reports) { report in
                                    reportCard(report)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("System Reports")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isGenerating {
                        ProgressView()
                            .tint(CyntientOpsDesign.DashboardColors.primaryAction)
                    } else {
                        Button(action: generatePortfolioReport) {
                            Image(systemName: "doc.badge.plus")
                        }
                    }
                    Button(action: loadReports) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task { loadReports() }
            .task { await loadTaxHistory() }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ActivityView(activityItems: [url])
                }
            }
        }
    }

    // MARK: - UI Components

    private var headerBar: some View {
        HStack {
            Text("Reports & Analytics")
                .opsTypography(CyntientOpsDesign.Typography.dashboardTitle)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

            Spacer()

            Button(action: generatePortfolioReport) {
                Label("Generate", systemImage: "doc.badge.plus")
                    .opsTypography(CyntientOpsDesign.Typography.caption)
            }
            .buttonStyle(ReportActionButtonStyle(color: CyntientOpsDesign.DashboardColors.primaryAction))

            Button(action: loadReports) {
                Image(systemName: "arrow.clockwise")
            }
            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
        }
    }

    private func glassMessage(icon: String, color: Color, title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color)
            Text(title)
                .opsTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .opsTypography(CyntientOpsDesign.Typography.caption)
        }
        .opsCardPadding()
        .cyntientOpsDarkCardBackground()
    }

    private func reportCard(_ report: AdminGeneratedReport) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: report.type))
                .foregroundColor(color(for: report.type))
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .opsTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                Text(report.generatedDate.formatted(date: .abbreviated, time: .shortened))
                    .opsTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            Spacer()
            Button {
                if let url = URL(string: report.filePath) {
                    shareURL = url
                    showShareSheet = true
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
            }
        }
        .opsCardPadding()
        .cyntientOpsDarkCardBackground()
    }

    private func loadReports() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let items = try await reportService.getAllReports()
                await MainActor.run {
                    self.reports = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load reports: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func loadTaxHistory() async {
        // Load recent DOF tax bills/liens for portfolio buildings
        do {
            // Fetch buildings
            let rows = try await container.database.query("SELECT id, name, bbl FROM buildings WHERE bbl IS NOT NULL")
            var bills: [(String, DOFTaxBill)] = []
            var liens: [(String, DOFTaxLien)] = []
            let api = NYCAPIService.shared
            for row in rows.prefix(8) {
                let bid = (row["id"] as? String) ?? ""
                let name = (row["name"] as? String) ?? bid
                let bbl = (row["bbl"] as? String) ?? ""
                guard !bbl.isEmpty else { continue }
                let tb = (try? await api.fetchDOFTaxBills(bbl: bbl)) ?? []
                let tl = (try? await api.fetchDOFTaxLiens(bbl: bbl)) ?? []
                bills.append(contentsOf: tb.sorted { ($0.paidDate ?? "") > ($1.paidDate ?? "") }.prefix(2).map { (name, $0) })
                liens.append(contentsOf: tl.prefix(1).map { (name, $0) })
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            await MainActor.run {
                self.taxBills = bills
                self.taxLiens = liens
            }
        } catch {
            // Non-fatal
        }
    }

    private func taxBillRow(_ building: String, _ bill: DOFTaxBill) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tax Bill • \(building)")
                    .opsTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Text("Year: \(bill.year)  Paid: $\(Int(bill.propertyTaxPaid ?? 0))  Outstanding: $\(Int(bill.outstandingAmount ?? 0))")
                    .opsTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            Spacer()
        }
    }

    private func taxLienRow(_ building: String, _ lien: DOFTaxLien) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tax Lien • \(building)")
                    .opsTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Text("Year: \(lien.year)  Amount: $\(Int(lien.lienAmount ?? 0))  Purchaser: \(lien.purchaser ?? "-")")
                    .opsTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            Spacer()
        }
    }

    private func generatePortfolioReport() {
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                let data = try await buildPortfolioReportData()
                let url = try await reportService.generateClientReport(data)
                await MainActor.run {
                    self.isGenerating = false
                    self.shareURL = url
                    self.showShareSheet = true
                }
                loadReports()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate report: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }

    private func buildPortfolioReportData() async throws -> ClientPortfolioReportData {
        // 1) Load buildings from real database
        let all = try await container.buildings.getAllBuildings()
        let buildings: [CoreTypes.NamedCoordinate] = all.map { b in
            CoreTypes.NamedCoordinate(
                id: b.id,
                name: b.name,
                address: b.address,
                latitude: b.latitude,
                longitude: b.longitude
            )
        }

        // 2) Calculate real metrics using BuildingMetricsService
        let buildingIds = buildings.map { $0.id }
        let metrics = try await container.metrics.calculateBatchMetrics(for: buildingIds)

        // 3) Get real compliance overview
        let complianceOverview = try await container.compliance.getComplianceOverview()

        // 4) Compute portfolio health from real metrics
        let completionAvg = metrics.isEmpty ? 0.0 : metrics.values.reduce(0.0) { $0 + $1.completionRate } / Double(metrics.count)
        let portfolioHealth = CoreTypes.PortfolioHealth(
            overallScore: completionAvg,
            totalBuildings: buildings.count,
            activeBuildings: buildings.count,
            criticalIssues: complianceOverview.criticalViolations,
            trend: .stable,
            lastUpdated: Date()
        )

        // 5) Map top intelligence insights (titles only) for the report
        let insightsRaw = container.intelligence.getInsights(for: .admin)
        let insights = insightsRaw.prefix(5).map { $0.title }

        return ClientPortfolioReportData(
            generatedAt: Date(),
            dateRange: .thisMonth,
            portfolioHealth: portfolioHealth,
            buildings: buildings,
            buildingMetrics: metrics,
            complianceOverview: complianceOverview,
            insights: insights
        )
    }

    private func icon(for type: String) -> String {
        switch type.lowercased() {
        case "compliance": return "checkmark.shield.fill"
        case "performance": return "chart.line.uptrend.xyaxis"
        case "financial": return "dollarsign.circle.fill"
        case "operations": return "gear"
        case "executive": return "briefcase.fill"
        default: return "doc.text.fill"
        }
    }

    private func color(for type: String) -> Color {
        switch type.lowercased() {
        case "compliance": return .orange
        case "performance": return .green
        case "financial": return .blue
        case "operations": return .purple
        case "executive": return .red
        default: return .accentColor
        }
    }
}

// Minimal UIActivityViewController wrapper for sharing
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// MARK: - Styling
private struct ReportActionButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 2)
    }
}
