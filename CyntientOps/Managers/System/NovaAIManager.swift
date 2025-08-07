//
//  NovaAIManager.swift
//  CyntientOps v6.0
//
//  🧠 PERSISTENT NOVA AI MANAGER - Holographic Architecture
//  ✅ SINGLETON: Persistent image loading and state management  
//  ✅ HOLOGRAPHIC: 3D transformation and visual effects
//  ✅ PERSISTENT: Single image load, multiple transformations
//  ✅ REACTIVE: ObservableObject for SwiftUI integration
//  ✅ ENHANCED: Preserves existing functionality + holographic features
//

import SwiftUI
import Combine
import UIKit
import Speech
import AVFoundation

@MainActor
public final class NovaAIManager: ObservableObject {
    public static let shared = NovaAIManager()
    
    // MARK: - Persistent Image Architecture
    
    /// Original Nova AI image (loaded once, persistent)
    @Published public var novaOriginalImage: UIImage? = nil
    
    /// Holographic processed version of Nova image  
    @Published public var novaHolographicImage: UIImage? = nil
    
    /// Legacy property (preserved for compatibility)
    @Published public var novaImage: UIImage? 
    
    // MARK: - Enhanced State Management
    
    @Published public var novaState: NovaState = .idle
    @Published public var animationPhase: Double = 0
    @Published public var pulseAnimation = false
    @Published public var rotationAngle: Double = 0
    @Published public var hasUrgentInsights = false
    @Published public var thinkingParticles: [Particle] = []
    @Published public var currentInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var priorityTasks: [String] = []
    @Published public var buildingAlerts: [String: Int] = [:]
    
    // MARK: - Holographic Mode Properties
    
    @Published public var isHolographicMode: Bool = false
    @Published public var showingWorkspace: Bool = false  
    @Published public var workspaceMode: WorkspaceMode = .chat
    
    // MARK: - Voice Interface Properties
    
    @Published public var isListening: Bool = false
    @Published public var voiceCommand: String = ""
    @Published public var voiceWaveformData: [Float] = Array(repeating: 0.0, count: 20)
    @Published public var isWakeWordActive: Bool = false
    @Published public var speechRecognitionAvailable: Bool = false
    
    // MARK: - Real-time Properties
    
    @Published public var urgentAlerts: [CoreTypes.ClientAlert] = []
    
    // MARK: - Private Properties
    
    private var animationTimer: Timer?
    private var particleTimer: Timer?
    private var imageLoadingTask: Task<Void, Never>? = nil
    private var holographicProcessingTask: Task<Void, Never>? = nil  
    private let imageCache = NSCache<NSString, UIImage>()
    private var cancellables = Set<AnyCancellable>()
    
    // Services integration
    private weak var serviceContainer: ServiceContainer?
    
    // Voice Processing Infrastructure
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var waveformTimer: Timer?
    
    // MARK: - Computed Properties
    
    public var isThinking: Bool {
        return novaState == .thinking
    }
    
    /// Get appropriate Nova image for current mode
    public var currentNovaImage: UIImage? {
        if isHolographicMode {
            return novaHolographicImage ?? novaOriginalImage
        }
        return novaOriginalImage ?? novaImage // Fallback to legacy
    }
    
    /// Check if Nova has any active states
    public var hasActiveState: Bool {
        return novaState != .idle || hasUrgentInsights || isHolographicMode
    }
    
    /// Get Nova status text
    public var statusText: String {
        if isHolographicMode {
            return "Holographic Mode Active"
        } else if isThinking {
            return "Processing..."
        } else if hasUrgentInsights {
            return "Urgent Insights Available"
        } else if novaState == .active {
            return "Nova Active"
        }
        return "Ready"
    }
    
    // MARK: - Initialization
    
    private init() {
        setupImageCache()
        loadPersistentNovaImage()
        startPersistentAnimations()
        setupSpeechRecognition()
    }
    
    // MARK: - Image Management (Enhanced Persistent Architecture)
    
    private func setupImageCache() {
        imageCache.countLimit = 10
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    /// Load Nova AI image once and cache persistently (Enhanced)
    public func loadPersistentNovaImage() {
        // Cancel existing task
        imageLoadingTask?.cancel()
        
        imageLoadingTask = Task { @MainActor in
            // Check cache first
            if let cachedImage = imageCache.object(forKey: "nova_original") {
                self.novaOriginalImage = cachedImage
                self.novaImage = cachedImage // Legacy compatibility
                await generateHolographicVersion()
                return
            }
            
            // Load using AIAssistantImageLoader
            if let loadedImage = AIAssistantImageLoader.loadAIAssistantImage() {
                // Store in cache
                self.imageCache.setObject(loadedImage, forKey: "nova_original")
                self.novaOriginalImage = loadedImage
                self.novaImage = loadedImage // Legacy compatibility
                print("✅ Nova AI image loaded and cached persistently")
                
                // Generate holographic version
                await generateHolographicVersion()
            } else {
                print("⚠️ Failed to load Nova AI image, using fallback")
                await generateFallbackImages()
            }
        }
    }
    
    /// Generate holographic transformation of Nova image
    private func generateHolographicVersion() async {
        guard let originalImage = novaOriginalImage else { return }
        
        // Cancel existing task
        holographicProcessingTask?.cancel()
        
        holographicProcessingTask = Task { @MainActor in
            // Check cache first
            if let cachedHologram = imageCache.object(forKey: "nova_holographic") {
                self.novaHolographicImage = cachedHologram
                return
            }
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let holographicImage = await self.processHolographicTransformation(originalImage)
                    await MainActor.run {
                        self.novaHolographicImage = holographicImage
                        self.imageCache.setObject(holographicImage, forKey: "nova_holographic")
                        print("✅ Holographic Nova image generated and cached")
                    }
                }
            }
        }
    }
    
    private func processHolographicTransformation(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let holographicImage = self.applyHolographicEffects(to: image)
                continuation.resume(returning: holographicImage)
            }
        }
    }
    
    private func applyHolographicEffects(to image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            
            // Draw original image with cyan tint
            context.cgContext.setBlendMode(.normal)
            context.cgContext.draw(cgImage, in: rect)
            
            // Add holographic cyan overlay
            context.cgContext.setBlendMode(.overlay)
            context.cgContext.setFillColor(UIColor.cyan.withAlphaComponent(0.3).cgColor)
            context.cgContext.fill(rect)
            
            // Add subtle glow effect
            context.cgContext.setBlendMode(.softLight)
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            context.cgContext.fill(rect)
        }
    }
    
    private func generateFallbackImages() async {
        // Create fallback Nova images using system symbols
        let fallbackImage = await createFallbackNovaImage()
        
        await MainActor.run {
            self.novaOriginalImage = fallbackImage
            self.novaImage = fallbackImage // Legacy compatibility
            self.novaHolographicImage = fallbackImage
        }
    }
    
    private func createFallbackNovaImage() async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let size = CGSize(width: 200, height: 200)
                let renderer = UIGraphicsImageRenderer(size: size)
                
                let image = renderer.image { context in
                    // Create gradient background
                    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: [UIColor.blue.cgColor, UIColor.purple.cgColor] as CFArray,
                                            locations: [0.0, 1.0])!
                    
                    context.cgContext.drawRadialGradient(gradient,
                                                       startCenter: CGPoint(x: size.width/2, y: size.height/2),
                                                       startRadius: 0,
                                                       endCenter: CGPoint(x: size.width/2, y: size.height/2),
                                                       endRadius: size.width/2,
                                                       options: [])
                    
                    // Add AI brain symbol
                    let symbolImage = UIImage(systemName: "brain.head.profile")?.withConfiguration(
                        UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
                    )
                    
                    if let symbol = symbolImage {
                        let symbolRect = CGRect(
                            x: (size.width - 80) / 2,
                            y: (size.height - 80) / 2,
                            width: 80,
                            height: 80
                        )
                        symbol.draw(in: symbolRect, blendMode: .normal, alpha: 0.9)
                    }
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    
    // MARK: - Persistent Animations
    private func startPersistentAnimations() {
        // Main animation timer for breathing and rotation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.updateAnimations()
            }
        }
        
        // Particle animation timer for thinking state
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                self.updateThinkingParticles()
            }
        }
    }
    
    private func updateAnimations() {
        // Continuous breathing animation
        animationPhase += 0.05
        if animationPhase > 2 * Double.pi {
            animationPhase = 0
        }
        
        // State-specific animations
        switch novaState {
        case .thinking:
            rotationAngle += 2.0
            if rotationAngle > 360 {
                rotationAngle = 0
            }
        case .urgent:
            pulseAnimation.toggle()
        default:
            break
        }
    }
    
    private func updateThinkingParticles() {
        guard novaState == .thinking else {
            thinkingParticles.removeAll()
            return
        }
        
        // Add new particles
        if thinkingParticles.count < 6 {
            let particle = Particle(
                x: Double.random(in: -50...50),
                y: Double.random(in: -50...50),
                opacity: Double.random(in: 0.3...0.8),
                scale: Double.random(in: 0.5...1.0)
            )
            thinkingParticles.append(particle)
        }
        
        // Update existing particles
        for i in thinkingParticles.indices {
            thinkingParticles[i].opacity *= 0.95
            thinkingParticles[i].scale *= 0.98
        }
        
        // Remove faded particles
        thinkingParticles.removeAll { $0.opacity < 0.1 }
    }
    
    // MARK: - Service Container Integration
    
    public func setServiceContainer(_ container: ServiceContainer) {
        self.serviceContainer = container
        setupIntelligenceIntegration()
    }
    
    private func setupIntelligenceIntegration() {
        // Subscribe to intelligence updates
        guard let container = serviceContainer else { return }
        
        container.intelligence.$insights
            .assign(to: \.currentInsights, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Holographic Mode Management
    
    /// Engage holographic mode with animations
    public func engageHolographicMode() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isHolographicMode = true
            showingWorkspace = true
            workspaceMode = .holographic
        }
        
        // Trigger holographic effects
        Task {
            await activateHolographicEffects()
        }
    }
    
    /// Disengage holographic mode
    public func disengageHolographicMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            isHolographicMode = false
            showingWorkspace = false
            workspaceMode = .chat
        }
    }
    
    /// Toggle holographic mode
    public func toggleHolographicMode() {
        if isHolographicMode {
            disengageHolographicMode()
        } else {
            engageHolographicMode()
        }
    }
    
    private func activateHolographicEffects() async {
        // Activate particle systems, sound effects, haptic feedback
        await MainActor.run {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            print("🔮 Holographic mode activated")
        }
    }
    
    // MARK: - Voice Interface
    
    
    private func processVoiceCommand() {
        guard !voiceCommand.isEmpty else { return }
        
        // Process voice command through Nova API
        Task {
            do {
                let prompt = NovaPrompt(
                    text: voiceCommand,
                    priority: .medium,
                    metadata: ["source": "voice"]
                )
                
                let response = try await NovaAPIService.shared.processPrompt(prompt)
                
                await MainActor.run {
                    // Handle voice response
                    print("🗣️ Voice command processed: \(response.message)")
                }
            } catch {
                print("❌ Voice command processing failed: \(error)")
            }
            
            await MainActor.run {
                voiceCommand = ""
            }
        }
    }
    
    // MARK: - Enhanced Speech Recognition System
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognitionAvailable = speechRecognizer?.isAvailable ?? false
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.speechRecognitionAvailable = true
                case .denied, .restricted, .notDetermined:
                    self?.speechRecognitionAvailable = false
                @unknown default:
                    self?.speechRecognitionAvailable = false
                }
            }
        }
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
    }
    
    /// Enhanced voice listening with real speech recognition
    public func startVoiceListening() {
        guard speechRecognitionAvailable else {
            print("❌ Speech recognition not available")
            return
        }
        
        // Stop any existing session
        if audioEngine?.isRunning == true {
            stopVoiceListening()
        }
        
        do {
            try startSpeechRecognition()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isListening = true
            }
            
            startWaveformProcessing()
            
            // Set wake word detection
            isWakeWordActive = true
            
            print("🎤 Enhanced voice listening started with speech recognition")
        } catch {
            print("❌ Failed to start voice listening: \(error)")
        }
    }
    
    /// Enhanced voice stopping with cleanup
    public func stopVoiceListening() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isListening = false
            isWakeWordActive = false
        }
        
        // Cleanup speech recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        stopWaveformProcessing()
        
        // Process final command if any
        if !voiceCommand.isEmpty {
            processVoiceCommand()
        }
    }
    
    private func startSpeechRecognition() throws {
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "NovaAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio engine
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "NovaAI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio engine unavailable"])
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Process waveform data
            self?.processAudioBuffer(buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let command = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self?.voiceCommand = command
                    
                    // Check for wake word
                    self?.checkForWakeWord(command)
                    
                    // Process command if final
                    if result.isFinal {
                        self?.processVoiceCommand()
                    }
                }
            }
            
            if let error = error {
                print("❌ Speech recognition error: \(error)")
                DispatchQueue.main.async {
                    self?.stopVoiceListening()
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let stride = max(1, frameLength / 20) // Sample down to 20 points
        
        var waveformSamples: [Float] = []
        for i in stride(from: 0, to: frameLength, by: stride) {
            let sample = abs(channelData[i])
            waveformSamples.append(sample)
        }
        
        // Pad or truncate to exactly 20 samples
        while waveformSamples.count < 20 {
            waveformSamples.append(0.0)
        }
        if waveformSamples.count > 20 {
            waveformSamples = Array(waveformSamples.prefix(20))
        }
        
        DispatchQueue.main.async {
            self.voiceWaveformData = waveformSamples
        }
    }
    
    private func checkForWakeWord(_ command: String) {
        let lowercased = command.lowercased()
        
        if lowercased.contains("hey nova") || lowercased.contains("nova") {
            // Wake word detected - trigger holographic mode
            if !isHolographicMode {
                engageHolographicMode()
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            print("🔮 Wake word 'Hey Nova' detected!")
        }
    }
    
    private func startWaveformProcessing() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            // Real-time waveform updates are handled in processAudioBuffer
            // This timer can be used for additional waveform processing if needed
        }
    }
    
    private func stopWaveformProcessing() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        
        // Reset waveform data
        voiceWaveformData = Array(repeating: 0.0, count: 20)
    }
    
    // MARK: - Workspace Management
    
    /// Switch workspace mode
    public func setWorkspaceMode(_ mode: WorkspaceMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            workspaceMode = mode
        }
    }
    
    /// Show Nova workspace
    public func showWorkspace() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingWorkspace = true
        }
    }
    
    /// Hide Nova workspace
    public func hideWorkspace() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            showingWorkspace = false
        }
    }
    
    // MARK: - Enhanced State Management
    
    /// Update Nova state from external sources  
    public func updateState(
        isActive: Bool? = nil,
        isBusy: Bool? = nil,
        hasUrgentInsights: Bool? = nil
    ) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let urgent = hasUrgentInsights { 
                self.hasUrgentInsights = urgent
                if urgent {
                    self.novaState = .urgent
                }
            }
        }
    }
    
    // MARK: - Legacy Methods (Preserved for compatibility)
    
    public func setState(_ newState: NovaState) {
        novaState = newState
        
        // Reset animations for new state
        switch newState {
        case .idle:
            pulseAnimation = false
            rotationAngle = 0
        case .thinking:
            // Thinking particles will be generated by timer
            break
        case .urgent:
            hasUrgentInsights = true
        case .error:
            pulseAnimation = true
        default:
            break
        }
    }
    
    public func clearUrgentInsights() {
        hasUrgentInsights = false
        if novaState == .urgent {
            novaState = .idle
        }
        currentInsights.removeAll { $0.priority == .critical }
    }
    
    /// Add urgent insight
    public func addUrgentInsight(_ insight: CoreTypes.IntelligenceInsight) {
        currentInsights.append(insight)
        
        if insight.priority == .critical {
            hasUrgentInsights = true
            novaState = .urgent
        }
    }
    
    // MARK: - Intelligence Processing (Enhanced)
    
    public func processInsights(_ insights: [CoreTypes.IntelligenceInsight]) {
        setState(.thinking)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentInsights = insights
            
            // Check for urgent insights
            let urgentInsights = insights.filter { $0.priority == .critical }
            if !urgentInsights.isEmpty {
                self.setState(.urgent)
                self.hasUrgentInsights = true
            } else {
                self.setState(.active)
            }
        }
    }
    
    public func updateBuildingAlerts(_ alerts: [String: Int]) {
        buildingAlerts = alerts
        
        let criticalBuildings = alerts.filter { $0.value > 0 }.count
        if criticalBuildings > 0 {
            setState(.urgent)
            hasUrgentInsights = true
        }
    }
    
    public func updatePriorityTasks(_ tasks: [String]) {
        priorityTasks = tasks
        
        if tasks.count > 5 {
            setState(.thinking)
        } else if tasks.isEmpty {
            setState(.idle)
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        animationTimer?.invalidate()
        particleTimer?.invalidate()
        waveformTimer?.invalidate()
        imageLoadingTask?.cancel()
        holographicProcessingTask?.cancel()
        
        // Cleanup voice recognition
        recognitionTask?.cancel()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
    }
}

// MARK: - Supporting Types

/// Nova State Enum (Enhanced)
public enum NovaState {
    case idle, thinking, active, urgent, error
}

/// Workspace Mode for holographic interface
public enum WorkspaceMode {
    case chat
    case map
    case portfolio
    case holographic
    case voice
    
    public var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .map: return "Map"
        case .portfolio: return "Portfolio"
        case .holographic: return "Holographic"
        case .voice: return "Voice"
        }
    }
    
    public var icon: String {
        switch self {
        case .chat: return "message.circle"
        case .map: return "map.circle"
        case .portfolio: return "building.2.crop.circle"
        case .holographic: return "cube.transparent"
        case .voice: return "waveform.circle"
        }
    }
}

/// Particle Animation Support (Preserved)
public struct Particle: Identifiable {
    public let id = UUID()
    public var x: Double
    public var y: Double
    public var opacity: Double
    public var scale: Double
    
    public init(x: Double = 0, y: Double = 0, opacity: Double = 1, scale: Double = 1) {
        self.x = x
        self.y = y
        self.opacity = opacity
        self.scale = scale
    }
}
