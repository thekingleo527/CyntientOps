//
//  GlassDeckContainer.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Animation syntax errors resolved (AnimationAnimation → Animation)
//  ✅ FIXED: GlassIntensity .light → .thin
//  ✅ ALIGNED: Updated for v6.0 architecture with proper SwiftUI patterns
//  ✅ OPTIMIZED: Glass deck system for three-dashboard experience
//

import SwiftUI

// MARK: - Glass Deck Container
struct GlassDeckContainer<Content: View>: View {
    let content: Content
    let intensity: GlassIntensity
    let spacing: CGFloat
    let animateOnAppear: Bool
    
    @State private var isVisible = false
    @State private var cardOffsets: [CGFloat] = []
    @State private var deckExpanded = false
    
    // MARK: - Animation Properties
    private let staggerDelay: Double = 0.1
    private let stackOffset: CGFloat = 8
    private let maxCards: Int = 5
    
    init(
        intensity: GlassIntensity = .regular,
        spacing: CGFloat = 16,
        animateOnAppear: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.spacing = spacing
        self.animateOnAppear = animateOnAppear
    }
    
    var body: some View {
        ZStack {
            // Background cards for depth effect
            if deckExpanded {
                ForEach(0..<min(maxCards, 3), id: \.self) { index in
                    backgroundCard(at: index)
                }
            }
            
            // Main content container
            mainContentCard
        }
        .onAppear {
            setupInitialState()
            if animateOnAppear {
                animateAppearance()
            }
        }
        .onTapGesture {
            toggleDeckExpansion()
        }
    }
    
    // MARK: - Card Components
    private var mainContentCard: some View {
        GlassCard(intensity: intensity) {
            content
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .zIndex(10)
    }
    
    private func backgroundCard(at index: Int) -> some View {
        GlassCard(intensity: .thin) {  // ✅ FIXED: .light → .thin
            Rectangle()
                .fill(Color.clear)
                .frame(height: 80)
        }
        .offset(
            x: CGFloat(index) * stackOffset,
            y: -CGFloat(index) * stackOffset
        )
        .scaleEffect(1.0 - (CGFloat(index) * 0.05))
        .opacity(0.6 - (Double(index) * 0.15))
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * staggerDelay), value: deckExpanded)
        .zIndex(Double(maxCards - index))
    }
    
    // MARK: - Animation Methods
    private func setupInitialState() {
        isVisible = false
        deckExpanded = false
        cardOffsets = Array(repeating: 0, count: maxCards)
    }
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            isVisible = true
        }
    }
    
    private func toggleDeckExpansion() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            deckExpanded.toggle()
        }
    }
}

// MARK: - Staggered Deck Animation
struct StaggeredDeckAnimation: View {
    let cardCount: Int
    let content: (Int) -> AnyView
    
    @State private var visibleCards: Set<Int> = []
    @State private var isAnimating = false
    
    private let staggerDelay: Double = 0.15
    private let animationDuration: Double = 0.6
    
    var body: some View {
        ZStack {
            ForEach(0..<cardCount, id: \.self) { index in
                content(index)
                    .scaleEffect(visibleCards.contains(index) ? 1.0 : 0.8)
                    .opacity(visibleCards.contains(index) ? 1.0 : 0.0)
                    .animation(
                        .spring(response: animationDuration, dampingFraction: 0.8)
                            .delay(Double(index) * staggerDelay),
                        value: visibleCards.contains(index)
                    )
                    .zIndex(Double(cardCount - index))
            }
        }
        .onAppear {
            startStaggeredAnimation()
        }
    }
    
    private func startStaggeredAnimation() {
        isAnimating = true
        
        for index in 0..<cardCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * staggerDelay) {
                visibleCards.insert(index)
            }
        }
    }
}

// MARK: - Deck Interaction Modifiers
extension View {
    func glassDeckContainer(
        intensity: GlassIntensity = .regular,
        spacing: CGFloat = 16,
        animateOnAppear: Bool = true
    ) -> some View {
        GlassDeckContainer(
            intensity: intensity,
            spacing: spacing,
            animateOnAppear: animateOnAppear
        ) {
            self
        }
    }
}

// MARK: - Preview Support
#if DEBUG
struct GlassDeckContainer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GlassDeckContainer {
                VStack {
                    Text("Main Card Content")
                        .font(.headline)
                    Text("Tap to expand deck")
                        .font(.caption)
                        .opacity(0.7)
                }
                .padding()
            }
            
            Text("Other UI Elements")
                .font(.title2)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
#endif
