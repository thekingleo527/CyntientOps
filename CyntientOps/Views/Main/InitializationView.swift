//
//  InitializationView.swift
//  CyntientOps
//
//  Database initialization screen shown on first launch
//

import SwiftUI

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App icon and title
                VStack(spacing: 16) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("CyntientOps")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Setting up your workspace...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Progress section
                VStack(spacing: 16) {
                    if viewModel.isInitializing {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(maxWidth: 200)
                        
                        Text(viewModel.statusMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else if let error = viewModel.error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            
                            Text("Initialization Failed")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(error.localizedDescription)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                Task {
                                    await viewModel.retry()
                                }
                            }
                            .buttonStyle(RetryButtonStyle())
                        }
                    } else if viewModel.isComplete {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                            
                            Text("Ready to go!")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    } else {
                        // Initial state
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("Preparing...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Footer
                Text("This may take a few moments")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 60)
        }
    }
}

struct RetryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

