import SwiftUI

struct ClientProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = NewAuthManager.shared
    @ObservedObject var viewModel: ClientDashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    clientProfileHeader
                    portfolioBuildingsSection
                    clientStatisticsSection
                    clientSettingsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground.ignoresSafeArea())
            .navigationTitle("Client Profile")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { HapticManager.impact(.medium); dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.subheadline.weight(.semibold))
                            Text("Back").font(.subheadline)
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { HapticManager.impact(.light); dismiss() }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.maximumFractionDigits = 1
        if value >= 1_000_000 { return (f.string(from: NSNumber(value: value/1_000_000)) ?? "$0") + "M" }
        if value >= 1_000 { return (f.string(from: NSNumber(value: value/1_000)) ?? "$0") + "K" }
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
    private func getCompletedTasksCount() -> Int { viewModel.clientTasks.filter { $0.isCompleted }.count }
    private func getBudgetColor() -> Color { viewModel.monthlyMetrics.budgetUtilization > 1.0 ? CyntientOpsDesign.DashboardColors.critical : (viewModel.monthlyMetrics.budgetUtilization > 0.8 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success) }
    private func getClientInitials() -> String { viewModel.clientInitials }
    
    private var clientProfileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(colors: [CyntientOpsDesign.DashboardColors.clientPrimary, CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 100, height: 100)
                Text(getClientInitials()).font(.system(size: 36, weight: .bold)).foregroundColor(.white)
            }
            VStack(spacing: 8) {
                Text(viewModel.clientDisplayName).font(.title2).fontWeight(.bold).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Text(viewModel.clientOrgName).font(.subheadline).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .padding(16)
        .cyntientOpsDarkCardBackground()
    }
    
    private var portfolioBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portfolio Properties").font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
                Text("\(viewModel.clientBuildings.count)").font(.subheadline).fontWeight(.semibold).foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
            ForEach(viewModel.clientBuildings.prefix(8), id: \.id) { b in
                HStack {
                    Image(systemName: "building.2").foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                    Text(b.name).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    Spacer()
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .cyntientOpsDarkCardBackground()
    }
    
    private var clientStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics").font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            HStack(spacing: 12) {
                ClientProfileStatCard(title: "Portfolio Value", value: "$\(formatCurrency(viewModel.portfolioMarketValue > 0 ? viewModel.portfolioMarketValue : viewModel.portfolioAssessedValue))", color: CyntientOpsDesign.DashboardColors.success)
                ClientProfileStatCard(title: "Completed Tasks", value: "\(getCompletedTasksCount())", color: CyntientOpsDesign.DashboardColors.clientPrimary)
                ClientProfileStatCard(title: "Budget Utilization", value: "\(Int(viewModel.monthlyMetrics.budgetUtilization * 100))%", color: getBudgetColor())
            }
        }
        .padding(16)
        .cyntientOpsDarkCardBackground()
    }
    
    private var clientSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings").font(.headline).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            ClientProfileInfoRow(icon: "envelope.fill", label: "Email", value: viewModel.clientEmail ?? "unknown")
            ClientProfileInfoRow(icon: "person.crop.circle", label: "Name", value: viewModel.clientDisplayName)
            Divider().background(CyntientOpsDesign.DashboardColors.borderSubtle)
            ClientSettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage your alerts and preferences")
            ClientSettingsRow(icon: "lock.fill", title: "Security", subtitle: "Password and 2FA settings")
            ClientSettingsRow(icon: "questionmark.circle.fill", title: "Support", subtitle: "Help and contact information")
            Divider().background(CyntientOpsDesign.DashboardColors.borderSubtle).padding(.vertical, 8)
            Button(action: { Task { await authManager.logout(); dismiss() } }) { ClientSettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "Log out of your account") }.buttonStyle(.plain)
        }
        .padding(16)
        .cyntientOpsDarkCardBackground()
    }
}

struct ClientProfileInfoRow: View { let icon: String; let label: String; let value: String
    var body: some View { HStack { Image(systemName: icon).font(.subheadline).foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary).frame(width: 20); Text(label).font(.subheadline).foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText); Spacer(); Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText) } }
}

struct ClientProfileStatCard: View { let title: String; let value: String; let color: Color
    var body: some View { VStack(spacing: 8) { Text(value).font(.title).fontWeight(.bold).foregroundColor(color); Text(title).font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))) }
}

struct ClientSettingsRow: View { let icon: String; let title: String; let subtitle: String
    var body: some View { HStack(spacing: 12) { Image(systemName: icon).font(.subheadline).foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary).frame(width: 20); VStack(alignment: .leading, spacing: 2) { Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(CyntientOpsDesign.DashboardColors.primaryText); Text(subtitle).font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText) }; Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText) }.padding(.vertical, 4) }
}
