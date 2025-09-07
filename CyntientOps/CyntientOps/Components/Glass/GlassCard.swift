//
//
//  GlassCard.swift
//  CyntientOps
//
//  ✅ FIXED: Animation typo corrected to Animation
//  ✅ FIXED: Removed duplicate GlassIntensity enum - using one from GlassTypes.swift
//  ✅ ALIGNED: With Phase 2.1 implementation
//

import SwiftUI

// MARK: - Glass Card View
struct GlassCard<Content: View>: View {
    // Content
    let content: Content
    
    // Customization
    var intensity: GlassIntensity
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowRadius: CGFloat
    var borderWidth: CGFloat
    var isHovering: Bool
    var hasGlow: Bool
    var glowColor: Color
    
    // Animation state
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        borderWidth: CGFloat = 1,
        isHovering: Bool = false,
        hasGlow: Bool = false,
        glowColor: Color = Color.blue,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.borderWidth = borderWidth
        self.isHovering = isHovering
        self.hasGlow = hasGlow
        self.glowColor = glowColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(glassBackground)
            .overlay(borderOverlay)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.2),
                radius: shadowRadius,
                x: 0,
                y: 5
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .onTapGesture {
                // ✅ FIXED: Changed Animation to Animation
                withAnimation(Animation.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // ✅ FIXED: Changed Animation to Animation
                    withAnimation(Animation.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        ZStack {
            // Base material blur using existing GlassIntensity.material
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(intensity.material)
            
            // Glass gradient overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Optional glow effect
            if hasGlow {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.5), lineWidth: borderWidth)
                    .blur(radius: 3)
            }
        }
    }
    
    // MARK: - Border Overlay
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: borderWidth
            )
    }
}

// MARK: - Preview
struct GlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                GlassCard(intensity: GlassIntensity.thin) {
                    Text("Thin Glass")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                }
                
                GlassCard(intensity: GlassIntensity.regular) {
                    Text("Regular Glass")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                }
                
                GlassCard(intensity: GlassIntensity.thick, hasGlow: true, glowColor: .blue) {
                    Text("Thick Glass with Glow")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .padding()
        }
    }
}
