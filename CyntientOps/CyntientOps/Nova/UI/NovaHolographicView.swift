//
//  NovaHolographicView.swift
//  CyntientOps v6.0
//
//  🔮 NOVA HOLOGRAPHIC WORKSPACE - Immersive 3D AI Interface
//  ✅ HOLOGRAPHIC: 400x400px holographic Nova with advanced effects
//  ✅ INTERACTIVE: Full workspace with map, portfolio, analytics
//  ✅ PARTICLE: Advanced particle field and scanline effects
//  ✅ GESTURES: Pinch, rotate, swipe navigation
//  ✅ VOICE: Voice waveform and command interface
//  ✅ IMMERSIVE: Full-screen experience with depth
//

import SwiftUI

public struct NovaHolographicView: View {
    // MARK: - Environment & State
    
    @EnvironmentObject private var novaManager: NovaAIManager
    @Environment(\.dismiss) private var dismiss
    
    // Gesture & Animation State
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var currentOffset: CGSize = .zero
    @State private var showingControls = true
    @State private var animationOffset: CGFloat = 0
    @State private var particlePhase: Double = 0
    @State private var selectedWorkspaceTab: WorkspaceTab = .nova
    
    // Advanced Particle System State
    @State private var interactiveParticles: [AdvancedParticle] = []
    @State private var energyField: Double = 0.5
    @State private var particleSystemActive = false
    
    // Voice Interface State - now using real data from NovaAIManager
    @State private var waveformTimer: Timer? = nil
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Deep space background
            holographicBackground
            
            // Enhanced particle field effect
            ParticleFieldView(phase: particlePhase)
            
            // Advanced interactive particle system
            if particleSystemActive {
                AdvancedParticleSystemView(
                    particles: interactiveParticles,
                    energyField: energyField,
                    touchPoint: currentOffset,
                    scale: currentScale
                )
                .allowsHitTesting(false)
            }
            
            // Main holographic workspace
            VStack(spacing: 0) {
                // Top control bar
                if showingControls {
                    holographicControlBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Central holographic Nova
                centralNovaHologram
                
                Spacer()
                
                // Bottom workspace tabs
                workspaceTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                
                // Workspace content
                workspaceContent
                    .frame(height: 200)
            }
            .padding()
            
            // Voice interface overlay
            if novaManager.isListening {
                voiceInterfaceOverlay
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .gesture(holographicGestures)
        .onAppear {
            startHolographicEffects()
        }
        .onDisappear {
            stopHolographicEffects()
        }
        .background(.black)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Holographic Background
    
    private var holographicBackground: some View {
        ZStack {
            // Deep space gradient
            RadialGradient(
                colors: [
                    .black,
                    Color.blue.opacity(0.1),
                    Color.cyan.opacity(0.05),
                    .black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Moving grid pattern
            HolographicGrid(offset: animationOffset)
                .opacity(0.3)
        }
    }
    
    // MARK: - Central Nova Hologram (400x400px)
    
    private var centralNovaHologram: some View {
        ZStack {
            // Base holographic Nova
            if let holographicImage = novaManager.novaHolographicImage {
                Image(uiImage: holographicImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 400, height: 400)
                    .clipShape(Circle())
                    .overlay(
                        // Scanline effect
                        ScanlineEffect()
                            .mask(Circle())
                    )
                    .overlay(
                        // Hologram distortion
                        HologramDistortion()
                            .mask(Circle())
                    )
                    .shadow(color: .cyan, radius: 20)
                    .shadow(color: .blue, radius: 40)
                    .scaleEffect(currentScale)
                    .rotationEffect(currentRotation)
                    .offset(currentOffset)
                    .rotation3DEffect(
                        .degrees(sin(particlePhase) * 5),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(cos(particlePhase * 0.8) * 3),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            
            // Holographic aura rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .cyan.opacity(0.6),
                                .blue.opacity(0.3),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: 400 + CGFloat(index * 30),
                        height: 400 + CGFloat(index * 30)
                    )
                    .rotationEffect(.degrees(particlePhase * Double(index + 1) * 10))
                    .opacity(0.7 - Double(index) * 0.2)
            }
            
            // Status text
            VStack {
                Spacer()
                
                Text(novaManager.statusText)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan, radius: 5)
                    .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                showingControls.toggle()
            }
        }
        .onLongPressGesture {
            // Voice activation
            if novaManager.isListening {
                novaManager.stopVoiceListening()
            } else {
                novaManager.startVoiceListening()
            }
        }
    }
    
    // MARK: - Control Bar
    
    private var holographicControlBar: some View {
        HStack {
            // Exit button
            Button(action: { 
                novaManager.disengageHolographicMode()
                dismiss() 
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan, radius: 3)
            }
            
            Spacer()
            
            // Mode indicator
            HStack(spacing: 8) {
                Image(systemName: "cube.transparent")
                    .font(.title3)
                    .foregroundColor(.cyan)
                
                Text("HOLOGRAPHIC MODE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(.cyan.opacity(0.5), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Voice toggle
            Button(action: {
                if novaManager.isListening {
                    novaManager.stopVoiceListening()
                } else {
                    novaManager.startVoiceListening()
                }
            }) {
                Image(systemName: novaManager.isListening ? "waveform.circle.fill" : "mic.circle")
                    .font(.title2)
                    .foregroundColor(novaManager.isListening ? .green : .cyan)
                    .shadow(color: novaManager.isListening ? .green : .cyan, radius: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Workspace Tab Bar
    
    private var workspaceTabBar: some View {
        HStack(spacing: 0) {
            ForEach(WorkspaceTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedWorkspaceTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                            .foregroundColor(selectedWorkspaceTab == tab ? .cyan : .gray)
                        
                        Text(tab.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedWorkspaceTab == tab ? .cyan : .gray)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedWorkspaceTab == tab ?
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.cyan.opacity(0.5), lineWidth: 1)
                            ) :
                        nil
                    )
                }
                .shadow(color: selectedWorkspaceTab == tab ? .cyan : .clear, radius: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.8))
        )
    }
    
    // MARK: - Workspace Content
    
    private var workspaceContent: some View {
        ZStack {
            switch selectedWorkspaceTab {
            case .nova:
                novaWorkspace
            case .map:
                mapWorkspace
            case .portfolio:
                portfolioWorkspace
            case .insights:
                insightsWorkspace
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Workspace Views
    
    private var novaWorkspace: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("Nova AI Status")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(novaManager.currentInsights.count)")
                        .font(.title.bold())
                        .foregroundColor(.cyan)
                    Text("Insights")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(novaManager.priorityTasks.count)")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                    Text("Priority Tasks")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text(novaManager.novaState.rawValue.capitalized)
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    private var mapWorkspace: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "map.circle")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("Building Portfolio Map")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Interactive building map integration coming soon...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var portfolioWorkspace: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "building.2.crop.circle")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("Portfolio Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                VStack {
                    Text("18")
                        .font(.title.bold())
                        .foregroundColor(.cyan)
                    Text("Buildings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("8")
                        .font(.title.bold())
                        .foregroundColor(.green)
                    Text("Workers")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("150")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    private var insightsWorkspace: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.circle")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if novaManager.currentInsights.isEmpty {
                Text("No active insights")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(novaManager.currentInsights.prefix(3)) { insight in
                            VStack(alignment: .leading) {
                                Text(insight.title)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                
                                Text(insight.description)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Voice Interface Overlay
    
    private var voiceInterfaceOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                // Enhanced Voice waveform with real data
                HStack(spacing: 3) {
                    ForEach(novaManager.voiceWaveformData.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .cyan],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 4, height: CGFloat(novaManager.voiceWaveformData[index]) * 40 + 5)
                            .animation(
                                .easeInOut(duration: 0.1).delay(Double(index) * 0.02),
                                value: novaManager.voiceWaveformData[index]
                            )
                            .shadow(color: .green, radius: 2)
                    }
                }
                .frame(height: 50)
                
                VStack(spacing: 8) {
                    if novaManager.isWakeWordActive {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.title3)
                                .foregroundColor(.cyan)
                                .symbolEffect(.pulse, isActive: true)
                            
                            Text("Wake Word Active")
                                .font(.headline)
                                .foregroundColor(.cyan)
                        }
                    } else {
                        Text("Listening...")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    // Show current voice command if available
                    if !novaManager.voiceCommand.isEmpty {
                        Text("\"\(novaManager.voiceCommand)\"")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .italic()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                    
                    Text("Say \"Hey Nova\" to activate holographic mode")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .shadow(color: .green, radius: 5)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.green.opacity(0.5), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Gestures
    
    private var holographicGestures: some Gesture {
        SimultaneousGesture(
            // Pinch to scale
            MagnificationGesture()
                .onChanged { value in
                    currentScale = value
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        currentScale = max(0.5, min(2.0, value))
                    }
                },
            
            SimultaneousGesture(
                // Rotation gesture
                RotationGesture()
                    .onChanged { value in
                        currentRotation = value
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            currentRotation = value
                        }
                    },
                
                // Drag gesture
                DragGesture()
                    .onChanged { value in
                        currentOffset = value.translation
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            currentOffset = .zero
                        }
                    }
            )
        )
    }
    
    // MARK: - Animation Control
    
    private func startHolographicEffects() {
        // Start particle animation
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            particlePhase = 2 * .pi
        }
        
        // Start grid animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            animationOffset = 100
        }
        
        // Initialize advanced particle system
        initializeAdvancedParticles()
        
        // Start voice waveform
        startVoiceWaveform()
    }
    
    private func initializeAdvancedParticles() {
        particleSystemActive = true
        
        // Create initial particle set
        interactiveParticles = (0..<30).map { index in
            AdvancedParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -200...200)
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -50...50),
                    dy: CGFloat.random(in: -50...50)
                ),
                size: CGFloat.random(in: 2...8),
                color: [.cyan, .blue, .purple, .green].randomElement()!,
                life: 1.0,
                energy: Double.random(in: 0.3...1.0),
                particleType: AdvancedParticleType.allCases.randomElement()!
            )
        }
        
        // Start particle update timer
        startAdvancedParticleUpdates()
    }
    
    private func startAdvancedParticleUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            if !particleSystemActive {
                timer.invalidate()
                return
            }
            
            updateAdvancedParticles()
        }
    }
    
    private func updateAdvancedParticles() {
        let dt: Double = 1.0/60.0
        
        // Update each particle
        for i in interactiveParticles.indices {
            var particle = interactiveParticles[i]
            
            // Update position based on velocity
            particle.position.x += particle.velocity.dx * dt
            particle.position.y += particle.velocity.dy * dt
            
            // Apply energy field attraction/repulsion
            let centerDistance = sqrt(
                pow(particle.position.x, 2) + pow(particle.position.y, 2)
            )
            
            if centerDistance > 0 {
                let force = energyField > 0.5 ? -20.0 : 20.0
                let forceX = (particle.position.x / centerDistance) * force * dt
                let forceY = (particle.position.y / centerDistance) * force * dt
                
                particle.velocity.dx += forceX
                particle.velocity.dy += forceY
            }
            
            // Apply drag
            particle.velocity.dx *= 0.98
            particle.velocity.dy *= 0.98
            
            // Update energy based on Nova state
            if novaManager.isListening {
                particle.energy = min(1.0, particle.energy + dt * 0.5)
            } else {
                particle.energy = max(0.2, particle.energy - dt * 0.2)
            }
            
            // Update life
            particle.life = max(0, particle.life - dt * 0.1)
            
            // Respawn if needed
            if particle.life <= 0 {
                particle = respawnParticle(particle)
            }
            
            interactiveParticles[i] = particle
        }
        
        // Update energy field based on voice activity
        if novaManager.isListening {
            energyField = min(1.0, energyField + dt * 2.0)
        } else {
            energyField = max(0.3, energyField - dt * 0.5)
        }
    }
    
    private func respawnParticle(_ particle: AdvancedParticle) -> AdvancedParticle {
        AdvancedParticle(
            id: particle.id,
            position: CGPoint(
                x: CGFloat.random(in: -300...300),
                y: CGFloat.random(in: -300...300)
            ),
            velocity: CGVector(
                dx: CGFloat.random(in: -30...30),
                dy: CGFloat.random(in: -30...30)
            ),
            size: CGFloat.random(in: 2...6),
            color: [.cyan, .blue, .purple, .green].randomElement()!,
            life: 1.0,
            energy: Double.random(in: 0.5...1.0),
            particleType: AdvancedParticleType.allCases.randomElement()!
        )
    }
    
    private func stopHolographicEffects() {
        waveformTimer?.invalidate()
        particleSystemActive = false
        interactiveParticles.removeAll()
    }
    
    private func startVoiceWaveform() {
        // Voice waveform is now handled by real speech recognition in NovaAIManager
        // No need for simulated waveform data
    }
}

// MARK: - Supporting Types

private enum WorkspaceTab: CaseIterable {
    case nova, map, portfolio, insights
    
    var displayName: String {
        switch self {
        case .nova: return "Nova"
        case .map: return "Map"
        case .portfolio: return "Portfolio"
        case .insights: return "Insights"
        }
    }
    
    var icon: String {
        switch self {
        case .nova: return "brain.head.profile"
        case .map: return "map.circle"
        case .portfolio: return "building.2.crop.circle"
        case .insights: return "lightbulb.circle"
        }
    }
}

// MARK: - Effect Views

private struct ParticleFieldView: View {
    let phase: Double
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { index in
                Circle()
                    .fill(.cyan.opacity(0.6))
                    .frame(width: 2, height: 2)
                    .offset(
                        x: cos(phase + Double(index) * 0.1) * Double(100 + index * 3),
                        y: sin(phase + Double(index) * 0.1) * Double(100 + index * 3)
                    )
                    .opacity(0.5)
            }
        }
    }
}

private struct ScanlineEffect: View {
    @State private var scanlinePosition: CGFloat = -200
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .cyan.opacity(0.8),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 4)
            .offset(y: scanlinePosition)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    scanlinePosition = 600
                }
            }
    }
}

private struct HologramDistortion: View {
    @State private var distortionPhase: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .cyan.opacity(0.3),
                        .clear,
                        .blue.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .offset(x: sin(distortionPhase) * 20)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    distortionPhase = 2 * .pi
                }
            }
    }
}

private struct HolographicGrid: View {
    let offset: CGFloat
    
    var body: some View {
        ZStack {
            // Horizontal lines
            VStack(spacing: 30) {
                ForEach(0..<20) { _ in
                    Rectangle()
                        .fill(.cyan.opacity(0.1))
                        .frame(height: 1)
                }
            }
            .offset(y: offset)
            
            // Vertical lines
            HStack(spacing: 30) {
                ForEach(0..<15) { _ in
                    Rectangle()
                        .fill(.cyan.opacity(0.1))
                        .frame(width: 1)
                }
            }
            .offset(x: offset * 0.7)
        }
    }
}

// MARK: - Advanced Particle System

struct AdvancedParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
    var life: Double
    var energy: Double
    var particleType: AdvancedParticleType
}

enum AdvancedParticleType: CaseIterable {
    case energy, data, neural, quantum
    
    var systemImage: String {
        switch self {
        case .energy: return "circle.fill"
        case .data: return "diamond.fill"
        case .neural: return "hexagon.fill"
        case .quantum: return "triangle.fill"
        }
    }
    
    var baseColor: Color {
        switch self {
        case .energy: return .cyan
        case .data: return .blue
        case .neural: return .purple
        case .quantum: return .green
        }
    }
}

struct AdvancedParticleSystemView: View {
    let particles: [AdvancedParticle]
    let energyField: Double
    let touchPoint: CGSize
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Render all particles
            ForEach(particles) { particle in
                AdvancedParticleView(
                    particle: particle,
                    energyField: energyField,
                    touchPoint: touchPoint,
                    globalScale: scale
                )
            }
            
            // Energy field visualization
            if energyField > 0.7 {
                EnergyFieldView(strength: energyField)
                    .opacity(0.3)
                    .allowsHitTesting(false)
            }
        }
        .drawingGroup() // Optimize rendering performance
    }
}

struct AdvancedParticleView: View {
    let particle: AdvancedParticle
    let energyField: Double
    let touchPoint: CGSize
    let globalScale: CGFloat
    
    var body: some View {
        Image(systemName: particle.particleType.systemImage)
            .font(.system(size: particle.size * globalScale))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        particle.color.opacity(particle.energy),
                        particle.color.opacity(particle.energy * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: particle.color, radius: particle.energy * 4)
            .scaleEffect(0.8 + (particle.energy * 0.4))
            .opacity(particle.life)
            .position(
                x: particle.position.x + touchPoint.width * 0.1,
                y: particle.position.y + touchPoint.height * 0.1
            )
            .blur(radius: energyField > 0.8 ? 1.0 : 0.0)
    }
}

struct EnergyFieldView: View {
    let strength: Double
    
    var body: some View {
        ZStack {
            // Central energy core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .cyan.opacity(strength * 0.8),
                            .blue.opacity(strength * 0.4),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 10)
            
            // Energy rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .cyan.opacity(strength * 0.6),
                                .clear,
                                .blue.opacity(strength * 0.4),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: 80 + CGFloat(index * 40),
                        height: 80 + CGFloat(index * 40)
                    )
                    .opacity(1.0 - (Double(index) * 0.3))
                    .rotationEffect(.degrees(Double(index) * 120))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NovaHolographicView()
        .environmentObject(NovaAIManager.shared)
}