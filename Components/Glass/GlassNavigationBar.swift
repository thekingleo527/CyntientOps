//
//  GlassNavigationBar.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ FIXED: Removed invalid @Environment property wrapper
//  ✅ ENHANCED: Glass morphism with proper dark theme integration
//  ✅ ALIGNED: With CyntientOpsDesign color system
//

import SwiftUI

struct GlassNavigationBar<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let actions: () -> Content
    
    var showMapButton: Bool = false
    var onMapReveal: (() -> Void)? = nil
    var showBackButton: Bool = false
    var onBackTap: (() -> Void)? = nil
    
    // Access safe area insets through the environment
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var isPressed = false
    
    init(
        title: String,
        subtitle: String? = nil,
        showMapButton: Bool = false,
        onMapReveal: (() -> Void)? = nil,
        showBackButton: Bool = false,
        onBackTap: (() -> Void)? = nil,
        @ViewBuilder actions: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showMapButton = showMapButton
        self.onMapReveal = onMapReveal
        self.showBackButton = showBackButton
        self.onBackTap = onBackTap
        self.actions = actions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Spacer for the top safe area
            Color.clear
                .frame(height: safeAreaInsets.top)
            
            // The actual navigation bar content
            HStack(spacing: 16) {
                // Left button (Back or Map)
                if showBackButton {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                        onBackTap?()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false
                        }
                    }) {
                        navigationButton(icon: "chevron.left")
                    }
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                } else if showMapButton {
                    Button(action: {
                        onMapReveal?()
                    }) {
                        navigationButton(icon: "map.fill")
                    }
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .tracking(0.5)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Action buttons
                actions()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(glassBackground)
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Components
    
    private func navigationButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
    
    private var glassBackground: some View {
        ZStack {
            // Dark base with blur
            Rectangle()
                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.85))
                .background(.ultraThinMaterial.opacity(0.5))
            
            // Gradient overlay for depth
            LinearGradient(
                colors: [
                    CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.3),
                    CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Bottom border
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.5)
            }
        }
    }
}

// MARK: - Convenience Extensions

extension GlassNavigationBar where Content == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showMapButton: Bool = false,
        onMapReveal: (() -> Void)? = nil,
        showBackButton: Bool = false,
        onBackTap: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showMapButton: showMapButton,
            onMapReveal: onMapReveal,
            showBackButton: showBackButton,
            onBackTap: onBackTap,
            actions: { EmptyView() }
        )
    }
}

// MARK: - Glass Navigation Action Button

struct GlassNavigationAction: View {
    let icon: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(
                    isDestructive ?
                    CyntientOpsDesign.DashboardColors.critical :
                    CyntientOpsDesign.DashboardColors.primaryText
                )
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                        .overlay(
                            Circle()
                                .stroke(
                                    isDestructive ?
                                    CyntientOpsDesign.DashboardColors.critical.opacity(0.3) :
                                    Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Safe Area Environment Key

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return window.safeAreaInsets.insets
        }
        return EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

private extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

// MARK: - Preview

struct GlassNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Dark Elegance background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack {
                // Example 1: With map button and actions
                GlassNavigationBar(
                    title: "Dashboard",
                    subtitle: "Good morning, Shawn",
                    showMapButton: true,
                    onMapReveal: { print("Map revealed") }
                ) {
                    HStack(spacing: 12) {
                        GlassNavigationAction(icon: "bell.fill") {
                            print("Notifications")
                        }
                        GlassNavigationAction(icon: "gear") {
                            print("Settings")
                        }
                    }
                }
                
                Spacer().frame(height: 40)
                
                // Example 2: With back button
                GlassNavigationBar(
                    title: "Building Details",
                    subtitle: "123 Main St",
                    showBackButton: true,
                    onBackTap: { print("Back tapped") }
                ) {
                    GlassNavigationAction(icon: "ellipsis") {
                        print("More options")
                    }
                }
                
                Spacer().frame(height: 40)
                
                // Example 3: Simple title only
                GlassNavigationBar(
                    title: "Tasks"
                )
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
