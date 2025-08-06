//
//  NovaAdminIntelligenceBar.swift
//  CyntientOps Phase 4
//
//  Nova Intelligence Bar for Admin Dashboard
//  Provides AI-powered portfolio insights and management assistance
//

import SwiftUI

struct NovaAdminIntelligenceBar: View {
    let container: ServiceContainer
    let adminContext: [String: Any]
    
    @State private var isExpanded = false
    @State private var currentInsight: String = "Analyzing portfolio performance..."
    @State private var animationPhase = 0
    
    @StateObject private var novaManager = NovaAIManager.shared
    
    private let adminInsights = [
        "Building efficiency up 12% this week",
        "3 workers ahead of daily targets",
        "Photo compliance at 94% - excellent",
        "Recommend redistributing tasks at Grand Elizabeth",
        "Weather impact minimal today"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Content
                expandedAdminContent
                    .frame(height: 280)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.95),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Collapsed Bar
            collapsedAdminBar
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.blue.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.blue.opacity(0.3)),
                    alignment: .top
                )
        }
        .onAppear {
            startAdminInsightRotation()
        }
    }
    
    private var collapsedAdminBar: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Nova Admin Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .scaleEffect(novaManager.isThinking ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: novaManager.isThinking)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Current Admin Insight
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nova AI • Portfolio Intelligence")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text(currentInsight)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.3), value: currentInsight)
                }
                
                Spacer()
                
                // Admin-specific indicators
                HStack(spacing: 8) {
                    // Portfolio health indicator
                    if let completion = adminContext["portfolioCompletion"] as? String {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            
                            Text(completion)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Alert count
                    if let alerts = adminContext["criticalAlerts"] as? Int, alerts > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                            
                            Text("\(alerts)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var expandedAdminContent: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    Text("Nova Portfolio Intelligence")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Monitoring")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Admin Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NovaAdminInsightCard(
                    title: "Portfolio Health",
                    value: adminContext["portfolioCompletion"] as? String ?? "78%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    subtitle: "Overall completion rate"
                )
                
                NovaAdminInsightCard(
                    title: "Worker Efficiency",
                    value: "\(adminContext["activeWorkers"] as? Int ?? 5)/\(adminContext["totalWorkers"] as? Int ?? 7)",
                    icon: "person.3.fill",
                    color: .blue,
                    subtitle: "Active workforce"
                )
                
                NovaAdminInsightCard(
                    title: "Compliance Score",
                    value: "\(Int((adminContext["complianceScore"] as? Double ?? 0.85) * 100))%",
                    icon: "shield.checkered",
                    color: .cyan,
                    subtitle: "Photo compliance"
                )
                
                if let alerts = adminContext["criticalAlerts"] as? Int, alerts > 0 {
                    NovaAdminInsightCard(
                        title: "Critical Alerts",
                        value: "\(alerts)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        subtitle: "Require attention"
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                        Text("Ask Nova")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14))
                        Text("Optimize")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    private func startAdminInsightRotation() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsight = adminInsights.randomElement() ?? adminInsights[0]
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct NovaAdminInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(color.opacity(0.6))
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
struct NovaAdminIntelligenceBar_Previews: PreviewProvider {
    static var previews: some View {
        Text("NovaAdminIntelligenceBar Preview")
            .foregroundColor(.white)
        /*
        VStack {
            Spacer()
            
            NovaAdminIntelligenceBar(
                container: ServiceContainer(),
                adminContext: [
                    "adminName": "Sarah Martinez",
                    "totalBuildings": 16,
                    "activeWorkers": 5,
                    "totalWorkers": 7,
                    "portfolioCompletion": "78%",
                    "complianceScore": 0.94,
                    "criticalAlerts": 2
                ]
            )
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        */
    }
}
#endif