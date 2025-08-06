//
//  NovaIntelligenceBar.swift
//  CyntientOps Phase 4
//
//  Nova Intelligence Bar - Expands from 60px to 300px
//  Provides AI-powered insights and assistance
//

import SwiftUI

struct NovaIntelligenceBar: View {
    let container: ServiceContainer
    let workerId: String?
    let currentContext: [String: Any]
    
    @State private var isExpanded = false
    @State private var currentInsight: String = "Nova is analyzing your performance..."
    @State private var animationPhase = 0
    
    // Nova AI Manager reference
    @StateObject private var novaManager = NovaAIManager.shared
    
    private let insights = [
        "You're ahead of schedule on 3 tasks today",
        "Photo required for sanitation tasks",
        "Rubin Museum prefers morning cleanings",
        "Consider batching tasks by floor level",
        "Weather alert: Indoor tasks recommended"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Content
                expandedContent
                    .frame(height: 240)
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
            
            // Collapsed Bar (always visible)
            collapsedBar
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
            startInsightRotation()
        }
    }
    
    private var collapsedBar: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Nova AI Icon with animation
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
                    
                    Image(systemName: "brain")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Current Insight
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nova AI")
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
                
                // Expand/Collapse Indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue.opacity(animationPhase == index ? 1.0 : 0.3))
                            .frame(width: 4, height: 4)
                            .scaleEffect(animationPhase == index ? 1.2 : 1.0)
                    }
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: animationPhase)
                    
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
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            // Nova Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    Text("Nova Intelligence")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    NovaInsightCard(
                        insight: insight,
                        index: index,
                        isActive: index < 2
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Action Buttons
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
                        Image(systemName: "lightbulb")
                            .font(.system(size: 14))
                        Text("Get Suggestion")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
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
    
    private func startInsightRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsight = insights.randomElement() ?? insights[0]
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct NovaInsightCard: View {
    let insight: String
    let index: Int
    let isActive: Bool
    
    var cardColor: Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        case 3: return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(cardColor)
                    .frame(width: 8, height: 8)
                
                Spacer()
                
                if isActive {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(cardColor)
                }
            }
            
            Text(insight)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isActive ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cardColor.opacity(isActive ? 0.5 : 0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isActive ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

#if DEBUG
struct NovaIntelligenceBar_Previews: PreviewProvider {
    static var previews: some View {
        Text("NovaIntelligenceBar Preview")
            .foregroundColor(.white)
        /*
        VStack {
            Spacer()
            
            // Collapsed state
            NovaIntelligenceBar(
                container: ServiceContainer(),
                workerId: "4",
                currentContext: [
                    "workerId": "4",
                    "workerName": "Kevin Dutan",
                    "totalTasks": 38,
                    "completedTasks": 16
                ]
            )
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        */
    }
}
#endif