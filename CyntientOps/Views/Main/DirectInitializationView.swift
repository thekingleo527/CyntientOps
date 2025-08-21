//
//  DirectInitializationView.swift
//  CyntientOps
//
//  🎯 SIMPLIFIED INITIALIZATION UI: Shows real-world data loading progress
//  ✅ CLEAN: No complex migration UI - just direct data loading
//  ✅ PRODUCTION READY: Connects to DirectDataInitializer
//

import SwiftUI

public struct DirectInitializationView: View {
    @EnvironmentObject private var initializer: DirectDataInitializer
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // Dark background
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
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .scaleEffect(animateIcon ? 1.2 : 0.8)
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                }
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)
                
                // Title
                Text("Loading Real-World Data")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Status Message
                Text(initializer.statusMessage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.3), value: initializer.statusMessage)
                
                // Progress
                VStack(spacing: 16) {
                    ProgressView(value: initializer.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .scaleEffect(y: 2.0)
                        .padding(.horizontal, 60)
                    
                    Text("\(Int(initializer.progress * 100))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Error Handling
                if let error = initializer.error {
                    VStack(spacing: 12) {
                        Text("Initialization Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Retry") {
                            Task {
                                try? await initializer.initializeIfNeeded()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                // Data Source Info
                VStack(spacing: 8) {
                    Text("Loading from:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 16) {
                        Label("OperationalDataManager", systemImage: "building.2")
                        Label("NYC APIs", systemImage: "network")
                        Label("Real Buildings", systemImage: "location")
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
            .onAppear {
                withAnimation {
                    animateIcon = true
                }
            }
        }
    }
}

#Preview {
    DirectInitializationView()
        .environmentObject(DirectDataInitializer())
}