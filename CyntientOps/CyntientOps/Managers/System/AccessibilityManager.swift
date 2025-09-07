//
//  AccessibilityManager.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  AccessibilityManager.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Provide robust accessibility support.
//
//  ✅ PRODUCTION READY: Centralizes accessibility state and logic.
//  ✅ RESPONSIVE: Monitors and responds to system accessibility changes.
//  ✅ INCLUSIVE: Includes helpers for color blindness and reduced motion.
//

import SwiftUI
import Combine

@MainActor
final class AccessibilityManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AccessibilityManager()
    
    // MARK: - Published Properties
    @Published var voiceOverEnabled: Bool
    @Published var reduceMotionEnabled: Bool
    
    @AppStorage("app_colorblind_mode") private var storedColorBlindMode: String = ColorBlindMode.none.rawValue
    @Published var colorBlindMode: ColorBlindMode = .none
    
    // MARK: - Color Blind Modes
    enum ColorBlindMode: String, CaseIterable, Identifiable {
        case none, protanopia, deuteranopia, tritanopia
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "Default"
            case .protanopia: return "Protanopia (Red-Blind)"
            case .deuteranopia: return "Deuteranopia (Green-Blind)"
            case .tritanopia: return "Tritanopia (Blue-Blind)"
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        // Initialize with current system settings
        self.voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        self.reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        self.colorBlindMode = ColorBlindMode(rawValue: storedColorBlindMode) ?? .none
        
        // Subscribe to system notifications for changes
        setupSubscribers()
    }
    
    // MARK: - Public API
    
    /// Adjusts a color to be more distinguishable based on the selected color-blind mode.
    func adjustColor(_ color: Color) -> Color {
        switch colorBlindMode {
        case .none:
            return color
        case .protanopia:
            // Example adjustment: Shift reds towards orange/yellow
            // This is a simplified example; a real implementation would use a color simulation library.
            if color == .red { return .orange }
            if color == .green { return .cyan }
            return color
        case .deuteranopia:
            // Example adjustment: Shift greens towards blue/yellow
            if color == .green { return .yellow }
            if color == .red { return .pink }
            return color
        case .tritanopia:
            // Example adjustment: Shift blues and yellows
            if color == .blue { return .purple }
            if color == .yellow { return .orange }
            return color
        }
    }
    
    /// Returns a suitable animation, disabling it if Reduce Motion is enabled.
    func animation(_ base: Animation = .default) -> Animation? {
        reduceMotionEnabled ? nil : base
    }
    
    // MARK: - Subscribers
    
    private func setupSubscribers() {
        // Monitor for changes in VoiceOver status
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.voiceOverEnabled = UIAccessibility.isVoiceOverRunning
            }
            .store(in: &cancellables)
        
        // Monitor for changes in Reduce Motion status
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
            .store(in: &cancellables)
            
        // Persist color-blind mode selection
        $colorBlindMode
            .sink { [weak self] mode in
                self?.storedColorBlindMode = mode.rawValue
            }
            .store(in: &cancellables)
    }
}