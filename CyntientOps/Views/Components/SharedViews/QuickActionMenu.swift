//  QuickActionMenu.swift
//  CyntientOps
//
//  A glass-styled contextual menu for Nova AI assistant quick actions
//  ✅ FIXED: Binding.constant usage in preview
//  ✅ FIXED: Changed @State to @Binding for proper parent-child communication
//  ✅ FIXED: Clean Nova integration without corruption
//

import SwiftUI
// CyntientOps Types Import
// (This comment helps identify our import)

// MARK: - Quick Action Types
enum QuickActionType: String, CaseIterable {
    case scanQR = "Scan QR/Text"
    case reportIssue = "Report Issue"
    case showMap = "Building Map"
    case askNova = "Ask Nova"
    case viewInsights = "AI Insights"
    
    var icon: String {
        switch self {
        case .scanQR: return "qrcode.viewfinder"
        case .reportIssue: return "exclamationmark.triangle.fill"
        case .showMap: return "map.fill"
        case .askNova: return "bubble.left.and.bubble.right.fill"
        case .viewInsights: return "brain"
        }
    }
    
    var color: Color {
        switch self {
        case .scanQR: return .blue
        case .reportIssue: return .orange
        case .showMap: return .green
        case .askNova: return .purple
        case .viewInsights: return .indigo
        }
    }
}

// MARK: - Quick Action Menu View
struct QuickActionMenu: View {
    // ✅ FIXED: Changed from @State to @Binding for proper parent-child communication
    @Binding var isPresented: Bool
    @State private var showNovaChat = false  // Nova integration
    let onActionSelected: (QuickActionType) -> Void
    
    @State private var animateIn = false
    @State private var selectedAction: QuickActionType?
    @Environment(\.colorScheme) var colorScheme
    
    // First 3 actions for the initial menu
    private let primaryActions: [QuickActionType] = [.scanQR, .reportIssue, .showMap]
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .opacity(animateIn ? 1 : 0)
                .onTapGesture {
                    dismissMenu()
                }
            
            // Floating menu
            VStack(spacing: 12) {
                // Menu items
                ForEach(primaryActions, id: \.self) { action in
                    quickActionButton(for: action)
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .opacity(animateIn ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(primaryActions.firstIndex(of: action) ?? 0) * 0.05),
                            value: animateIn
                        )
                }
                
                // Separator
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 20)
                    .opacity(animateIn ? 1 : 0)
                    .animation(Animation.easeInOut(duration: 0.3).delay(0.2), value: animateIn)
                
                // Ask Nova button (special)
                askNovaButton()
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(0.25),
                        value: animateIn
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 280)
            .offset(y: animateIn ? 0 : 20)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateIn = true
            }
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .sheet(isPresented: $showNovaChat) {
            NovaInteractionView()
        }
    }
    
    // MARK: - Action Button
    private func quickActionButton(for action: QuickActionType) -> some View {
        Button(action: {
            selectedAction = action
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onActionSelected(action)
                dismissMenu()
            }
        }) {
            HStack(spacing: 16) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(action.color)
                }
                
                // Label
                Text(action.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedAction == action ?
                         Color.white.opacity(0.1) :
                         Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Ask Nova Button (Special)
    private func askNovaButton() -> some View {
        Button(action: {
            selectedAction = .askNova
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showNovaChat = true
                dismissMenu()
            }
        }) {
            HStack(spacing: 16) {
                // Animated Nova icon
                ZStack {
                    // Gradient background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.blue.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    // Pulsing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 44, height: 44)
                        .scaleEffect(animateIn ? 1.2 : 1)
                        .opacity(animateIn ? 0 : 0.8)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: animateIn
                        )
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Label with gradient
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Nova AI")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Get instant help")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.1),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(0.3),
                                        Color.blue.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Dismiss
    private func dismissMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            animateIn = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Preview Provider
struct QuickActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Menu
            // ✅ FIXED: Now properly passes Binding to @Binding parameter
            QuickActionMenu(isPresented: .constant(true)) { action in
                print("Selected: \(action.rawValue)")
            }
        }
        .preferredColorScheme(.dark)
    }
}
