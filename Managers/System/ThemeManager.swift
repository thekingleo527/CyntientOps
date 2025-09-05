
//  ThemeManager.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create a centralized theme manager for dynamic UI styling.
//
//  ✅ PRODUCTION READY: Manages dark/light mode, accent colors, and accessibility settings.
//  ✅ PERSISTENT: Saves and loads user preferences from UserDefaults.
//  ✅ REACTIVE: Changes are published and can be observed by any SwiftUI view.
//

import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Published Properties
    @AppStorage("app_theme") private var storedTheme: String = Theme.system.rawValue
    @AppStorage("app_accent_color") private var storedAccentColor: String = "blue"
    @AppStorage("app_high_contrast") private var storedHighContrast: Bool = false
    
    @Published var currentTheme: Theme = .system
    @Published var accentColor: Color = .blue
    @Published var useHighContrast: Bool = false
    
    // MARK: - Theme Definitions
    enum Theme: String, CaseIterable, Identifiable {
        case light, dark, system
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        // Load preferences on init
        loadPreferences()
        
        // Set up subscribers to persist changes automatically
        setupSubscribers()
    }
    
    // MARK: - Public API
    
    /// Applies a new theme to the application.
    func applyTheme(_ theme: Theme) {
        currentTheme = theme
    }
    
    /// Applies a new accent color.
    func applyAccentColor(_ color: Color) {
        accentColor = color
    }
    
    /// Toggles the high contrast mode.
    func toggleHighContrast(isOn: Bool) {
        useHighContrast = isOn
    }
    
    // MARK: - Color Palette
    // Centralizes color definitions based on the current theme.
    
    var primaryBackgroundColor: Color {
        useHighContrast ? .black : Color("PrimaryBackground") // Assuming color sets in Assets
    }
    
    var secondaryBackgroundColor: Color {
        useHighContrast ? Color(white: 0.1) : Color("SecondaryBackground")
    }
    
    var cardColor: Color {
        useHighContrast ? Color(white: 0.15) : Color("CardBackground")
    }
    
    var primaryTextColor: Color {
        useHighContrast ? .white : Color("PrimaryText")
    }
    
    var secondaryTextColor: Color {
        useHighContrast ? Color(white: 0.8) : Color("SecondaryText")
    }
    
    // MARK: - Persistence
    
    private func setupSubscribers() {
        $currentTheme
            .sink { [weak self] theme in
                self?.storedTheme = theme.rawValue
            }
            .store(in: &cancellables)
            
        $accentColor
            .sink { [weak self] color in
                self?.storedAccentColor = color.description // A simple way to store color name
            }
            .store(in: &cancellables)
        
        $useHighContrast
            .sink { [weak self] isEnabled in
                self?.storedHighContrast = isEnabled
            }
            .store(in: &cancellables)
    }
    
    private func loadPreferences() {
        self.currentTheme = Theme(rawValue: storedTheme) ?? .system
        self.accentColor = colorFromString(storedAccentColor)
        self.useHighContrast = storedHighContrast
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        // This can be expanded to a more robust system
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }
}
