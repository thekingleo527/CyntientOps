//
//  HeaderV3B.swift
//  CyntientOps v6.0 - Future-Ready Header
//
//  ✅ BRAND-FIRST: Logo on left establishes identity
//  ✅ AI-CENTRIC: Nova takes center stage
//  ✅ USER-FOCUSED: Profile and clock actions grouped right
//  ✅ FUTURE-READY: Supports voice, AR, wearables roadmap
//  ✅ PROGRESSIVE: Features appear conditionally
//

import SwiftUI
import Foundation
import Combine

struct HeaderV3B: View {
    // MARK: - Properties
    
    let workerName: String
    let nextTaskName: String?
    let showClockPill: Bool
    let isNovaProcessing: Bool
    let onProfileTap: () -> Void
    let onNovaPress: () -> Void
    let onNovaLongPress: () -> Void
    
    // Optional callbacks
    var onLogoTap: (() -> Void)?
    var onClockAction: (() -> Void)?
    
    // Future Phase callbacks
    var onVoiceCommand: (() -> Void)?
    var onARModeToggle: (() -> Void)?
    var onWearableSync: (() -> Void)?
    
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @State private var showNovaTooltip = false
    @State private var novaScale: CGFloat = 1.0
    @State private var clockedDuration = ""
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            headerBackground
            
            // Main content with proper layout
            HStack(spacing: 0) {
                // LEFT: Brand Logo (20%)
                brandSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(width: UIScreen.main.bounds.width * 0.2)
                
                // CENTER: Nova AI (40%)
                novaSection
                    .frame(maxWidth: .infinity)
                    .frame(width: UIScreen.main.bounds.width * 0.4)
                
                // RIGHT: User Profile & Clock (40%)
                userSection
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(width: UIScreen.main.bounds.width * 0.4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 80)
        .onReceive(timer) { _ in
            updateClockDuration()
        }
    }
    
    // MARK: - Background
    
    private var headerBackground: some View {
        ZStack {
            // Base glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Subtle gradient based on state
            LinearGradient(
                colors: [
                    backgroundAccentColor.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Bottom separator
            VStack {
                Spacer()
                Divider()
                    .opacity(0.3)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Brand Section (Left)
    
    private var brandSection: some View {
        Button(action: { onLogoTap?() }) {
            HStack(spacing: 8) {
                // Logo
                Image("CyntientOpsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                
                // Or text logo if image not found
                if UIImage(named: "CyntientOpsLogo") == nil {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("FRANCO")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("SPHERE")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .opacity(0.9)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onLogoTap == nil)
    }
    
    // MARK: - Nova Section (Center)
    
    private var novaSection: some View {
        VStack(spacing: 4) {
            // Future phase buttons arranged around Nova
            HStack(spacing: 16) {
                // Voice Command (Phase 1)
                if onVoiceCommand != nil {
                    futurePhaseButton(
                        icon: "mic.fill",
                        color: .purple,
                        action: { onVoiceCommand?() },
                        label: "Voice"
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Nova button (center)
                Button(action: handleNovaAction) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(novaBackgroundGradient)
                            .frame(width: 48, height: 48)
                            .shadow(color: novaGlowColor.opacity(0.3), radius: 8)
                        
                        // Nova icon
                        novaIcon
                            .scaleEffect(novaScale)
                        
                        // State indicators
                        if isNovaProcessing {
                            novaProcessingRing
                        }
                        
                        // Alert badge
                        if hasUrgentContext {
                            alertBadge
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .onLongPressGesture {
                    onNovaLongPress()
                }
                
                // AR Mode (Phase 2)
                if onARModeToggle != nil {
                    futurePhaseButton(
                        icon: "arkit",
                        color: .cyan,
                        action: { onARModeToggle?() },
                        label: "AR"
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Context message
            novaContextMessage
                .animation(.easeInOut, value: novaMessage)
        }
        .overlay(
            novaTooltip
                .opacity(showNovaTooltip ? 1 : 0)
                .offset(y: -60)
        )
    }
    
    private var novaIcon: some View {
        Group {
            if let novaImage = UIImage(named: "NovaAI") {
                Image(uiImage: novaImage)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
            } else {
                // Fallback icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating, isActive: isNovaProcessing)
            }
        }
    }
    
    private var novaProcessingRing: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(
                AngularGradient(
                    colors: [.white, .white.opacity(0.2)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: 54, height: 54)
            .rotationEffect(.degrees(isNovaProcessing ? 360 : 0))
            .animation(
                .linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isNovaProcessing
            )
    }
    
    private var alertBadge: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 12, height: 12)
            .overlay(
                Text("!")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            )
            .offset(x: 18, y: -18)
    }
    
    private var novaContextMessage: some View {
        Text(novaMessage)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(novaMessageColor)
            .lineLimit(1)
            .frame(height: 14)
    }
    
    private var novaTooltip: some View {
        Text("Tap for AI assistance")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
    }
    
    // MARK: - User Section (Right)
    
    private var userSection: some View {
        HStack(spacing: 12) {
            // Future Phase: Wearable sync indicator
            if onWearableSync != nil {
                wearableIndicator
            }
            
            // Clock status
            if showClockPill {
                clockStatusView
            }
            
            // Profile button
            profileButton
        }
    }
    
    private var wearableIndicator: some View {
        Button(action: { onWearableSync?() }) {
            Image(systemName: "applewatch")
                .font(.system(size: 16))
                .foregroundColor(.green)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.1))
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .transition(.scale.combined(with: .opacity))
    }
    
    private var clockStatusView: some View {
        Button(action: { onClockAction?() }) {
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(clockStatusColor)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(clockStatusColor.opacity(0.5))
                                .frame(width: 12, height: 12)
                                .opacity(isClocked ? 1 : 0)
                                .animation(
                                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: isClocked
                                )
                        )
                    
                    Text(isClocked ? "Clocked In" : "Clock In")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                if let building = contextAdapter.currentBuilding {
                    Text("\(building.name) • \(clockedDuration)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(clockBackgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(clockStatusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var profileButton: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 8) {
                // Name (optional, for larger screens)
                if UIScreen.main.bounds.width > 390 {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(profileGradient)
                        .frame(width: 40, height: 40)
                    
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helper Views
    
    private func futurePhaseButton(icon: String, color: Color, action: @escaping () -> Void, label: String) -> some View {
        VStack(spacing: 2) {
            Button(action: action) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(color.opacity(0.8))
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayName: String {
        let name = !workerName.isEmpty && workerName != "Worker"
            ? workerName
            : contextAdapter.currentWorker?.name ?? "Worker"
        
        // Show first name only for space
        return name.components(separatedBy: " ").first ?? name
    }
    
    private var initials: String {
        let name = displayName
        let components = name.components(separatedBy: " ")
        let first = components.first?.first ?? "F"
        let last = components.count > 1 ? components.last?.first : nil
        
        if let last = last {
            return "\(first)\(last)".uppercased()
        } else {
            return String(first).uppercased()
        }
    }
    
    private var isClocked: Bool {
        contextAdapter.currentBuilding != nil
    }
    
    private var clockStatusColor: Color {
        isClocked ? .green : .orange
    }
    
    private var clockBackgroundColor: Color {
        isClocked ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)
    }
    
    private var backgroundAccentColor: Color {
        if hasUrgentContext {
            return .red
        } else if isNovaProcessing {
            return .purple
        } else if isClocked {
            return .green
        } else {
            return .blue
        }
    }
    
    private var profileGradient: LinearGradient {
        let baseColor = getRoleColor()
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func getRoleColor() -> Color {
        guard let role = contextAdapter.currentWorker?.role else { return .blue }
        switch role {
        case .worker: return .blue
        case .admin: return .green
        case .manager: return .orange
        case .client: return .purple
        }
    }
    
    private var novaBackgroundGradient: LinearGradient {
        let colors: [Color] = hasUrgentContext
            ? [.red.opacity(0.8), .orange.opacity(0.8)]
            : isNovaProcessing
                ? [.purple, .blue]
                : [.blue.opacity(0.8), .purple.opacity(0.8)]
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var novaGlowColor: Color {
        hasUrgentContext ? .red : .blue
    }
    
    private var hasUrgentContext: Bool {
        // Check for urgent conditions
        let hasUrgentTask = contextAdapter.todaysTasks.contains { task in
            task.urgency == .urgent || task.urgency == .critical
        }
        
        let hasDSNY = nextTaskName?.lowercased().contains("dsny") ?? false
        
        return hasUrgentTask || hasDSNY
    }
    
    private var novaMessage: String {
        if isNovaProcessing {
            return "Analyzing..."
        } else if hasUrgentContext {
            return "Urgent task requires attention"
        } else if let task = nextTaskName {
            return "Ready to help with \(task)"
        } else if isClocked {
            return "Monitoring your progress"
        } else {
            return "Tap for AI assistance"
        }
    }
    
    private var novaMessageColor: Color {
        if hasUrgentContext {
            return .red
        } else if isNovaProcessing {
            return .purple
        } else {
            return .secondary
        }
    }
    
    // MARK: - Methods
    
    private func handleNovaAction() {
        // Animate press
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            novaScale = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                novaScale = 1.0
            }
        }
        
        onNovaPress()
        
        // Show tooltip for first-time users
        if !UserDefaults.standard.bool(forKey: "hasSeenNovaTooltip") {
            withAnimation {
                showNovaTooltip = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showNovaTooltip = false
                }
                UserDefaults.standard.set(true, forKey: "hasSeenNovaTooltip")
            }
        }
    }
    
    private func updateClockDuration() {
        guard let building = contextAdapter.currentBuilding else {
            clockedDuration = ""
            return
        }
        
        let duration = Date().timeIntervalSince(Date()) // Placeholder
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            clockedDuration = "\(hours)h \(minutes)m"
        } else {
            clockedDuration = "\(minutes)m"
        }
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Current state - Worker clocked in
            HeaderV3B(
                workerName: "Kevin Dutan",
                nextTaskName: "Museum Security Check",
                showClockPill: true,
                isNovaProcessing: false,
                onProfileTap: { print("Profile") },
                onNovaPress: { print("Nova") },
                onNovaLongPress: { print("Nova long press") }
            )
            
            // With future features enabled
            HeaderV3B(
                workerName: "Edwin Rodriguez",
                nextTaskName: nil,
                showClockPill: true,
                isNovaProcessing: true,
                onProfileTap: { },
                onNovaPress: { },
                onNovaLongPress: { },
                onVoiceCommand: { print("Voice command") },
                onARModeToggle: { print("AR mode") },
                onWearableSync: { print("Wearable sync") }
            )
            
            // Not clocked in
            HeaderV3B(
                workerName: "Mercedes Gonzalez",
                nextTaskName: nil,
                showClockPill: false,
                isNovaProcessing: false,
                onProfileTap: { },
                onNovaPress: { },
                onNovaLongPress: { }
            )
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Future Phases Roadmap

/*
🚀 FUTURE PHASES INTEGRATION PLAN:

Phase 1: Voice Integration (Q2 2025)
- Voice command button flanks Nova AI
- Hands-free task completion
- Multi-language support (English/Spanish)
- Voice-to-text notes
- "Hey Nova" wake word

Phase 2: AR Features (Q3 2025)
- AR mode button opposite voice
- Building navigation overlay
- Equipment identification
- Visual task guides
- Safety hazard detection

Phase 3: Advanced AI (Q4 2025)
- Nova learns worker patterns
- Predictive task suggestions
- Anomaly detection alerts
- Performance optimization
- Contextual recommendations

Phase 4: Wearable Support (Q1 2026)
- Apple Watch sync indicator
- Smart glasses integration
- Haptic feedback
- Emergency alerts
- Hands-free operations

Phase 5: Integration Ecosystem (Q2 2026)
- Third-party tool badges
- API marketplace access
- Custom workflow buttons
- Enterprise integrations
- Plugin architecture

LAYOUT EVOLUTION:
Current: [Logo] ← [Nova AI] → [User/Clock]
Phase 1: [Logo] ← [Voice][Nova AI] → [User/Clock]
Phase 2: [Logo] ← [Voice][Nova AI][AR] → [User/Clock]
Phase 4: [Logo] ← [Voice][Nova AI][AR] → [Watch][User/Clock]

The header is designed to gracefully accommodate new features without disrupting the core layout. Future buttons appear conditionally based on available callbacks.
*/
