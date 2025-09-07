//
//  GlassTabBar.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Glass morphism with sophisticated animations
//  ✅ ADDED: Haptic feedback and accessibility
//  ✅ ALIGNED: With CyntientOpsDesign color system
//

import SwiftUI

// MARK: - Glass Tab Bar
struct GlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [GlassTabItem]
    
    // Animation state
    @State private var animatedTab: Int = 0
    @State private var tabWidths: [Int: CGFloat] = [:]
    @Namespace private var tabNamespace
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(selectedTab: Binding<Int>, tabs: [GlassTabItem]) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self._animatedTab = State(initialValue: selectedTab.wrappedValue)
    }
    
    var body: some View {
        // Dark glass card container
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                tabButton(for: index)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    tabWidths[index] = geo.size.width
                                }
                        }
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: Color.black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 10
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .onChange(of: selectedTab) { newValue in
            withAnimation(CyntientOpsDesign.Animations.spring) {
                animatedTab = newValue
            }
        }
    }
    
    // MARK: - Tab Button
    
    private func tabButton(for index: Int) -> some View {
        Button(action: {
            impactFeedback.impactOccurred()
            withAnimation(CyntientOpsDesign.Animations.spring) {
                selectedTab = index
                animatedTab = index
            }
        }) {
            VStack(spacing: 6) {
                // Icon with animation
                Image(systemName: animatedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                    .font(.system(size: 22, weight: animatedTab == index ? .semibold : .regular))
                    .foregroundColor(tabColor(for: index))
                    .scaleEffect(animatedTab == index ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animatedTab)
                
                // Title
                Text(tabs[index].title)
                    .font(.system(size: 11, weight: animatedTab == index ? .semibold : .medium))
                    .foregroundColor(tabColor(for: index))
                    .opacity(animatedTab == index ? 1.0 : 0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if animatedTab == index {
                        // Selected tab background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.3),
                                        CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .matchedGeometryEffect(id: "tab", in: tabNamespace)
                            .padding(.horizontal, 8)
                    }
                }
            )
        }
        .accessibilityLabel("\(tabs[index].title) tab")
        .accessibilityHint(animatedTab == index ? "Currently selected" : "Double tap to select")
    }
    
    // MARK: - Helpers
    
    private func tabColor(for index: Int) -> Color {
        if animatedTab == index {
            // Selected tab uses accent color
            return CyntientOpsDesign.DashboardColors.info
        } else {
            // Unselected tabs use muted text
            return CyntientOpsDesign.DashboardColors.secondaryText
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            // Dark base with heavy blur
            RoundedRectangle(cornerRadius: 24)
                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.9))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .opacity(0.7)
                )
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Inner border
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Floating Glass Tab Bar Variant

struct FloatingGlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [GlassTabItem]
    
    @State private var showLabels = true
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(tabs.indices, id: \.self) { index in
                floatingTabButton(for: index)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.95))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.4),
            radius: 30,
            x: 0,
            y: 15
        )
    }
    
    private func floatingTabButton(for index: Int) -> some View {
        Button(action: {
            withAnimation(CyntientOpsDesign.Animations.spring) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                    .font(.system(size: 24, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(
                        selectedTab == index ?
                        CyntientOpsDesign.DashboardColors.info :
                        CyntientOpsDesign.DashboardColors.secondaryText
                    )
                    .scaleEffect(selectedTab == index ? 1.15 : 1.0)
                
                if showLabels {
                    Text(tabs[index].title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(
                            selectedTab == index ?
                            CyntientOpsDesign.DashboardColors.info :
                            CyntientOpsDesign.DashboardColors.tertiaryText
                        )
                        .opacity(selectedTab == index ? 1.0 : 0.6)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Preview

struct GlassTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Dark Elegance background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Standard Glass Tab Bar
                VStack(spacing: 40) {
                    Text("Standard Tab Bar")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    GlassTabBar(
                        selectedTab: .constant(0),
                        tabs: [
                            GlassTabItem(title: "Dashboard", icon: "house", selectedIcon: "house.fill"),
                            GlassTabItem(title: "Tasks", icon: "list.bullet", selectedIcon: "list.bullet"),
                            GlassTabItem(title: "Buildings", icon: "building", selectedIcon: "building.fill"),
                            GlassTabItem(title: "Profile", icon: "person", selectedIcon: "person.fill")
                        ]
                    )
                }
                
                Spacer()
                
                // Floating Variant
                VStack(spacing: 40) {
                    Text("Floating Variant")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    FloatingGlassTabBar(
                        selectedTab: .constant(1),
                        tabs: [
                            GlassTabItem(title: "Home", icon: "house", selectedIcon: "house.fill"),
                            GlassTabItem(title: "Search", icon: "magnifyingglass", selectedIcon: "magnifyingglass"),
                            GlassTabItem(title: "Add", icon: "plus.circle", selectedIcon: "plus.circle.fill"),
                            GlassTabItem(title: "Profile", icon: "person", selectedIcon: "person.fill")
                        ]
                    )
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
