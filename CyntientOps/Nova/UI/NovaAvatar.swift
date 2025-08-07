import SwiftUI

//
//  NovaAvatar.swift - HOLOGRAPHIC AI ASSISTANT AVATAR
//  CyntientOps v6.0
//
//  🔮 HOLOGRAPHIC NOVA AVATAR - Enhanced with Persistent Image Architecture
//  ✅ PERSISTENT: Uses NovaAIManager for cached image loading
//  ✅ HOLOGRAPHIC: Supports holographic mode transformations
//  ✅ ENHANCED: Advanced breathing, rotation, and status animations  
//  ✅ PRESERVED: All original functionality with performance improvements
//  ✅ REACTIVE: Responds to NovaAIManager state changes
//  ✅ LONG PRESS: Holographic mode trigger
//

// MARK: - Nova Avatar Component
/// An animated AI assistant avatar with persistent image loading and holographic support.
/// Features sophisticated animations for different states and holographic mode activation.
public struct NovaAvatar: View {
    // Configuration
    let size: AvatarSize
    let isActive: Bool
    let hasUrgentInsights: Bool
    let isBusy: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    // Persistent Nova Manager
    @EnvironmentObject private var novaManager: NovaAIManager
    
    // Animation states
    @State private var breathe = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var rotationAngle: Double = 0
    @State private var busyPulse = false
    @State private var hasStartedPulse = false
    
    public init(
        size: AvatarSize = .large,
        isActive: Bool = false,
        hasUrgentInsights: Bool = false,
        isBusy: Bool = false,
        onTap: @escaping () -> Void = {},
        onLongPress: @escaping () -> Void = {}
    ) {
        self.size = size
        self.isActive = isActive
        self.hasUrgentInsights = hasUrgentInsights
        self.isBusy = isBusy
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    public var body: some View {
        ZStack {
            // Pulsating ring when busy
            if isBusy {
                busyPulseRing
            }
            
            // Main avatar using AIAssistantImageLoader
            avatarView
                .overlay(glowEffect)
                .overlay(urgentPulseRing)
                .shadow(
                    color: glowColor.opacity(glowOpacity),
                    radius: size.shadowRadius,
                    x: 0,
                    y: size.shadowOffset
                )
                .onAppear {
                    startBreathingAnimation()
                    if isBusy {
                        startBusyAnimation()
                    }
                }
                .onTapGesture { onTap() }
                .onLongPressGesture { 
                    // Trigger holographic mode on long press
                    novaManager.toggleHolographicMode()
                    onLongPress() 
                }
            
            // Status badge
            if isActive || hasUrgentInsights || isBusy {
                statusBadge
                    .offset(
                        x: size.dimension * 0.35,
                        y: -size.dimension * 0.35
                    )
            }
        }
        .onChange(of: isBusy) { oldValue, newValue in
            if newValue {
                startBusyAnimation()
            } else {
                stopBusyAnimation()
            }
        }
    }
    
    // MARK: - Avatar View using Persistent NovaAIManager Image
    private var avatarView: some View {
        ZStack {
            // Base AI Assistant avatar from persistent manager
            Group {
                if let novaImage = novaManager.currentNovaImage {
                    Image(uiImage: novaImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.dimension, height: size.dimension)
                        .clipShape(Circle())
                } else {
                    // Fallback while loading
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.dimension, height: size.dimension)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: size.dimension * 0.4, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            .scaleEffect(breathe ? 1.05 : 0.95) // Breathing effect on the AI image itself
            .rotationEffect(.degrees(isBusy ? rotationAngle : 0)) // Rotate when thinking
            // Add holographic effects when in holographic mode
            .opacity(novaManager.isHolographicMode ? 0.9 : 1.0)
            .overlay(
                // Holographic scanline effect
                novaManager.isHolographicMode ?
                LinearGradient(
                    colors: [
                        .clear,
                        .cyan.opacity(0.3),
                        .clear,
                        .cyan.opacity(0.2),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(Circle())
                : nil
            )
            
            // Animated border ring
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            borderColor,
                            borderColor.opacity(0.6),
                            borderColor.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(isBusy ? -rotationAngle * 0.5 : 0)) // Counter-rotate border
            
            // Thinking particles effect when busy
            if isBusy {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.8),
                                    Color.blue.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: 4)
                        .offset(y: -size.dimension * 0.4)
                        .rotationEffect(.degrees(Double(index) * 120 + rotationAngle * 2))
                        .opacity(busyPulse ? 0.0 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: busyPulse
                        )
                }
            }
        }
    }
    
    // MARK: - Busy Pulse Ring
    private var busyPulseRing: some View {
        ZStack {
            // Primary thinking ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.purple,
                            Color.blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(
                    width: size.dimension + 16,
                    height: size.dimension + 16
                )
                .scaleEffect(busyPulse ? 1.2 : 1.0)
                .opacity(busyPulse ? 0.0 : 0.8)
                .rotationEffect(.degrees(rotationAngle * 0.5))
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: busyPulse
                )
            
            // Secondary inner ring for depth
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.6),
                            Color.blue.opacity(0.4)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    lineWidth: 1.5
                )
                .frame(
                    width: size.dimension + 8,
                    height: size.dimension + 8
                )
                .scaleEffect(busyPulse ? 1.1 : 0.95)
                .opacity(busyPulse ? 0.0 : 0.6)
                .rotationEffect(.degrees(-rotationAngle * 0.3))
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(0.2),
                    value: busyPulse
                )
        }
    }
    
    // MARK: - Glow Effect
    private var glowEffect: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.4),
                            glowColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size.dimension * 0.3,
                        endRadius: size.dimension * 0.6
                    )
                )
                .frame(
                    width: size.dimension * 1.4,
                    height: size.dimension * 1.4
                )
                .blur(radius: 8)
                .opacity(breathe ? 0.9 : 0.5)
            
            // Inner ring glow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(0.6),
                            glowColor.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .blur(radius: 4)
                .opacity(breathe ? 0.9 : 0.6)
        }
    }
    
    // MARK: - Urgent Pulse Ring
    private var urgentPulseRing: some View {
        Group {
            if hasUrgentInsights {
                ZStack {
                    // Primary urgent ring
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(
                            width: size.dimension + 8,
                            height: size.dimension + 8
                        )
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: pulseScale
                        )
                    
                    // Secondary urgent dots
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 3, height: 3)
                            .offset(y: -size.dimension * 0.5 - 4)
                            .rotationEffect(.degrees(Double(index) * 90))
                            .scaleEffect(pulseScale * 0.8)
                            .opacity(2.0 - pulseScale)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.1),
                                value: pulseScale
                            )
                    }
                }
                .onAppear {
                    if !hasStartedPulse {
                        hasStartedPulse = true
                        pulseScale = 1.3
                    }
                }
                .onDisappear {
                    hasStartedPulse = false
                    pulseScale = 1.0
                }
            }
        }
    }
    
    // MARK: - Status Badge
    private var statusBadge: some View {
        ZStack {
            // Glowing background when busy
            if isBusy {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                statusBadgeColor,
                                statusBadgeColor.opacity(0.3)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.badgeSize
                        )
                    )
                    .frame(
                        width: size.badgeSize * 1.5,
                        height: size.badgeSize * 1.5
                    )
                    .blur(radius: 3)
                    .opacity(glowOpacity)
            }
            
            Circle()
                .fill(statusBadgeColor)
                .frame(
                    width: size.badgeSize,
                    height: size.badgeSize
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            // Use mini AI assistant icon instead of system icons
            if isBusy {
                // Mini spinning AI icon for busy state using persistent image
                Group {
                    if let novaImage = novaManager.currentNovaImage {
                        Image(uiImage: novaImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.badgeSize - 4, height: size.badgeSize - 4)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 1)
                            )
                    } else {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: size.badgeIconSize, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(0.8)
            } else {
                // Status indicator overlay
                statusIcon
                    .font(.system(size: size.badgeIconSize, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        if hasUrgentInsights { return .orange }
        if isBusy { return .purple }
        if isActive { return .green }
        return .purple
    }
    
    private var borderWidth: CGFloat {
        isActive || hasUrgentInsights || isBusy ? 2 : 1
    }
    
    private var glowColor: Color {
        if isBusy { return .purple }
        if hasUrgentInsights { return .orange }
        if isActive { return .green }
        return .blue
    }
    
    private var statusBadgeColor: Color {
        if isBusy { return .purple }
        if hasUrgentInsights { return .orange }
        if isActive { return .green }
        return .blue
    }
    
    private var statusIcon: Image {
        if hasUrgentInsights {
            return Image(systemName: "exclamationmark.circle.fill")
        } else if isActive {
            return Image(systemName: "waveform.circle.fill")
        } else {
            return Image(systemName: "checkmark.circle.fill")
        }
    }
    
    // MARK: - Animation Methods
    
    private func startBreathingAnimation() {
        // Natural breathing rhythm
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            breathe = true
        }
        
        // Gentle glow pulsing
        withAnimation(
            Animation.easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.9
        }
    }
    
    private func startBusyAnimation() {
        // Smooth thinking animation
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            busyPulse = true
        }
        
        // Gentle rotation for thinking state
        withAnimation(
            Animation.linear(duration: 8.0)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    private func stopBusyAnimation() {
        busyPulse = false
        rotationAngle = 0
    }
}

// MARK: - Size Enum
extension NovaAvatar {
    public enum AvatarSize {
        case small   // 40x40
        case medium  // 50x50
        case large   // 60x60
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 60
            }
        }
        
        var badgeSize: CGFloat {
            dimension * 0.25
        }
        
        var badgeIconSize: CGFloat {
            dimension * 0.12
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
        
        var shadowOffset: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
}

// MARK: - Preview
struct NovaAvatar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Size variations
                HStack(spacing: 30) {
                    VStack {
                        NovaAvatar(size: .small)
                        Text("Small")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack {
                        NovaAvatar(size: .medium)
                        Text("Medium")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack {
                        NovaAvatar(size: .large)
                        Text("Large")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // State variations
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        VStack {
                            NovaAvatar(
                                size: .large,
                                isActive: true,
                                onTap: { print("Active Nova tapped") }
                            )
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            NovaAvatar(
                                size: .large,
                                hasUrgentInsights: true,
                                onTap: { print("Urgent Nova tapped") }
                            )
                            Text("Urgent")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            NovaAvatar(
                                size: .large,
                                isBusy: true,
                                onTap: { print("Busy Nova tapped") }
                            )
                            Text("Busy")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            NovaAvatar(
                                size: .large,
                                isActive: true,
                                hasUrgentInsights: true,
                                onTap: { print("Active + Urgent Nova tapped") }
                            )
                            Text("Active + Urgent")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            NovaAvatar(
                                size: .large,
                                hasUrgentInsights: true,
                                isBusy: true,
                                onTap: { print("Busy + Urgent Nova tapped") }
                            )
                            Text("Busy + Urgent")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Text("Tap any Nova avatar to test interactions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .preferredColorScheme(.dark)
    }
}
