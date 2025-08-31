//
//  SimpleSplashView.swift
//  CyntientOps
//
//  Simple splash screen for fast app startup
//  Replaces complex initialization progress view
//

import SwiftUI

struct SimpleSplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Simple black background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .blue.opacity(0.5), radius: 20)
                
                // App name
                Text("CyntientOps")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)
                
                // Simple spinner
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            animateLogo()
        }
    }
    
    private func animateLogo() {
        withAnimation(.easeOut(duration: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
            isAnimating = true
        }
    }
}

#Preview {
    SimpleSplashView()
}