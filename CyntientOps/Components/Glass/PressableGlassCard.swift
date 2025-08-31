//
//  PressableGlassCard.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Integrated with CyntientOpsDesign color system
//  ✅ IMPROVED: Glass effects and press animations
//  ✅ ADDED: Haptic feedback and accessibility support
//

import SwiftUI

// MARK: - Pressable Glass Card
struct PressableGlassCard<Content: View>: View {
    // Content
    let content: Content
    let action: () -> Void
    
    // Style properties
    var intensity: GlassIntensity
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowRadius: CGFloat
    var borderWidth: CGFloat
    var hasGlow: Bool
    var glowColor: Color
    var isDisabled: Bool
    
    // Animation state
    @State private var isPressed = false
    @State private var isHovered = false
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        borderWidth: CGFloat = 1,
        hasGlow: Bool = false,
        glowColor: Color? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.borderWidth = borderWidth
        self.hasGlow = hasGlow
        self.glowColor = glowColor ?? CyntientOpsDesign.DashboardColors.info
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            
            // Haptic feedback
            impactFeedback.impactOccurred()
            
            // Quick press animation
            withAnimation(CyntientOpsDesign.Animations.spring) {
                isPressed = true
            }
            
            // Execute action
            action()
            
            // Reset press state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(CyntientOpsDesign.Animations.spring) {
                    isPressed = false
                }
            }
        }) {
            content
                .padding(padding)
                .background(glassBackground)
                .overlay(borderOverlay)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        .shadow(
            color: CyntientOpsDesign.DashboardColors.baseBackground.opacity(isPressed ? 0.4 : 0.3),
            radius: isPressed ? shadowRadius + 5 : shadowRadius,
            x: 0,
            y: isPressed ? 8 : 5
        )
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(CyntientOpsDesign.Animations.spring) {
                isHovered = hovering
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(CyntientOpsDesign.Animations.spring) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        ZStack {
            // Dark base with blur
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.8))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(intensity.material)
                        .opacity(0.5)
                )
            
            // Glass gradient overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(isPressed ? 0.1 : 0.3),
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(isPressed ? 0.05 : 0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Glow effect (optional)
            if hasGlow && !isDisabled {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(glowColor.opacity(isPressed ? 0.15 : 0.1))
                    .blur(radius: 10)
                    .opacity(isHovered ? 1.0 : 0.7)
            }
            
            // Pressed state overlay
            if isPressed {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.1))
            }
        }
    }
    
    // MARK: - Border Overlay
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isPressed ? 0.3 : 0.2),
                        Color.white.opacity(isPressed ? 0.1 : 0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: borderWidth
            )
    }
}

// MARK: - Pressable Glass Card Styles

enum PressableCardStyle {
    case primary
    case secondary
    case success
    case danger
    case warning
    
    var glowColor: Color {
        switch self {
        case .primary:
            return CyntientOpsDesign.DashboardColors.info
        case .secondary:
            return CyntientOpsDesign.DashboardColors.inactive
        case .success:
            return CyntientOpsDesign.DashboardColors.success
        case .danger:
            return CyntientOpsDesign.DashboardColors.critical
        case .warning:
            return CyntientOpsDesign.DashboardColors.warning
        }
    }
}

// MARK: - Convenience Extensions

extension PressableGlassCard {
    func cardStyle(_ style: PressableCardStyle) -> PressableGlassCard {
        PressableGlassCard(
            intensity: intensity,
            cornerRadius: cornerRadius,
            padding: padding,
            shadowRadius: shadowRadius,
            borderWidth: borderWidth,
            hasGlow: true,
            glowColor: style.glowColor,
            isDisabled: isDisabled,
            action: action,
            content: { content }
        )
    }
}

// MARK: - Preview
struct PressableGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Dark Elegance background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Clock In Card
                PressableGlassCard(hasGlow: true, glowColor: CyntientOpsDesign.DashboardColors.success) {
                    print("Clock In tapped")
                } content: {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.title2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        Text("CLOCK IN")
                            .font(.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .cardStyle(.success)
                
                // Task Card
                PressableGlassCard(intensity: .thin) {
                    print("Task tapped")
                } content: {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        Text("Complete Task")
                            .font(.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        Text("Mark this task as complete")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                .cardStyle(.primary)
                
                // Settings Card
                PressableGlassCard(intensity: .thick, cornerRadius: 30) {
                    print("Settings tapped")
                } content: {
                    VStack(spacing: 12) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        Text("Configure your preferences")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                
                // Disabled Card Example
                PressableGlassCard(isDisabled: true) {
                    print("This won't fire")
                } content: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.body)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        Text("Locked Feature")
                            .font(.subheadline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
                
                // Danger Action Card
                PressableGlassCard {
                    print("Delete tapped")
                } content: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.body)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                        Text("Delete Item")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                    }
                }
                .cardStyle(.danger)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
