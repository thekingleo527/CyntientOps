//
//  ProfileView.swift
//  CyntientOps v6.0
//
//  ✅ ALL COMPILATION ERRORS FIXED
//  ✅ No async operations in computed properties or view builders
//  ✅ Proper ViewBuilder usage
//  ✅ Cross-dashboard integration ready
//  ✅ FIXED: Proper error handling for logout
//  ✅ DARK ELEGANCE: Updated with new theme system
//

import SwiftUI
import Foundation

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
    
    @State private var showImagePicker = false
    @State private var showLogoutConfirmation = false
    @State private var profileImage: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Determine user's dashboard role for theming
    private var dashboardRole: DashboardRole {
        switch authManager.userRole {
        case .admin, .manager: return .admin
        case .client: return .client
        case .worker, .none: return .worker
        }
    }
    
    private var currentWorkerRole: String {
        contextEngine.workerContext?.profile.role.rawValue.capitalized ?? "Worker"
    }
    
    private var currentWorkerEmail: String? {
        contextEngine.workerContext?.profile.email
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CyntientOpsDesign.Spacing.lg) {
                    // Profile header
                    profileHeader
                    
                    // Worker information
                    workerInfoSection
                    
                    // Statistics section
                    statisticsSection
                    
                    // Settings section
                    settingsSection
                    
                    // Actions section
                    actionsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, CyntientOpsDesign.Spacing.md)
                .padding(.top, CyntientOpsDesign.Spacing.md)
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticManager.impact(.medium)
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundColor(dashboardRole.primaryColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.impact(.light)
                        dismiss()
                    }
                    .foregroundColor(dashboardRole.primaryColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showImagePicker) {
            CyntientOpsImagePicker(
                image: $profileImage,
                sourceType: .photoLibrary
            )
        }
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.md) {
            // Profile image
            Button(action: {
                HapticManager.impact(.light)
                showImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: dashboardRole.heroGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    // Edit overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(dashboardRole.primaryColor)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                                .offset(x: -8, y: -8)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Worker name and role
            VStack(spacing: CyntientOpsDesign.Spacing.xs) {
                Text(authManager.currentWorkerName)
                    .francoTypography(CyntientOpsDesign.Typography.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(currentWorkerRole)
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(dashboardRole.primaryColor)
                
                if let email = currentWorkerEmail {
                    Text(email)
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
        }
    }
    
    // MARK: - Worker Information
    
    private var workerInfoSection: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.md) {
            Text("Worker Information")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                ProfileInfoRow(
                    icon: "person.badge.key.fill",
                    label: "Worker ID",
                    value: authManager.workerId ?? "Unknown",
                    role: dashboardRole
                )
                
                ProfileInfoRow(
                    icon: "building.2.fill",
                    label: "Assigned Buildings",
                    value: "\(contextEngine.workerContext?.assignedBuildings.count ?? 0)",
                    role: dashboardRole
                )
                
                ProfileInfoRow(
                    icon: "clock.fill",
                    label: "Employment Status",
                    value: "Active",
                    role: dashboardRole
                )
                
                ProfileInfoRow(
                    icon: "calendar.badge.clock",
                    label: "Member Since",
                    value: "March 2024",
                    role: dashboardRole
                )
            }
        }
        .francoCardPadding()
        .cyntientOpsDarkCardBackground()
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.md) {
            Text("Performance Stats")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                HStack(spacing: CyntientOpsDesign.Spacing.md) {
                    ProfileStatCard(
                        title: "Tasks Today",
                        value: "\(contextEngine.taskContext.todaysTasks.count)",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                    
                    ProfileStatCard(
                        title: "Completed",
                        value: "\(getCompletedTasksCount())",
                        color: CyntientOpsDesign.DashboardColors.success
                    )
                }
                
                HStack(spacing: CyntientOpsDesign.Spacing.md) {
                    ProfileStatCard(
                        title: "Pending",
                        value: "\(getPendingTasksCount())",
                        color: CyntientOpsDesign.DashboardColors.warning
                    )
                    
                    ProfileStatCard(
                        title: "Urgent",
                        value: "\(getUrgentTasksCount())",
                        color: CyntientOpsDesign.DashboardColors.critical
                    )
                }
            }
        }
        .francoCardPadding()
        .cyntientOpsDarkCardBackground()
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.md) {
            Text("Settings")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Push notifications and alerts",
                    hasChevron: true,
                    role: dashboardRole
                ) {
                    // Handle notifications settings
                }
                
                Divider()
                    .background(CyntientOpsDesign.DashboardColors.borderSubtle)
                    .padding(.vertical, CyntientOpsDesign.Spacing.sm)
                
                SettingsRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: "Always enabled for better visibility",
                    hasChevron: false,
                    role: dashboardRole
                ) {
                    // Dark mode is always on
                }
                
                Divider()
                    .background(CyntientOpsDesign.DashboardColors.borderSubtle)
                    .padding(.vertical, CyntientOpsDesign.Spacing.sm)
                
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "FAQs and contact information",
                    hasChevron: true,
                    role: dashboardRole
                ) {
                    // Handle help & support
                }
            }
        }
        .francoCardPadding()
        .cyntientOpsDarkCardBackground()
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.sm) {
            Button {
                HapticManager.impact(.medium)
                Task {
                    await refreshContextData()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                    Text("Refresh Data")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(dashboardRole.primaryColor)
                .francoCornerRadius(CyntientOpsDesign.CornerRadius.md)
            }
            
            Button {
                HapticManager.impact(.medium)
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                        .fill(CyntientOpsDesign.DashboardColors.critical.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                                .stroke(CyntientOpsDesign.DashboardColors.critical.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLogout() {
        HapticManager.impact(.heavy)
        Task {
            await authManager.logout()
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func refreshContextData() async {
        guard let workerId = authManager.workerId else { return }
        do {
            try await contextEngine.loadContext(for: workerId)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func getPendingTasksCount() -> Int {
        contextEngine.taskContext.todaysTasks.filter { task in
            !task.isCompleted
        }.count
    }
    
    private func getCompletedTasksCount() -> Int {
        contextEngine.taskContext.todaysTasks.filter { task in
            task.isCompleted
        }.count
    }
    
    private func getUrgentTasksCount() -> Int {
        contextEngine.taskContext.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            let urgencyValue = urgency.rawValue.lowercased()
            return urgencyValue == "high" || urgencyValue == "critical" || urgencyValue == "urgent"
        }.count
    }
}

// MARK: - Supporting Components

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let role: DashboardRole
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(role.primaryColor)
                .frame(width: 20)
            
            Text(label)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.sm) {
            Text(value)
                .francoTypography(CyntientOpsDesign.Typography.title)
                .foregroundColor(color)
            
            Text(title)
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CyntientOpsDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let hasChevron: Bool
    let role: DashboardRole
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: CyntientOpsDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(role.primaryColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs / 2) {
                    Text(title)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(subtitle)
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                
                Spacer()
                
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            .padding(.vertical, CyntientOpsDesign.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview Provider

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(NewAuthManager.shared)
            .preferredColorScheme(.dark)
    }
}
