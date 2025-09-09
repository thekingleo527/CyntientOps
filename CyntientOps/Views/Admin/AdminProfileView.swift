//
//  AdminProfileView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Admin profile with logout functionality
//  ✅ REAL DATA: From AdminDashboardViewModel
//

import SwiftUI

public struct AdminProfileView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("preferredLanguage") private var preferredLanguage: String = "en"
    @Environment(\.dismiss) private var dismiss
    
    @State private var showLogoutConfirmation = false
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Admin Profile Header
                adminProfileHeader
                
                // Admin Stats Section
                adminStatsSection
                
                // Account Settings Section
                accountSettingsSection
                
                // System Information
                systemInfoSection

                // Language Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Text("Language")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    Picker("Language", selection: $preferredLanguage) {
                        Text("English").tag("en")
                        Text("Español").tag("es")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preferredLanguage) { _, new in
                        languageManager.setLanguage(code: new)
                    }
                }
                .padding()
                .cyntientOpsDarkCardBackground()
                
                // Logout Section
                logoutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
        }
        .alert("Confirm Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to log out of the admin dashboard?")
        }
        .task {
            // Ensure tiles hydrate with fresh values when profile opens
            await viewModel.refreshDashboardData()
        }
    }
    
    // MARK: - Profile Components
    
    private var adminProfileHeader: some View {
        VStack(spacing: 16) {
            // Admin Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CyntientOpsDesign.DashboardColors.adminAccent, CyntientOpsDesign.DashboardColors.adminAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text("SM")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
        VStack(spacing: 4) {
            Text("Shawn Magloire")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

            Text("CyntientOps Administrator")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)

            // Admin Status Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.success)
                    .frame(width: 8, height: 8)

                Text("Administrator Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
            .cornerRadius(8)

            // Contact details
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    Text(NewAuthManager.shared.currentUser?.email ?? "shawn@fme-llc.com")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    Text("917-731-1764")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
            }
        }
    }
    }
    
    private var adminStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio Oversight")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminProfileStatCard(
                    title: "Buildings Managed",
                    value: viewModel.buildingCount.formatted(),
                    icon: "building.2.fill",
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                
                AdminProfileStatCard(
                    title: "Active Workers",
                    value: viewModel.workersActive.formatted(),
                    icon: "person.2.fill",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminProfileStatCard(
                    title: "Compliance Score",
                    value: viewModel.compliancePercentText,
                    icon: "checkmark.shield.fill",
                    color: getComplianceColor()
                )
                
                AdminProfileStatCard(
                    title: "Today's Progress",
                    value: viewModel.completionPercentText,
                    icon: "chart.line.uptrend.xyaxis",
                    color: getProgressColor()
                )
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
    
    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                AdminSettingRow(
                    icon: "person.crop.circle",
                    title: "Profile Information",
                    subtitle: "Manage admin account details",
                    action: { /* Profile settings */ }
                )
                
                AdminSettingRow(
                    icon: "shield.lefthalf.filled",
                    title: "Security Settings",
                    subtitle: "Password and access controls",
                    action: { /* Security settings */ }
                )
                
                AdminSettingRow(
                    icon: "bell.badge",
                    title: "Notification Preferences",
                    subtitle: "Alert and notification settings",
                    action: { /* Notification settings */ }
                )
                
                AdminSettingRow(
                    icon: "gear",
                    title: "System Configuration",
                    subtitle: "Advanced admin settings",
                    action: { /* System settings */ }
                )
                
                AdminSettingRow(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Broadcast Message",
                    subtitle: "Send update to all dashboards",
                    action: { /* Broadcast tool */ }
                )
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

            VStack(spacing: 8) {
                AdminInfoRow(label: "App Version", value: "CyntientOps v6.0")
                AdminInfoRow(label: "Database Status", value: viewModel.isSynced ? "Connected" : "Offline")
                AdminInfoRow(label: "Last Sync", value: viewModel.lastSyncAt.formatted(date: .abbreviated, time: .shortened))
                AdminInfoRow(label: "Admin Session", value: "Active since login")
                AdminInfoRow(label: "Admin Email", value: NewAuthManager.shared.currentUser?.email ?? "shawn@fme-llc.com")
                AdminInfoRow(label: "Admin Phone", value: "917-731-1764")
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
    
    private var logoutSection: some View {
        VStack(spacing: 16) {
            Button(action: { showLogoutConfirmation = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "power")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Logout Admin Session")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(CyntientOpsDesign.DashboardColors.critical)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Logging out will end your admin session and return you to the login screen.")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getComplianceColor() -> Color {
        if viewModel.complianceScore >= 0.9 {
            return CyntientOpsDesign.DashboardColors.success
        } else if viewModel.complianceScore >= 0.7 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private func getProgressColor() -> Color {
        if viewModel.completionToday >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if viewModel.completionToday >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private func performLogout() {
        Task {
            await authManager.logout()
            dismiss()
        }
    }
}

// MARK: - Supporting Profile Components

struct AdminProfileStatCard: View {
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
                .font(.title3)
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

struct AdminSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
        .padding(.vertical, 4)
    }
}
