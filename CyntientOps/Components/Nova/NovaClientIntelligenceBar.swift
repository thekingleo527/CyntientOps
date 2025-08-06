//
//  NovaClientIntelligenceBar.swift
//  CyntientOps Phase 4
//
//  Nova Intelligence Bar for Client Dashboard
//  Provides AI-powered portfolio insights and cost optimization
//

import SwiftUI

struct NovaClientIntelligenceBar: View {
    let container: ServiceContainer
    let clientContext: [String: Any]
    
    @State private var isExpanded = false
    @State private var currentInsight: String = "Analyzing portfolio performance..."
    @State private var animationPhase = 0
    
    @StateObject private var novaManager = NovaAIManager.shared
    
    private let clientInsights = [
        "Portfolio performance up 8% this quarter",
        "Cost savings opportunity: $12K/month identified",
        "Compliance score excellent at 94%",
        "Building efficiency optimized across 9 properties",
        "Recommend energy audit for additional savings"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Client Content
                expandedClientContent
                    .frame(height: 280)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.95),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Collapsed Bar
            collapsedClientBar
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.purple.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.purple.opacity(0.3)),
                    alignment: .top
                )
        }
        .onAppear {
            startClientInsightRotation()
        }
    }
    
    private var collapsedClientBar: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Nova Client Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .scaleEffect(novaManager.isThinking ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: novaManager.isThinking)
                    
                    Image(systemName: "brain.filled.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Current Client Insight
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nova AI • Portfolio Intelligence")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    
                    Text(currentInsight)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.3), value: currentInsight)
                }
                
                Spacer()
                
                // Client-specific indicators
                HStack(spacing: 8) {
                    // Cost savings indicator
                    if let savings = clientContext["estimatedSavings"] as? Double, savings > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            
                            Text("$\(Int(savings/1000))K")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Portfolio health
                    if let health = clientContext["portfolioHealth"] as? Double {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            
                            Text("\(Int(health * 100))%")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var expandedClientContent: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.filled.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                    
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
                    
                    Text("Optimizing")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Client Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NovaClientInsightCard(
                    title: "Portfolio Health",
                    value: "\(Int((clientContext["portfolioHealth"] as? Double ?? 0.85) * 100))%",
                    icon: "building.2.crop.circle",
                    color: .blue,
                    subtitle: "Overall performance"
                )
                
                NovaClientInsightCard(
                    title: "Cost Efficiency",
                    value: "$\(Int((clientContext["estimatedSavings"] as? Double ?? 0)/1000))K",
                    icon: "dollarsign.circle",
                    color: .green,
                    subtitle: "Monthly savings"
                )
                
                NovaClientInsightCard(
                    title: "Compliance Score",
                    value: "\(Int((clientContext["complianceScore"] as? Double ?? 0.94) * 100))%",
                    icon: "shield.checkered",
                    color: .cyan,
                    subtitle: "Regulatory status"
                )
                
                if let violations = clientContext["criticalViolations"] as? Int, violations > 0 {
                    NovaClientInsightCard(
                        title: "Critical Issues",
                        value: "\(violations)",
                        icon: "exclamationmark.triangle",
                        color: .red,
                        subtitle: "Need attention"
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
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 14))
                        Text("Cost Report")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.2))
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
    
    private func startClientInsightRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsight = clientInsights.randomElement() ?? clientInsights[0]
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct NovaClientInsightCard: View {
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
struct NovaClientIntelligenceBar_Previews: PreviewProvider {
    static var previews: some View {
        Text("NovaClientIntelligenceBar Preview")
            .foregroundColor(.white)
        /*
        VStack {
            Spacer()
            
            NovaClientIntelligenceBar(
                container: ServiceContainer(),
                clientContext: [
                    "clientName": "JM Realty Group",
                    "totalBuildings": 9,
                    "portfolioHealth": 0.85,
                    "estimatedSavings": 12000.0,
                    "complianceScore": 0.94,
                    "criticalViolations": 1
                ]
            )
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        */
    }
}
#endif