//
//  GlassButton.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 6/8/25.
//  ✅ FIXED: Corrected Animation to Animation
//  ✅ FIXED: Corrected Binding assignment in GlassToggleButton
//  ✅ ALIGNED: With GlassTypes.swift definitions
//

import SwiftUI

// MARK: - Glass Button (using existing types from GlassTypes.swift)
struct GlassButton: View {
    // Content
    let text: String
    let action: () -> Void
    
    // Style properties
    var style: GlassButtonStyle
    var size: GlassButtonSize
    var isFullWidth: Bool
    var isDisabled: Bool
    var isLoading: Bool
    var icon: String?
    
    // Animation state
    @State private var isPressed = false
    @State private var loadingRotation = 0.0
    
    init(
        _ text: String,
        style: GlassButtonStyle = .primary,
        size: GlassButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
            }
        }) {
            HStack(spacing: 8) {
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(style.textColor)
                        .rotationEffect(.degrees(loadingRotation))
                        .onAppear {
                            // ✅ FIXED: Animation instead of Animation
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                                loadingRotation = 360.0
                            }
                        }
                }
                
                // Icon
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(size.font)
                        .foregroundColor(style.textColor.opacity(isDisabled ? 0.5 : 1.0))
                }
                
                // Text
                Text(isLoading ? "Loading..." : text)
                    .font(size.font)
                    .foregroundColor(style.textColor.opacity(isDisabled ? 0.5 : 1.0))
                    .lineLimit(1)
                
                if isFullWidth {
                    Spacer()
                }
            }
            .padding(size.padding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(buttonBackground)
            .cornerRadius(size.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(borderGradient, lineWidth: 1)
            )
            .shadow(
                color: style.baseColor.opacity(isPressed ? 0.4 : 0.2),
                radius: isPressed ? 8 : 4,
                x: 0,
                y: isPressed ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            // ✅ FIXED: Animation instead of Animation
            withAnimation(Animation.easeInOut(duration: 0.1)) {
                isPressed = pressing && !isDisabled && !isLoading
            }
        }, perform: {})
    }
    
    // MARK: - Background
    private var buttonBackground: some View {
        ZStack {
            // Base material
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(style.intensity.material)
            
            // Color overlay
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            style.baseColor.opacity(0.8),
                            style.baseColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Highlight overlay
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPressed ? 0.1 : 0.2),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    // MARK: - Border Gradient
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                style.baseColor.opacity(0.6),
                style.baseColor.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Icon Button
struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    
    var style: GlassButtonStyle
    var size: GlassButtonSize
    var isDisabled: Bool
    
    @State private var isPressed = false
    
    init(
        icon: String,
        style: GlassButtonStyle = .secondary,
        size: GlassButtonSize = .medium,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                action()
            }
        }) {
            Image(systemName: icon)
                .font(size.font)
                .foregroundColor(style.textColor.opacity(isDisabled ? 0.5 : 1.0))
                .frame(width: iconSize, height: iconSize)
                .background(
                    Circle()
                        .fill(style.intensity.material)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            style.baseColor.opacity(0.6),
                                            style.baseColor.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            style.baseColor.opacity(0.6),
                                            style.baseColor.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: style.baseColor.opacity(isPressed ? 0.4 : 0.2),
                    radius: isPressed ? 6 : 3,
                    x: 0,
                    y: isPressed ? 3 : 1
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            // ✅ FIXED: Animation instead of Animation
            withAnimation(Animation.easeInOut(duration: 0.1)) {
                isPressed = pressing && !isDisabled
            }
        }, perform: {})
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        }
    }
}

// MARK: - Glass Toggle Button
struct GlassToggleButton: View {
    let text: String
    @Binding var isOn: Bool  // ✅ FIXED: Changed from @State to @Binding
    let action: (() -> Void)?
    
    var style: GlassButtonStyle
    var size: GlassButtonSize
    
    init(
        _ text: String,
        isOn: Binding<Bool>,
        style: GlassButtonStyle = .secondary,
        size: GlassButtonSize = .medium,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self._isOn = isOn  // ✅ FIXED: Proper binding assignment
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        GlassButton(
            text,
            style: isOn ? .primary : style,
            size: size,
            icon: isOn ? "checkmark" : nil
        ) {
            // ✅ FIXED: Animation instead of Animation
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
            action?()
        }
    }
}

// MARK: - Preview
struct GlassButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Primary buttons
                    VStack(spacing: 16) {
                        Text("Primary Buttons")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GlassButton("Small Button", style: .primary, size: .small) {
                            print("Small button tapped")
                        }
                        
                        GlassButton("Medium Button", style: .primary, size: .medium) {
                            print("Medium button tapped")
                        }
                        
                        GlassButton("Large Button", style: .primary, size: .large, isFullWidth: true) {
                            print("Large button tapped")
                        }
                        
                        GlassButton("With Icon", style: .primary, size: .medium, icon: "star.fill") {
                            print("Icon button tapped")
                        }
                        
                        GlassButton("Loading", style: .primary, size: .medium, isLoading: true) {
                            print("Loading button tapped")
                        }
                        
                        GlassButton("Disabled", style: .primary, size: .medium, isDisabled: true) {
                            print("Disabled button tapped")
                        }
                    }
                    
                    // Secondary buttons
                    VStack(spacing: 16) {
                        Text("Secondary Buttons")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GlassButton("Secondary", style: .secondary, size: .medium) {
                            print("Secondary button tapped")
                        }
                        
                        GlassButton("Tertiary", style: .tertiary, size: .medium) {
                            print("Tertiary button tapped")
                        }
                        
                        GlassButton("Destructive", style: .destructive, size: .medium) {
                            print("Destructive button tapped")
                        }
                    }
                    
                    // Icon buttons
                    HStack(spacing: 16) {
                        GlassIconButton(icon: "heart.fill", style: .primary) {
                            print("Heart tapped")
                        }
                        
                        GlassIconButton(icon: "star.fill", style: .secondary) {
                            print("Star tapped")
                        }
                        
                        GlassIconButton(icon: "trash.fill", style: .destructive) {
                            print("Trash tapped")
                        }
                        
                        GlassIconButton(icon: "plus", style: .tertiary) {
                            print("Plus tapped")
                        }
                    }
                    
                    // Toggle buttons
                    VStack(spacing: 16) {
                        Text("Toggle Buttons")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // ✅ FIXED: Proper binding syntax
                        GlassToggleButton("Toggle Option", isOn: .constant(false)) {
                            print("Toggle 1 changed")
                        }
                        GlassToggleButton("Active Toggle", isOn: .constant(true)) {
                            print("Toggle 2 changed")
                        }
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
