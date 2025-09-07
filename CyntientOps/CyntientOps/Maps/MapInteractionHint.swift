//
//  MapInteractionHint.swift
//  CyntientOps
//
//  ✅ V6.0 UPDATED: Aligned with GRDB implementation and actor architecture
//  ✅ FIXED: Animation syntax errors and SwiftUI binding issues
//  ✅ ENHANCED: Better state management and user preference integration
//  ✅ COMPATIBLE: Works with three-dashboard system
//

import SwiftUI
import Foundation

struct MapInteractionHint: View {
    @Binding var showHint: Bool
    let hasSeenHint: Bool
    
    // MARK: - State Management
    @State private var opacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var autoHideTimer: Timer?
    @State private var isVisible: Bool = false
    
    // MARK: - Animation Constants
    private let animationDuration: Double = 0.6
    private let autoHideDuration: Double = 4.0
    private let pulseDuration: Double = 1.8
    private let maxPulseScale: CGFloat = 1.08
    
    // MARK: - User Preference Keys
    private static let hasSeenMapHintKey = "franco_has_seen_map_hint"
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            hintContainer
                .opacity(opacity)
                .scaleEffect(pulseScale)
                .animation(.easeOut(duration: animationDuration), value: opacity)
                .animation(
                    shouldPulse ?
                    .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true) :
                    .easeOut(duration: 0.3),
                    value: pulseScale
                )
        }
        .onAppear {
            startHintSequence()
        }
        .onDisappear {
            cleanup()
        }
        .onChange(of: showHint) { newValue in
            if !newValue {
                hideHint()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldPulse: Bool {
        !hasSeenHint && isVisible
    }
    
    // MARK: - Hint Container
    
    private var hintContainer: some View {
        VStack(spacing: 16) {
            swipeIndicator
            hintContent
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(hintBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 44) // Safe area + extra padding
    }
    
    // MARK: - Background with Glass Effect
    
    private var hintBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Swipe Indicator
    
    private var swipeIndicator: some View {
        VStack(spacing: 10) {
            // Animated chevron
            Image(systemName: "chevron.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .scaleEffect(shouldPulse ? pulseScale : 1.0)
            
            // Handle bar
            Capsule()
                .fill(.white.opacity(0.4))
                .frame(width: 40, height: 5)
                .overlay(
                    Capsule()
                        .fill(.white.opacity(0.6))
                        .frame(width: 32, height: 3)
                )
        }
    }
    
    // MARK: - Hint Content
    
    private var hintContent: some View {
        VStack(spacing: 8) {
            Text("Swipe up to view full map")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Text("Explore all your buildings and routes")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
    
    // MARK: - Animation Lifecycle
    
    private func startHintSequence() {
        guard showHint else { return }
        
        isVisible = true
        
        // Delay appearance to ensure smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: animationDuration)) {
                opacity = 1.0
            }
            
            // Start pulse for first-time users
            if !hasSeenHint {
                withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                    pulseScale = maxPulseScale
                }
            }
            
            // Auto-hide timer
            startAutoHideTimer()
        }
    }
    
    private func startAutoHideTimer() {
        stopAutoHideTimer()
        
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDuration, repeats: false) { _ in
            dismissHint()
        }
    }
    
    private func stopAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    private func dismissHint() {
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 0.0
            pulseScale = 1.0
        }
        
        // Mark as seen and hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            markAsSeen()
            showHint = false
            isVisible = false
        }
    }
    
    private func hideHint() {
        stopAutoHideTimer()
        
        withAnimation(.easeOut(duration: animationDuration * 0.7)) {
            opacity = 0.0
            pulseScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration * 0.7)) {
            isVisible = false
        }
    }
    
    private func cleanup() {
        stopAutoHideTimer()
    }
    
    // MARK: - User Preferences
    
    private func markAsSeen() {
        UserDefaults.standard.set(true, forKey: Self.hasSeenMapHintKey)
        print("🗺️ Map interaction hint marked as seen")
    }
    
    static func hasUserSeenHint() -> Bool {
        UserDefaults.standard.bool(forKey: hasSeenMapHintKey)
    }
    
    static func resetHintStatus() {
        UserDefaults.standard.removeObject(forKey: hasSeenMapHintKey)
        print("🔄 Map interaction hint status reset")
    }
}

// MARK: - Convenience Extensions

extension MapInteractionHint {
    /// Create a MapInteractionHint with automatic UserDefaults handling
    static func automatic(showHint: Binding<Bool>) -> some View {
        let hasSeenHint = Self.hasUserSeenHint()
        return MapInteractionHint(
            showHint: showHint,
            hasSeenHint: hasSeenHint
        )
    }
    
    /// Force show hint (useful for tutorials or onboarding)
    static func forceShow(showHint: Binding<Bool>) -> some View {
        return MapInteractionHint(
            showHint: showHint,
            hasSeenHint: false
        )
    }
    
    /// Show hint for returning users (no pulse animation)
    static func forReturningUser(showHint: Binding<Bool>) -> some View {
        return MapInteractionHint(
            showHint: showHint,
            hasSeenHint: true
        )
    }
}

// MARK: - UserDefaults CyntientOps Extension

extension UserDefaults {
    /// CyntientOps app preference keys
    enum CyntientOpsKeys {
        static let hasSeenMapHint = "franco_has_seen_map_hint"
        static let hasSeenDashboardTour = "franco_has_seen_dashboard_tour"
        static let lastSelectedDashboard = "franco_last_selected_dashboard"
        static let preferredMapStyle = "franco_preferred_map_style"
    }
    
    /// Check if the user has seen the map interaction hint
    var francoHasSeenMapHint: Bool {
        get { bool(forKey: CyntientOpsKeys.hasSeenMapHint) }
        set { set(newValue, forKey: CyntientOpsKeys.hasSeenMapHint) }
    }
    
    /// Reset all CyntientOps onboarding hints
    func resetCyntientOpsOnboardingHints() {
        removeObject(forKey: CyntientOpsKeys.hasSeenMapHint)
        removeObject(forKey: CyntientOpsKeys.hasSeenDashboardTour)
        print("🔄 All CyntientOps onboarding hints reset")
    }
    
    /// Get/set last selected dashboard for continuity
    var francoLastSelectedDashboard: String? {
        get { string(forKey: CyntientOpsKeys.lastSelectedDashboard) }
        set { set(newValue, forKey: CyntientOpsKeys.lastSelectedDashboard) }
    }
}

// MARK: - View Integration Helpers

extension View {
    /// Add map interaction hint overlay
    func withMapInteractionHint(
        showHint: Binding<Bool>,
        hasSeenHint: Bool? = nil
    ) -> some View {
        self.overlay(
            MapInteractionHint(
                showHint: showHint,
                hasSeenHint: hasSeenHint ?? MapInteractionHint.hasUserSeenHint()
            ),
            alignment: .bottom
        )
    }
    
    /// Add automatic map interaction hint
    func withAutomaticMapHint(showHint: Binding<Bool>) -> some View {
        self.overlay(
            MapInteractionHint.automatic(showHint: showHint),
            alignment: .bottom
        )
    }
}

// MARK: - Preview Provider

struct MapInteractionHint_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // First-time user preview (with pulse animation)
            PreviewContainer(
                title: "First-Time User",
                hasSeenHint: false,
                colors: [.blue, .purple]
            )
            
            // Returning user preview (no pulse)
            PreviewContainer(
                title: "Returning User",
                hasSeenHint: true,
                colors: [.green, .blue]
            )
            
            // Interactive demo
            InteractiveDemoView()
                .previewDisplayName("Interactive Demo")
        }
    }
}

// MARK: - Preview Support Views

private struct PreviewContainer: View {
    let title: String
    let hasSeenHint: Bool
    let colors: [Color]
    
    @State private var showHint = true
    
    var body: some View {
        ZStack {
            mockMapBackground(colors: colors)
            
            if showHint {
                MapInteractionHint(
                    showHint: $showHint,
                    hasSeenHint: hasSeenHint
                )
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName(title)
    }
    
    private func mockMapBackground(colors: [Color]) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: colors.map { $0.opacity(0.8) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        Text("CyntientOps Map")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 60)
            )
    }
}

private struct InteractiveDemoView: View {
    @State private var showDemoHint = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Map Interaction Hint")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    demoButton("Show First-Time Hint", color: .blue) {
                        MapInteractionHint.resetHintStatus()
                        showDemoHint = true
                    }
                    
                    demoButton("Show Returning User Hint", color: .green) {
                        UserDefaults.standard.francoHasSeenMapHint = true
                        showDemoHint = true
                    }
                    
                    demoButton("Reset All Hints", color: .orange) {
                        // Reset onboarding hints
                        UserDefaults.standard.removeObject(forKey: "has_seen_map_hint")
                        UserDefaults.standard.removeObject(forKey: "has_seen_building_hint")
                        UserDefaults.standard.removeObject(forKey: "has_seen_task_hint")
                    }
                }
                
                Text("Hint auto-hides after 4 seconds")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if showDemoHint {
                MapInteractionHint.automatic(showHint: $showDemoHint)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func demoButton(
        _ title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(color.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
