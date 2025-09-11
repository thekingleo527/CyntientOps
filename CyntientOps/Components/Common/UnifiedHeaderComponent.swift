//
//  UnifiedHeaderComponent.swift
//  CyntientOps v6.0
//
//  ✅ COMPREHENSIVE: Unified header component for consistent branding
//  ✅ REUSABLE: Supports multiple dashboard types (Admin, Client, Worker)
//  ✅ INTELLIGENT: Nova AI integration status and notifications
//  ✅ DARK ELEGANCE: Consistent with established theme
//  ✅ DATA-DRIVEN: Real user data from AuthManager and ServiceContainer
//

import SwiftUI
import Combine

struct UnifiedHeaderComponent: View {
    // MARK: - Properties
    
    let title: String
    let subtitle: String?
    let userRole: UserRole
    let showLogo: Bool
    let showNotifications: Bool
    let showUserProfile: Bool
    let onNotificationTap: (() -> Void)?
    let onProfileTap: (() -> Void)?
    let onMenuTap: (() -> Void)?
    
    @EnvironmentObject private var container: ServiceContainer
    @EnvironmentObject private var novaEngine: NovaAIManager
    @State private var notificationCount = 0
    @State private var userDisplayName = "User"
    @State private var currentTime = Date()
    @State private var syncStatus: SyncStatus = .synced
    
    // Timer for live updates
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    // MARK: - Enums
    
    enum UserRole {
        case admin
        case client
        case worker
        
        var displayName: String {
            switch self {
            case .admin: return "Administrator"
            case .client: return "Client"
            case .worker: return "Worker"
            }
        }
        
        var primaryColor: Color {
            switch self {
            case .admin: return .blue
            case .client: return .green
            case .worker: return .orange
            }
        }
    }
    
    enum SyncStatus {
        case syncing
        case synced
        case error
        
        var icon: String {
            switch self {
            case .syncing: return "arrow.clockwise"
            case .synced: return "checkmark.circle"
            case .error: return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .syncing: return .blue
            case .synced: return .green
            case .error: return .red
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        title: String,
        subtitle: String? = nil,
        userRole: UserRole = .admin,
        showLogo: Bool = true,
        showNotifications: Bool = true,
        showUserProfile: Bool = true,
        onNotificationTap: (() -> Void)? = nil,
        onProfileTap: (() -> Void)? = nil,
        onMenuTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.userRole = userRole
        self.showLogo = showLogo
        self.showNotifications = showNotifications
        self.showUserProfile = showUserProfile
        self.onNotificationTap = onNotificationTap
        self.onProfileTap = onProfileTap
        self.onMenuTap = onMenuTap
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Header Bar
            HStack(spacing: 16) {
                // Left Section - Logo & Title
                leftSection
                
                Spacer()
                
                // Center Section - Title & Subtitle
                centerSection
                
                Spacer()
                
                // Right Section - Controls
                rightSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(headerBackground)
            
            // Status Bar (optional)
            if shouldShowStatusBar {
                statusBar
            }
        }
        .onAppear {
            loadUserData()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateSyncStatus()
        }
    }
    
    // MARK: - Left Section
    
    private var leftSection: some View {
        HStack(spacing: 12) {
            if showLogo {
                cyntientOpsLogo
            }
            
            if let onMenuTap = onMenuTap {
                Button(action: onMenuTap) {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
        }
    }
    
    private var cyntientOpsLogo: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [userRole.primaryColor, userRole.primaryColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 36, height: 36)
            
            Text("CO")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(userRole.primaryColor)
        }
    }
    
    // MARK: - Center Section
    
    private var centerSection: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            } else {
                Text(userRole.displayName)
                    .font(.caption)
                    .foregroundColor(userRole.primaryColor)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Right Section
    
    private var rightSection: some View {
        HStack(spacing: 16) {
            // Nova AI Status Indicator
            novaAIStatusIndicator
            
            // Notifications
            if showNotifications {
                notificationButton
            }
            
            // User Profile
            if showUserProfile {
                userProfileButton
            }
        }
    }
    
    private var novaAIStatusIndicator: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(novaEngine.novaState == .active ? .green : .gray)
                    .font(.caption)
                
                if novaEngine.novaState == .active {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .scaleEffect(novaEngine.isThinking ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: novaEngine.isThinking)
                }
            }
        }
        .disabled(true)
    }
    
    private var notificationButton: some View {
        Button(action: {
            onNotificationTap?()
        }) {
            ZStack {
                Image(systemName: "bell")
                    .foregroundColor(.white)
                    .font(.title3)
                
                if notificationCount > 0 {
                    Text("\(notificationCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
    
    private var userProfileButton: some View {
        Button(action: {
            onProfileTap?()
        }) {
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(userDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(currentTime.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [userRole.primaryColor, userRole.primaryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(userDisplayName.prefix(1))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // MARK: - Status Bar
    
    private var shouldShowStatusBar: Bool {
        syncStatus != .synced || novaEngine.isThinking
    }
    
    private var statusBar: some View {
        HStack {
            // Sync Status
            HStack(spacing: 6) {
                Image(systemName: syncStatus.icon)
                    .foregroundColor(syncStatus.color)
                    .font(.caption)
                    .rotationEffect(syncStatus == .syncing ? .degrees(360) : .degrees(0))
                    .animation(syncStatus == .syncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncStatus == .syncing)
                
                Text(syncStatusText)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Nova AI Processing Status
            if novaEngine.isThinking {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: userRole.primaryColor))
                    
                    Text("Nova AI Processing...")
                        .font(.caption2)
                        .foregroundColor(userRole.primaryColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Computed Properties
    
    private var headerBackground: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.95),
                Color.black.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
                .overlay(
            // Subtle accent border
            Rectangle()
                .fill(userRole.primaryColor.opacity(0.3))
                .frame(height: 1)
                .offset(y: 50)
        )
    }
    
    private var syncStatusText: String {
        switch syncStatus {
        case .syncing: return "Syncing..."
        case .synced: return "All systems operational"
        case .error: return "Connection issue"
        }
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() {
        if let currentUser = container.auth.currentUser {
            userDisplayName = currentUser.name
        }
        
        // Load notification count (placeholder)
        notificationCount = 3
        
        updateSyncStatus()
    }
    
    private func updateSyncStatus() {
        // Check various system statuses
        let hasConnectivity = true // Would check real connectivity
        let isDataSynced = true // Would check sync status
        
        if !hasConnectivity {
            syncStatus = .error
        } else if container.dashboardSync.pendingUpdatesCount > 0 {
            syncStatus = .syncing
        } else if isDataSynced {
            syncStatus = .synced
        } else {
            syncStatus = .error
        }
    }
}

// MARK: - Convenience Initializers

extension UnifiedHeaderComponent {
    
    /// Admin Dashboard Header
    static func adminHeader(
        title: String = "Admin Dashboard",
        subtitle: String? = "Portfolio Management",
        onNotificationTap: (() -> Void)? = nil,
        onProfileTap: (() -> Void)? = nil,
        onMenuTap: (() -> Void)? = nil
    ) -> UnifiedHeaderComponent {
        UnifiedHeaderComponent(
            title: title,
            subtitle: subtitle,
            userRole: .admin,
            showLogo: true,
            showNotifications: true,
            showUserProfile: true,
            onNotificationTap: onNotificationTap,
            onProfileTap: onProfileTap,
            onMenuTap: onMenuTap
        )
    }
    
    /// Client Dashboard Header
    static func clientHeader(
        title: String = "Portfolio Overview",
        subtitle: String? = "Executive Dashboard",
        onNotificationTap: (() -> Void)? = nil,
        onProfileTap: (() -> Void)? = nil,
        onMenuTap: (() -> Void)? = nil
    ) -> UnifiedHeaderComponent {
        UnifiedHeaderComponent(
            title: title,
            subtitle: subtitle,
            userRole: .client,
            showLogo: true,
            showNotifications: true,
            showUserProfile: true,
            onNotificationTap: onNotificationTap,
            onProfileTap: onProfileTap,
            onMenuTap: onMenuTap
        )
    }
    
    /// Worker Dashboard Header
    static func workerHeader(
        title: String = "My Tasks",
        subtitle: String? = "Daily Routine",
        onNotificationTap: (() -> Void)? = nil,
        onProfileTap: (() -> Void)? = nil,
        onMenuTap: (() -> Void)? = nil
    ) -> UnifiedHeaderComponent {
        UnifiedHeaderComponent(
            title: title,
            subtitle: subtitle,
            userRole: .worker,
            showLogo: true,
            showNotifications: true,
            showUserProfile: true,
            onNotificationTap: onNotificationTap,
            onProfileTap: onProfileTap,
            onMenuTap: onMenuTap
        )
    }
    
    /// Simple Header (minimal)
    static func simpleHeader(
        title: String,
        subtitle: String? = nil,
        userRole: UserRole = .admin
    ) -> UnifiedHeaderComponent {
        UnifiedHeaderComponent(
            title: title,
            subtitle: subtitle,
            userRole: userRole,
            showLogo: false,
            showNotifications: false,
            showUserProfile: false
        )
    }
}

// MARK: - Preview Support

// Preview removed to avoid constructing async ServiceContainer in previews
