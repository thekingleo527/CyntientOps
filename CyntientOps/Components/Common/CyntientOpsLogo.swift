//
//  CyntientOpsLogo.swift
//  CyntientOps
//
//  Custom logo component matching brand colors and dark theme
//

import SwiftUI

// Renamed to avoid conflict with the header's logo component
struct CyntientOpsBrandLogo: View {
    let size: CGFloat
    let style: LogoStyle
    
    enum LogoStyle {
        case full // Logo + text
        case iconOnly // Just the symbol
        case minimal // Simple variant
    }
    
    init(size: CGFloat = 32, style: LogoStyle = .iconOnly) {
        self.size = size
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .iconOnly:
            iconOnlyLogo
        case .full:
            fullLogo
        case .minimal:
            minimalLogo
        }
    }
    
    private var iconOnlyLogo: some View {
        ZStack {
            // Outer ring - brand blue
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
            
            // Inner symbol - stylized "C"
            Path { path in
                let center = CGPoint(x: size/2, y: size/2)
                let radius = size * 0.25
                
                // Create a stylized "C" shape
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(45),
                    endAngle: .degrees(315),
                    clockwise: false
                )
            }
            .stroke(
                LinearGradient(
                    colors: [.white, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            
            // Central dot for tech/precision feel
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.15, height: size * 0.15)
        }
    }
    
    private var fullLogo: some View {
        HStack(spacing: 8) {
            iconOnlyLogo
            
            if size >= 24 {
                VStack(alignment: .leading, spacing: 0) {
                    Text("CyntientOps")
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    if size >= 40 {
                        Text("Operations Platform")
                            .font(.system(size: size * 0.2, weight: .medium, design: .rounded))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
        }
    }
    
    private var minimalLogo: some View {
        ZStack {
            // Simple geometric shape
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(
                    LinearGradient(
                        colors: [
                            .blue.opacity(0.8),
                            .cyan.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // "CO" monogram
            Text("CO")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
