//
//  ContentView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Now delegates ViewModel creation to role-specific container views.
//  ✅ CLEAN: Only handles top-level routing based on user role.
//  ✅ ROBUST: Aligned with a consistent ViewModel injection pattern.
//  ✅ DARK ELEGANCE: Updated with new theme colors and transitions
//  ✅ FIXED: Resolved userId and userRole property issues
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var previousRole: CoreTypes.UserRole?
    
    var body: some View {
        ZStack {
            // Dark Elegance Background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            // Main content with role-based routing
            Group {
                switch authManager.userRole {
                case .admin, .manager:
                    // Admin and Manager share the same dashboard experience
                    AdminDashboardContainerView()
                        .transition(roleTransition)
                        .id("admin-\(authManager.workerId ?? "")")
                    
                case .client:
                    ClientDashboardContainerView()
                        .transition(roleTransition)
                        .id("client-\(authManager.workerId ?? "")")
                    
                case .worker:
                    WorkerDashboardContainerView()
                        .transition(roleTransition)
                        .id("worker-\(authManager.workerId ?? "")")
                    
                case nil:
                    // Fallback with loading state for undefined role
                    UndefinedRoleView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(CyntientOpsDesign.Animations.dashboardTransition, value: authManager.userRole)
            
            // PRODUCTION: Debug role indicator removed
        }
        // Pass the authManager down so the container views can use it
        .environmentObject(authManager)
        .preferredColorScheme(.dark)
        .onChange(of: authManager.userRole) { _, newRole in
            handleRoleChange(from: previousRole, to: newRole)
            previousRole = newRole
        }
        .onAppear {
            previousRole = authManager.userRole
        }
    }
    
    // MARK: - Computed Properties
    
    private var roleTransition: AnyTransition {
        // Custom transition based on role hierarchy
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: - Helper Methods
    
    private func handleRoleChange(from oldRole: CoreTypes.UserRole?, to newRole: CoreTypes.UserRole?) {
        // Log role changes for analytics
        #if DEBUG
        logInfo("🔄 Role transition: \(oldRole?.rawValue ?? "none") → \(newRole?.rawValue ?? "none")")
        #endif
        
        // Clear any role-specific caches if needed
        if oldRole != newRole {
            // Trigger any necessary cleanup or preparation
            NotificationCenter.default.post(
                name: Notification.Name("UserRoleChanged"),
                object: nil,
                userInfo: ["oldRole": oldRole as Any, "newRole": newRole as Any]
            )
        }
    }
}

// MARK: - Undefined Role View

struct UndefinedRoleView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var isRetrying = false
    
    var body: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.xl) {
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: CyntientOpsDesign.DashboardColors.primaryText))
                .scaleEffect(1.5)
            
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                Text("Setting up your dashboard...")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("We're preparing your personalized experience")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Retry button after delay
            if !isRetrying {
                Button(action: retryRoleAssignment) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(CyntientOpsDesign.DashboardColors.primaryAction)
                    .cornerRadius(8)
                }
                .opacity(0)
                .animation(.easeIn(duration: 0.3).delay(3), value: isRetrying)
                .task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation {
                        isRetrying = false
                    }
                }
            }
        }
        .francoCardPadding()
        .frame(maxWidth: 400)
    }
    
    private func retryRoleAssignment() {
        isRetrying = true
        
        Task {
            // Attempt to refresh the user's role
            if authManager.workerId != nil {
                // Try to re-authenticate or refresh session
                do {
                    try await authManager.refreshSession()
                } catch {
                    logInfo("Failed to refresh session: \(error)")
                }
            }
            
            await MainActor.run {
                isRetrying = false
            }
        }
    }
}

// MARK: - Production Container Views

struct AdminDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var serviceContainer: ServiceContainer
    
    var body: some View {
        AdminDashboardView(container: serviceContainer)
            .environmentObject(serviceContainer)
            .environmentObject(authManager)
    }
}

struct ClientDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var serviceContainer: ServiceContainer
    
    var body: some View {
        ClientDashboardView(container: serviceContainer)
            .environmentObject(authManager)
    }
}

struct WorkerDashboardContainerView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var serviceContainer: ServiceContainer
    
    var body: some View {
        WorkerDashboardView(container: serviceContainer)
            .environmentObject(authManager)
    }
}
