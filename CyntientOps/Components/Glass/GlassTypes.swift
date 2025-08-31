//
//  GlassTypes.swift
//  CyntientOps v6.0
//
//  ✅ SINGLE SOURCE OF TRUTH: Only GlassIntensity definition in entire codebase
//  ✅ FIXED: All Animation syntax errors corrected
//  ✅ UNIFIED: Central location for all Glass component types
//  ✅ ENHANCED: Added missing properties for GlassButton compatibility
//

import SwiftUI

// MARK: - Glass Intensity (SINGLE SOURCE OF TRUTH)
public enum GlassIntensity: CaseIterable {
    case ultraThin
    case thin
    case regular
    case thick
    
    public var material: Material {
        switch self {
        case .ultraThin:
            return .ultraThinMaterial
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        }
    }
    
    public var opacity: Double {
        switch self {
        case .ultraThin:
            return 0.05
        case .thin:
            return 0.1
        case .regular:
            return 0.15
        case .thick:
            return 0.25
        }
    }
    
    public var blurRadius: CGFloat {
        switch self {
        case .ultraThin:
            return 10
        case .thin:
            return 15
        case .regular:
            return 20
        case .thick:
            return 30
        }
    }
    
    public var strokeOpacity: Double {
        switch self {
        case .ultraThin: return 0.05
        case .thin: return 0.1
        case .regular: return 0.15
        case .thick: return 0.25
        }
    }
    
    public var shadowRadius: CGFloat {
        switch self {
        case .ultraThin: return 6
        case .thin: return 12
        case .regular: return 20
        case .thick: return 30
        }
    }
    
    public var brightness: Double {
        switch self {
        case .ultraThin: return 0.3
        case .thin: return 0.2
        case .regular: return 0.1
        case .thick: return 0.05
        }
    }
}

// MARK: - Glass Button Style
public enum GlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case custom(baseColor: Color, textColor: Color)
    
    public var baseColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .gray
        case .tertiary: return .clear
        case .destructive: return .red
        case .custom(let baseColor, _): return baseColor
        }
    }
    
    public var textColor: Color {
        switch self {
        case .primary, .secondary, .destructive: return .white
        case .tertiary: return .white.opacity(0.8)
        case .custom(_, let textColor): return textColor
        }
    }
    
    public var intensity: GlassIntensity {
        switch self {
        case .primary: return .regular
        case .secondary: return .thin
        case .tertiary: return .ultraThin
        case .destructive: return .regular
        case .custom: return .regular
        }
    }
}

// MARK: - Glass Button Size
public enum GlassButtonSize {
    case small
    case medium
    case large
    
    public var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium: return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        case .large: return EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        }
    }
    
    public var font: Font {
        switch self {
        case .small: return .subheadline
        case .medium: return .body
        case .large: return .headline
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
}

// MARK: - Glass Modal Size
public enum GlassModalSize {
    case small
    case medium
    case large
    case fullScreen
    
    public var width: CGFloat? {
        switch self {
        case .small: return 300
        case .medium: return 400
        case .large: return 600
        case .fullScreen: return nil
        }
    }
    
    public var height: CGFloat? {
        switch self {
        case .small: return 200
        case .medium: return 400
        case .large: return 600
        case .fullScreen: return nil
        }
    }
}

// MARK: - Other Glass Types
public enum GlassModalStyle {
    case centered
    case bottom
    case fullScreen
}

public enum GlassNavigationStyle {
    case inline
    case large
    case transparent
    
    public var intensity: GlassIntensity {
        switch self {
        case .inline: return .regular
        case .large: return .thick
        case .transparent: return .ultraThin
        }
    }
}

public enum GlassLoadingStyle {
    case spinner
    case progress
    case pulse
    
    public var color: Color {
        return .white
    }
}

public enum GlassTransition {
    case fade
    case scale
    case slide(Edge)
    case blur
    
    public var animation: Animation {
        switch self {
        case .fade, .blur: return .easeInOut(duration: 0.3)
        case .scale: return .spring(response: 0.4, dampingFraction: 0.8)
        case .slide: return .spring(response: 0.5, dampingFraction: 0.85)
        }
    }
}

public struct GlassTabItem {
    public let title: String
    public let icon: String
    public let selectedIcon: String
    
    public init(title: String, icon: String, selectedIcon: String) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
    }
}

// MARK: - Glass Style Configuration (Added for better customization)
public struct GlassStyleConfiguration {
    public let baseColor: Color
    public let intensity: GlassIntensity
    public let cornerRadius: CGFloat
    public let borderWidth: CGFloat
    public let shadowRadius: CGFloat
    
    public init(
        baseColor: Color = .white,
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        shadowRadius: CGFloat = 10
    ) {
        self.baseColor = baseColor
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
    }
    
    // Preset configurations
    public static let card = GlassStyleConfiguration(
        intensity: .regular,
        cornerRadius: 16,
        shadowRadius: 10
    )
    
    public static let modal = GlassStyleConfiguration(
        intensity: .thick,
        cornerRadius: 24,
        shadowRadius: 20
    )
    
    public static let navigationBar = GlassStyleConfiguration(
        intensity: .thick,
        cornerRadius: 0,
        borderWidth: 0,
        shadowRadius: 5
    )
    
    public static let statusBadge = GlassStyleConfiguration(
        intensity: .thin,
        cornerRadius: 8,
        shadowRadius: 4
    )
}

// MARK: - Glass Theme (Added for theming support)
public struct GlassTheme {
    public let primary: Color
    public let secondary: Color
    public let background: LinearGradient
    public let cardIntensity: GlassIntensity
    public let modalIntensity: GlassIntensity
    
    public static let dark = GlassTheme(
        primary: .blue,
        secondary: .purple,
        background: LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        cardIntensity: .regular,
        modalIntensity: .thick
    )
    
    public static let light = GlassTheme(
        primary: .blue,
        secondary: .indigo,
        background: LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.95, blue: 0.97),
                Color(red: 0.9, green: 0.9, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        cardIntensity: .thin,
        modalIntensity: .regular
    )
}

// MARK: - Type Aliases for compatibility
public typealias GlassCardStyle = GlassIntensity
public typealias GlassEffectStyle = GlassIntensity

// MARK: - ButtonStyle Disambiguation
// To avoid conflicts with SwiftUI's ButtonStyle protocol,
// we namespace our button style differently
public typealias GlassButtonVariant = GlassButtonStyle
