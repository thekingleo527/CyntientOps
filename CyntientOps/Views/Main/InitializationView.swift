//
//  InitializationView.swift
//  CyntientOps
//
//  Simple initialization view with logo and spinner
//  Should only appear briefly during app startup
//

import SwiftUI

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
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
                
                // Error message or spinner
                if let error = viewModel.initializationError {
                    VStack(spacing: 15) {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task { await viewModel.retryInitialization() }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8)
                    }
                } else if viewModel.isInitializing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .onAppear {
            animateLogo()
            startInitialization()
        }
    }
    
    // MARK: - Helper Methods
    
    private func animateLogo() {
        withAnimation(.easeOut(duration: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
    }
    
    private func startInitialization() {
        Task {
            await viewModel.startInitialization()
        }
    }
}

#Preview {
    InitializationView(viewModel: InitializationViewModel())
}
