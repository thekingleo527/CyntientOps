//
//  GlassLoadingView.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Integrated with CyntientOpsDesign color system
//  ✅ IMPROVED: Glass effects and animations for dark theme
//  ✅ ADDED: Multiple loading styles with consistent theming
//

import SwiftUI

// MARK: - Glass Loading View
struct GlassLoadingView: View {
    let message: String
    let showProgress: Bool
    let intensity: GlassIntensity
    
    @State private var isAnimating = false
    @State private var progress: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    // MARK: - Animation Constants
    private let pulseRange: ClosedRange<CGFloat> = 0.95...1.05
    private let pulseDuration: Double = 1.5
    private let rotationDuration: Double = 2.0
    private let progressDuration: Double = 3.0
    
    init(
        message: String = "Loading...",
        showProgress: Bool = false,
        intensity: GlassIntensity = .regular
    ) {
        self.message = message
        self.showProgress = showProgress
        self.intensity = intensity
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Loading Animation
            loadingAnimation
            
            // Message Text
            messageText
            
            // Progress Bar (if enabled)
            if showProgress {
                progressBar
            }
        }
        .padding(32)
        .cyntientOpsDarkCardBackground(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    // MARK: - Animation Components
    private var loadingAnimation: some View {
        ZStack {
            // Outer Ring
            Circle()
                .stroke(CyntientOpsDesign.DashboardColors.glassOverlay, lineWidth: 3)
                .frame(width: 60, height: 60)
            
            // Animated Ring
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.info,
                            CyntientOpsDesign.DashboardColors.info.opacity(0.5),
                            CyntientOpsDesign.DashboardColors.glassOverlay,
                            CyntientOpsDesign.DashboardColors.info
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    .linear(duration: rotationDuration).repeatForever(autoreverses: false),
                    value: rotationAngle
                )
            
            // Center Pulse
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.info.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true),
                    value: pulseScale
                )
        }
    }
    
    private var messageText: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            .opacity(isAnimating ? 1.0 : 0.7)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            // Progress Track
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                CyntientOpsDesign.DashboardColors.info,
                                CyntientOpsDesign.DashboardColors.info.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            
            // Progress Text
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
    }
    
    // MARK: - Computed Properties
    private var progressWidth: CGFloat {
        return 200 * CGFloat(progress)
    }
    
    // MARK: - Animation Control
    private func startAnimations() {
        isAnimating = true
        rotationAngle = 360
        pulseScale = pulseRange.upperBound
        
        if showProgress {
            animateProgress()
        }
    }
    
    private func stopAnimations() {
        isAnimating = false
        rotationAngle = 0
        pulseScale = 1.0
        progress = 0.0
    }
    
    private func animateProgress() {
        withAnimation(.easeInOut(duration: progressDuration).repeatForever(autoreverses: true)) {
            progress = 1.0
        }
    }
}

// MARK: - Loading Dots Animation
struct LoadingDotsView: View {
    @State private var animating = false
    
    private let dotCount = 3
    private let animationDuration: Double = 0.6
    private let staggerDelay: Double = 0.2
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.info)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: animationDuration)
                            .repeatForever()
                            .delay(Double(index) * staggerDelay),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Skeleton Loading View
struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    
    let rows: Int
    let intensity: GlassIntensity
    
    init(rows: Int = 3, intensity: GlassIntensity = .thin) {
        self.rows = rows
        self.intensity = intensity
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rows, id: \.self) { index in
                skeletonRow(width: randomWidth())
                    .opacity(isAnimating ? 0.3 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func skeletonRow(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [
                        CyntientOpsDesign.DashboardColors.glassOverlay,
                        CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.5),
                        CyntientOpsDesign.DashboardColors.glassOverlay
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 16)
    }
    
    private func randomWidth() -> CGFloat {
        let widths: [CGFloat] = [200, 150, 180, 120, 220]
        return widths.randomElement() ?? 180
    }
}

// MARK: - Spinner Loading View
struct SpinnerLoadingView: View {
    @State private var isSpinning = false
    
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 40, color: Color? = nil) {
        self.size = size
        self.color = color ?? CyntientOpsDesign.DashboardColors.info
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(
                color.opacity(0.8),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(
                .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isSpinning
            )
            .onAppear {
                isSpinning = true
            }
    }
}

// MARK: - Minimal Loading Indicator
struct MinimalLoadingIndicator: View {
    @State private var opacity: Double = 0.5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.info)
                    .frame(width: 4, height: 4)
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: opacity
                    )
            }
        }
        .onAppear {
            opacity = 1.0
        }
    }
}

// MARK: - View Extensions
extension View {
    func glassLoading(
        isLoading: Bool,
        message: String = "Loading...",
        showProgress: Bool = false,
        intensity: GlassIntensity = .regular
    ) -> some View {
        ZStack {
            self
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                CyntientOpsDesign.DashboardColors.baseBackground.opacity(0.5)
                    .ignoresSafeArea()
                
                GlassLoadingView(
                    message: message,
                    showProgress: showProgress,
                    intensity: intensity
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
    
    func minimalLoading(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    MinimalLoadingIndicator()
                        .padding(8)
                        .background(
                            Capsule()
                                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.9))
                                .overlay(
                                    Capsule()
                                        .stroke(CyntientOpsDesign.DashboardColors.glassOverlay, lineWidth: 1)
                                )
                        )
                }
            },
            alignment: .bottomTrailing
        )
    }
}

// MARK: - Preview Support
#if DEBUG
struct GlassLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Dark Elegance background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Standard loading view
                GlassLoadingView()
                
                // Loading with progress
                GlassLoadingView(
                    message: "Syncing data...",
                    showProgress: true,
                    intensity: .thick
                )
                
                // Different loading styles
                HStack(spacing: 30) {
                    VStack(spacing: 20) {
                        Text("Dots")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        LoadingDotsView()
                    }
                    
                    VStack(spacing: 20) {
                        Text("Spinner")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        SpinnerLoadingView()
                    }
                    
                    VStack(spacing: 20) {
                        Text("Minimal")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        MinimalLoadingIndicator()
                    }
                }
                
                // Skeleton loading
                VStack(spacing: 20) {
                    Text("Skeleton Loading")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    SkeletonLoadingView(rows: 4)
                        .padding()
                        .cyntientOpsDarkCardBackground(cornerRadius: 12)
                }
                .frame(width: 300)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
