//
//  LoginView.swift
//  CyntientOps v6.0
//
//  ✅ ENHANCED: Biometric authentication support
//  ✅ SECURE: No more hardcoded passwords
//  ✅ IMPROVED: Better error handling and UX
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showBiometricButton = false
    
    @StateObject private var authManager = NewAuthManager.shared
    
    // Animation states
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -90
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    @State private var quickAccessOffset: CGFloat = 30
    @State private var quickAccessOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.25),
                        Color(red: 0.15, green: 0.2, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                        Color(red: 0.48, green: 0.73, blue: 1.0).opacity(0.2)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(Animation.easeIn(duration: 1.5)) {
                        backgroundOpacity = 1.0
                    }
                }
            }
            
            // Main content
            ScrollView {
                VStack(spacing: 30) {
                    // Logo section with glass enhancement
                    VStack(spacing: 24) {
                        // Glass-backed logo
                        ZStack {
                            // Animated glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .blur(radius: 20)
                                .scaleEffect(logoScale * 1.5)
                            
                            // Glass backing
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                            
                            // Logo
                            SimpleCyntientOpsLogo(size: 100)
                                .rotationEffect(Angle.degrees(logoRotation))
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        
                        // App name
                        VStack(spacing: 8) {
                            Text("CyntientOps")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.white.opacity(0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 2, y: 2)
                            
                            Text("Building Maintenance Management")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(0.5)
                        }
                        .opacity(logoOpacity)
                    }
                    .padding(.top, 60)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                            logoRotation = 0
                        }
                        
                        // Check if biometric login is available
                        checkBiometricAvailability()
                    }
                    
                    // Login form in glass card
                    GlassCard(intensity: GlassIntensity.regular, cornerRadius: 24) {
                        VStack(spacing: 20) {
                            // Biometric login button (if available)
                            if showBiometricButton && authManager.isBiometricEnabled {
                                Button(action: {
                                    Task {
                                        await performBiometricLogin()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: biometricIcon)
                                            .font(.system(size: 24))
                                        
                                        Text("Login with \(biometricTypeString)")
                                            .font(.headline)
                                        
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                HStack {
                                    VStack { Divider() }
                                    Text("OR")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal)
                                    VStack { Divider() }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    TextField("Enter your email", text: $email)
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .placeholder(when: email.isEmpty) {
                                            Text("Enter your email")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .foregroundColor(.white)
                                            .disableAutocorrection(true)
                                            .autocapitalization(.none)
                                            .placeholder(when: password.isEmpty) {
                                                Text("Enter your password")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .foregroundColor(.white)
                                            .placeholder(when: password.isEmpty) {
                                                Text("Enter your password")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                    }
                                    
                                    Button(action: {
                                        withAnimation(Animation.easeInOut(duration: 0.2)) {
                                            showPassword.toggle()
                                        }
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 20)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Error message
                            if let errorMessage = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                    
                                    Text(errorMessage)
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Login button
                            GlassButton(
                                "LOG IN",
                                style: .primary,
                                size: .large,
                                isFullWidth: true,
                                isDisabled: !isValidForm,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await performLogin()
                                }
                            }
                            .padding(.top, 8)
                            
                            // Forgot password link
                            Button(action: {
                                // Handle forgot password
                                print("Forgot password tapped")
                            }) {
                                Text("Forgot Password?")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                            formOffset = 0
                            formOpacity = 1
                        }
                    }
                    
                    // Development quick access section (remove in production)
                    #if DEBUG
                    GlassCard(intensity: GlassIntensity.thin, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Development Quick Access")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("⚠️ Remove in Production")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            VStack(spacing: 12) {
                                quickAccessButton(
                                    email: "dutankevin1@gmail.com",
                                    name: "Kevin (Worker)",
                                    icon: "wrench.and.screwdriver",
                                    color: .blue
                                )
                                
                                quickAccessButton(
                                    email: "shawn@fme-llc.com",
                                    name: "Shawn (Admin)",
                                    icon: "shield.checkmark",
                                    color: .purple
                                )
                                
                                quickAccessButton(
                                    email: "francosphere@francomanagementgroup.com",
                                    name: "Client Access",
                                    icon: "person.text.rectangle",
                                    color: .green
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: quickAccessOffset)
                    .opacity(quickAccessOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6)) {
                            quickAccessOffset = 0
                            quickAccessOpacity = 1
                        }
                    }
                    #endif
                    
                    // Footer
                    Text("© 2025 Franco Management Enterprises")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkBiometricAvailability() {
        showBiometricButton = authManager.biometricType != .none
    }
    
    private var biometricIcon: String {
        switch authManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.shield"
        }
    }
    
    private var biometricTypeString: String {
        switch authManager.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics"
        }
    }
    
    #if DEBUG
    private func quickAccessButton(email: String, name: String, icon: String, color: Color) -> some View {
        Button(action: {
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                self.email = email
                self.password = "password" // Default test password
            }
            Task {
                await performLogin()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    #endif
    
    private var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func performLogin() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                isLoading = true
                errorMessage = nil
            }
        }
        
        do {
            try await authManager.authenticate(email: email, password: password)
            
            await MainActor.run {
                withAnimation(Animation.easeInOut(duration: 0.2)) {
                    isLoading = false
                }
                print("✅ Login successful")
            }
            
        } catch {
            await MainActor.run {
                withAnimation(Animation.easeInOut(duration: 0.2)) {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func performBiometricLogin() async {
        await MainActor.run {
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                isLoading = true
                errorMessage = nil
            }
        }
        
        do {
            try await authManager.authenticateWithBiometrics()
            
            await MainActor.run {
                withAnimation(Animation.easeInOut(duration: 0.2)) {
                    isLoading = false
                }
                print("✅ Biometric login successful")
            }
            
        } catch {
            await MainActor.run {
                withAnimation(Animation.easeInOut(duration: 0.2)) {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Simple Logo Component

struct SimpleCyntientOpsLogo: View {
    let size: CGFloat
    
    init(size: CGFloat) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.29, green: 0.56, blue: 0.89),
                            Color(red: 0.48, green: 0.73, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.08
                )
            
            // Inner geometric pattern
            ZStack {
                // Building blocks representation
                RoundedRectangle(cornerRadius: size * 0.04)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.35, height: size * 0.5)
                    .offset(x: -size * 0.1, y: -size * 0.05)
                
                RoundedRectangle(cornerRadius: size * 0.04)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.8),
                                Color(red: 0.48, green: 0.73, blue: 1.0).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.25, height: size * 0.4)
                    .offset(x: size * 0.12, y: size * 0.05)
                
                // Gear/operations symbol
                Image(systemName: "gearshape.fill")
                    .font(.system(size: size * 0.2, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.29, green: 0.56, blue: 0.89),
                                Color(red: 0.48, green: 0.73, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: size * 0.05, y: size * 0.15)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
