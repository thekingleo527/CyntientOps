////
//  ForgotPasswordView.swift
//  CyntientOps
//
//  ✅ FIXED: withAnimation syntax errors resolved
//  ✅ FIXED: Missing closing parentheses in animation calls
//  ✅ FIXED: Malformed closure expressions
//  Glassmorphism-enhanced password reset view
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Form state
    @State private var email = ""
    @State private var message: String?
    @State private var isSuccess = false
    @State private var isLoading = false
    
    // Animation states
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0
    @State private var successScale: CGFloat = 0.8
    @State private var successOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient (matching other auth views)
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.25),
                        Color(red: 0.15, green: 0.2, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                        Color(red: 0.48, green: 0.73, blue: 1.0).opacity(0.2)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
            }
            
            // Main content
            VStack {
                // Glass navigation header
                GlassCard(intensity: GlassIntensity.ultraThin, cornerRadius: 0, padding: 0) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Back")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Reset Password")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Balance spacer
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                if !isSuccess {
                    // Reset form content
                    ScrollView {
                        VStack(spacing: 32) {
                            // Logo section
                            VStack(spacing: 20) {
                                ZStack {
                                    // Glass backing
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 90, height: 90)
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
                                        .shadow(color: Color.black.opacity(0.3), radius: 15, y: 8)
                                    
                                    // Icon for password reset
                                    ZStack {
                                        SimpleCyntientOpsLogo(size: 60)
                                            .opacity(0.3)
                                        
                                        Image(systemName: "lock.rotation")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .scaleEffect(logoScale)
                                .opacity(logoOpacity)
                                
                                VStack(spacing: 8) {
                                    Text("Forgot Your Password?")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Enter your email and we'll send you\na link to reset your password")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 40)
                            .onAppear {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                                    logoScale = 1.0
                                    logoOpacity = 1.0
                                }
                            }
                            
                            // Form card
                            GlassCard(intensity: GlassIntensity.regular, cornerRadius: 24) {
                                VStack(spacing: 20) {
                                    // Email field
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Email Address")
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
                                        
                                        Text("We'll send password reset instructions to this email")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.top, 4)
                                    }
                                    
                                    // Error/Status message
                                    if let message = message, !isSuccess {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption)
                                            
                                            Text(message)
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
                                    
                                    // Submit button - FIXED PARAMETER ORDER
                                    GlassButton(
                                        isLoading ? "Sending..." : "Send Reset Link",
                                        style: .primary,
                                        size: .large,
                                        isFullWidth: true,
                                        isDisabled: email.isEmpty,
                                        isLoading: isLoading
                                    ) {
                                        sendResetLink()
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal, 24)
                            .offset(y: contentOffset)
                            .opacity(contentOpacity)
                            .onAppear {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                                    contentOffset = 0
                                    contentOpacity = 1
                                }
                            }
                            
                            // Additional help text
                            VStack(spacing: 16) {
                                Text("Remember your password?")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.left.circle.fill")
                                            .font(.system(size: 16))
                                        
                                        Text("Back to Login")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.top, 20)
                            .opacity(contentOpacity)
                        }
                        .padding(.bottom, 40)
                    }
                } else {
                    // Success view
                    SuccessView
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Success View
    
    private var SuccessView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Success icon with animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .scaleEffect(successScale * 1.2)
                    
                    // Glass circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 20, y: 10)
                    
                    // Check icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .scaleEffect(successScale)
                .opacity(successOpacity)
                
                // Success message
                VStack(spacing: 12) {
                    Text("Check Your Email")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("We've sent password reset\ninstructions to:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text(email)
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .opacity(successOpacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    successScale = 1.0
                    successOpacity = 1.0
                }
            }
            
            Spacer()
            
            // Return to login button
            GlassCard(intensity: GlassIntensity.thin, cornerRadius: 20, padding: 0) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Return to Login")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 24)
            .opacity(successOpacity)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Helper Methods
    
    private func sendResetLink() {
        // ✅ FIXED: Proper withAnimation syntax with closing parenthesis
        withAnimation(.easeInOut(duration: 0.2)) {
            message = nil
        }
        
        // Validate email
        guard !email.isEmpty else {
            withAnimation(.spring()) {
                message = "Please enter your email address"
            }
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            withAnimation(.spring()) {
                message = "Please enter a valid email address"
            }
            return
        }
        
        // ✅ FIXED: Proper withAnimation syntax
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
        }
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // ✅ FIXED: Proper withAnimation syntax
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
            }
            
            // Check if email exists (simulation)
            let knownEmails = [
                "g.hutson1989@gmail.com",
                "edwinlema911@gmail.com",
                "dutankevin1@gmail.com",
                "francosphere@francomanagementgroup.com",
                "shawn@fme-llc.com"
            ]
            
            if knownEmails.contains(email.lowercased()) || email.contains("@francosphere.com") {
                // Success
                withAnimation(.spring()) {
                    isSuccess = true
                }
                
                // Auto-dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                // Error - email not found
                withAnimation(.spring()) {
                    message = "No account found with this email address"
                }
            }
        }
    }
    
    // MARK: - Supporting Components
    
    struct GlassInfoCard: View {
        let icon: String
        let title: String
        let message: String
        let iconColor: Color
        
        var body: some View {
            GlassCard(intensity: GlassIntensity.thin, cornerRadius: 16) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .preferredColorScheme(.dark)
    }
}
