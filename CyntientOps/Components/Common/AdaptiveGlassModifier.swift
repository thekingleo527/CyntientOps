//
//  AdaptiveGlassModifier.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Removed conflicting GlassIntensity enum
//  ✅ UNIFIED: Now uses GlassIntensity from GlassTypes.swift
//  ✅ ALIGNED: Backward compatibility for existing code maintained
//  ✅ CONSOLIDATED: Extracted all glass utilities from GlassMorphismStyles.swift
//  ✅ CONSOLIDATED: Extracted all button styles from GlassButtonModifier.swift
//  ✅ CONSOLIDATED: Extracted all animation components from GlassTransitions.swift
//  🔧 HF-25: UNIFIED GLASSMORPHISM SYSTEM (2040 STANDARD)
//  Consistent glass styling across all CyntientOps components
//

import SwiftUI

struct AdaptiveGlassModifier: ViewModifier {
    let isCompact: Bool
    let intensity: GlassIntensity  // ✅ FIXED: Using unified GlassIntensity from GlassTypes.swift
    
    func body(content: Content) -> some View {
        if isCompact {
            content.francoGlassCardCompact(intensity: intensity)
        } else {
            content.francoGlassCard(intensity: intensity)
        }
    }
}

// MARK: - 🔧 HF-25: UNIFIED GLASS CARD EXTENSIONS

extension View {
    /// Standard Franco glass card with consistent Material Design 2040 styling
    func francoGlassCard(intensity: GlassIntensity = .regular) -> some View {
        self
            .padding(16)
            .background(intensity.material, in: RoundedRectangle(cornerRadius: 16))  // ✅ Using unified GlassIntensity.material
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(intensity.strokeOpacity), lineWidth: 1)  // ✅ Using unified GlassIntensity.strokeOpacity
            )
            .shadow(color: .black.opacity(0.15), radius: intensity.shadowRadius, x: 0, y: 6)  // ✅ Using unified GlassIntensity.shadowRadius
    }
    
    /// Compact glass card for tight spaces
    func francoGlassCardCompact(intensity: GlassIntensity = .thin) -> some View {
        self
            .padding(12)
            .background(intensity.material, in: RoundedRectangle(cornerRadius: 12))  // ✅ Using unified GlassIntensity.material
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(intensity.strokeOpacity), lineWidth: 0.5)  // ✅ Using unified GlassIntensity.strokeOpacity
            )
            .shadow(color: .black.opacity(0.1), radius: intensity.shadowRadius * 0.6, x: 0, y: 3)  // ✅ Using unified GlassIntensity.shadowRadius
    }
    
    /// Adaptive glass modifier that switches between regular and compact
    func adaptiveGlass(isCompact: Bool, intensity: GlassIntensity = .regular) -> some View {
        self.modifier(AdaptiveGlassModifier(isCompact: isCompact, intensity: intensity))
    }
}

// MARK: - Glass Effect Presets for Common Use Cases

extension View {
    /// Property card glass effect (optimized for dashboard cards)
    func propertyCardGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.regular)
    }
    
    /// Metric card glass effect (optimized for data display)
    func metricCardGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.thin)
    }
    
    /// Header glass effect (optimized for navigation)
    func headerGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.ultraThin)
    }
    
    /// Modal glass effect (optimized for overlays)
    func modalGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.thick)
    }
}

// MARK: - Additional Glass Effects (Extracted from GlassMorphismStyles)

extension View {
    /// Glass effect with custom background color
    func glassTinted(_ color: Color, intensity: GlassIntensity = .regular) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.opacity(0.1))
                    )
            )
    }
    
    /// Glass effect with pulsing animation
    func glassPulsing(color: Color = .blue, intensity: GlassIntensity = .regular) -> some View {
        self
            .modifier(PulsingGlassModifier(color: color))
    }
    
    /// Glass effect with shimmer animation
    func glassShimmer(intensity: GlassIntensity = .regular) -> some View {
        self
            .modifier(ShimmerGlassModifier())
    }
}

// MARK: - Glass Animation Modifiers (Extracted from GlassMorphismStyles)

struct PulsingGlassModifier: ViewModifier {
    let color: Color
    @State private var isPulsing = false
    
    init(color: Color) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(isPulsing ? 0.8 : 0.3), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerGlassModifier: ViewModifier {
    @State private var startPoint = UnitPoint.topLeading
    @State private var endPoint = UnitPoint.bottomTrailing
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: startPoint
                )
                .onAppear {
                    withAnimation {
                        startPoint = .bottomTrailing
                        endPoint = .topLeading
                    }
                }
            )
    }
}

// MARK: - Glass Typography Helpers (Extracted from GlassMorphismStyles)

extension Text {
    /// Applies glass-friendly text styling
    func glassText(size: Font = .body, weight: Font.Weight = .medium) -> some View {
        self
            .font(size.weight(weight))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
    
    /// Applies glass heading styling
    func glassHeading() -> some View {
        self.glassText(size: .title2, weight: .bold)
    }
    
    /// Applies glass subtitle styling
    func glassSubtitle() -> some View {
        self.glassText(size: .subheadline, weight: .medium)
            .foregroundColor(.white.opacity(0.8))
    }
    
    /// Applies glass caption styling
    func glassCaption() -> some View {
        self.glassText(size: .caption, weight: .regular)
            .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Glass Color Utilities (Extracted from GlassMorphismStyles)

extension Color {
    /// Glass-friendly colors with proper opacity
    static let glassWhite = Color.white.opacity(0.15)
    static let glassBlack = Color.black.opacity(0.15)
    static let glassBlue = Color.blue.opacity(0.2)
    static let glassPurple = Color.purple.opacity(0.2)
    static let glassGreen = Color.green.opacity(0.2)
    static let glassOrange = Color.orange.opacity(0.2)
    static let glassRed = Color.red.opacity(0.2)
    
    /// Creates a glass-friendly version of any color
    func glassVariant(opacity: Double = 0.2) -> Color {
        return self.opacity(opacity)
    }
}

// MARK: - Glass Layout Helpers (Extracted from GlassMorphismStyles)

extension View {
    /// Standard glass card spacing for CyntientOps
    func francoSpacing() -> some View {
        self.padding(.vertical, 12)
    }
    
    /// Standard glass section spacing
    func francoSectionSpacing() -> some View {
        self.padding(.vertical, 20)
    }
    
    /// Glass-friendly divider
    func glassDivider() -> some View {
        VStack {
            self
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal)
        }
    }
}

// MARK: - Safe Area Utilities (Extracted and Enhanced)

extension View {
    /// Smart safe area handling for glass components
    func glassSafeArea() -> some View {
        self
            .ignoresSafeArea(edges: [.horizontal, .bottom])
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
    }
    
    /// Glass navigation bar safe area
    func glassNavigationSafeArea() -> some View {
        self.padding(.top, getSafeAreaTop())
    }
}

// MARK: - Helper Functions (Extracted from GlassMorphismStyles)

private func getSafeAreaTop() -> CGFloat {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return 0
    }
    return window.safeAreaInsets.top
}

// MARK: - Glass Configuration (Extracted from GlassMorphismStyles)

struct GlassConfiguration {
    static let defaultCornerRadius: CGFloat = 16
    static let compactCornerRadius: CGFloat = 12
    static let defaultPadding: CGFloat = 16
    static let compactPadding: CGFloat = 12
    static let defaultShadowRadius: CGFloat = 10
    static let strokeOpacity: Double = 0.1
    
    // Animation durations
    static let quickAnimation: Double = 0.2
    static let standardAnimation: Double = 0.3
    static let slowAnimation: Double = 0.5
}

// MARK: - Glass Button Modifiers (Extracted from GlassButtonModifier)

struct GlassButtonModifier: ViewModifier {
    var style: ButtonGlassStyle
    var size: ButtonGlassSize
    
    init(style: ButtonGlassStyle = .secondary, size: ButtonGlassSize = .medium) {
        self.style = style
        self.size = size
    }
    
    func body(content: Content) -> some View {
        content
            .font(size.font)
            .foregroundColor(style.textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(style.backgroundOpacity)
                    
                    // Color overlay
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(style.backgroundColor)
                        .opacity(style.colorOpacity)
                    
                    // Border
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: 1)
                        .opacity(style.borderOpacity)
                }
            )
            .scaleEffect(1.0)
            .animation(Animation.easeInOut(duration: 0.15), value: UUID())
    }
}

// MARK: - Button Style Enums (Extracted from GlassButtonModifier)

enum ButtonGlassStyle {
    case primary
    case secondary
    case ghost
    case danger
    case success
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .white
        case .ghost: return .clear
        case .danger: return .red
        case .success: return .green
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .white
        case .ghost: return .white
        case .danger: return .white
        case .success: return .white
        }
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .primary: return 0.3
        case .secondary: return 0.2
        case .ghost: return 0.1
        case .danger: return 0.3
        case .success: return 0.3
        }
    }
    
    var colorOpacity: Double {
        switch self {
        case .primary: return 0.3
        case .secondary: return 0.1
        case .ghost: return 0
        case .danger: return 0.3
        case .success: return 0.3
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .white
        case .ghost: return .white
        case .danger: return .red
        case .success: return .green
        }
    }
    
    var borderOpacity: Double {
        switch self {
        case .primary: return 0.5
        case .secondary: return 0.3
        case .ghost: return 0.2
        case .danger: return 0.5
        case .success: return 0.5
        }
    }
}

enum ButtonGlassSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .headline
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
}

// MARK: - Glass Button Extensions (Extracted from GlassButtonModifier)

extension View {
    /// Apply glass button styling to any view
    func glassButton(
        style: ButtonGlassStyle = .secondary,
        size: ButtonGlassSize = .medium
    ) -> some View {
        modifier(GlassButtonModifier(style: style, size: size))
    }
}

// Fix for foregroundColor on Button
extension Button {
    func glassButtonWithColor() -> some View {
        self.buttonStyle(PlainButtonStyle())
            .glassButton()
    }
}

// Convenience Button Extensions
extension Button where Label == Text {
    /// Create a glass-styled button with text
    static func glass(
        _ title: String,
        style: ButtonGlassStyle = .primary,
        size: ButtonGlassSize = .medium,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .glassButton(style: style, size: size)
    }
}

// MARK: - Backward Compatibility
// Keep old function names working for existing code

extension View {
    @available(*, deprecated, message: "Use francoGlassCard(intensity:) instead")
    func glassMorphismCard() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.regular)
    }
    
    @available(*, deprecated, message: "Use francoGlassCardCompact(intensity:) instead")
    func glassMorphismCardCompact() -> some View {
        self.francoGlassCardCompact(intensity: GlassIntensity.thin)
    }
}

// MARK: - Glass Animation Components (Extracted from GlassTransitions.swift)

// MARK: - Animated Glass Card
struct AnimatedGlassCard<Content: View>: View {
    let content: Content
    let intensity: GlassIntensity
    let animateOnAppear: Bool
    
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    init(
        intensity: GlassIntensity = .regular,
        animateOnAppear: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.animateOnAppear = animateOnAppear
    }
    
    var body: some View {
        content
            .francoGlassCard(intensity: intensity)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                if animateOnAppear {
                    withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                        scale = 1.0
                        opacity = 1.0
                        isVisible = true
                    }
                } else {
                    scale = 1.0
                    opacity = 1.0
                    isVisible = true
                }
            }
    }
}

// MARK: - Floating Animation Modifier
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 10, duration: Double = 3.0) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? amplitude : 0)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

// MARK: - Shimmer Effect Modifier (Enhanced version)
struct ShimmerEffectModifier: ViewModifier {
    @State private var isShimmering = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isShimmering ? 300 : -300)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isShimmering
                    )
                    .mask(content)
            )
            .onAppear {
                isShimmering = true
            }
    }
}

// MARK: - Pulsing Glow Effect Modifier
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    @State private var isPulsing = false
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(isPulsing ? 0.3 : 0.1))
                    .blur(radius: isPulsing ? 10 : 5)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - PropertyCard Live Update Animation (v6.0 Feature)
struct PropertyCardUpdateModifier: ViewModifier {
    @State private var isUpdating = false
    let updateTrigger: Bool
    
    init(updateTrigger: Bool) {
        self.updateTrigger = updateTrigger
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isUpdating ? 1.02 : 1.0)
            .animation(Animation.spring(response: 0.4, dampingFraction: 0.7), value: isUpdating)
            .onChange(of: updateTrigger) { _ in
                withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.7)) {
                    isUpdating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.7)) {
                        isUpdating = false
                    }
                }
            }
    }
}

// MARK: - Dashboard Switch Animation (v6.0 Feature)
struct DashboardSwitchModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.0 : 0.95)
            .opacity(isActive ? 1.0 : 0.7)
            .animation(Animation.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Glass Hover Modifier
struct GlassHoverModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.3 : 0.2), radius: isHovered ? 15 : 8)
            .animation(Animation.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .onTapGesture {
                // iOS doesn't have onHover, use tap for interaction
                withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.8)) {
                    isHovered.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.8)) {
                        isHovered = false
                    }
                }
            }
    }
}

// MARK: - Animated Glass Appear Modifier
struct AnimatedGlassAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    init(delay: Double) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0)
            .blur(radius: isVisible ? 0 : 10)
            .onAppear {
                withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Enhanced View Extensions for Glass Animations
extension View {
    func animatedGlassAppear(delay: Double = 0) -> some View {
        self.modifier(AnimatedGlassAppearModifier(delay: delay))
    }
    
    func floating(amplitude: CGFloat = 10, duration: Double = 3.0) -> some View {
        self.modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
    
    func shimmerEffect() -> some View {
        self.modifier(ShimmerEffectModifier())
    }
    
    func pulsingGlow(color: Color = .blue) -> some View {
        self.modifier(PulsingGlowModifier(color: color))
    }
    
    func glassHover() -> some View {
        self.modifier(GlassHoverModifier())
    }
    
    // v6.0 Dashboard Extensions
    func propertyCardUpdate(trigger: Bool) -> some View {
        self.modifier(PropertyCardUpdateModifier(updateTrigger: trigger))
    }
    
    func dashboardActive(_ isActive: Bool) -> some View {
        self.modifier(DashboardSwitchModifier(isActive: isActive))
    }
}

// MARK: - Glass Loading State Component
struct GlassLoadingState: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Success Checkmark Animation
struct GlassSuccessCheckmark: View {
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(isVisible ? 1.0 : 0.1)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isVisible)
            
            Image(systemName: "checkmark")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .scaleEffect(isVisible ? 1.0 : 0.1)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: isVisible)
        }
        .onAppear {
            isVisible = true
        }
    }
}
