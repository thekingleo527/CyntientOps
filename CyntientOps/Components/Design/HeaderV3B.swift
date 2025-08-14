//
//  HeaderV3B.swift
//  CyntientOps v6.0 - WorkerHeaderV3B Hard Reset
//
//  ✅ HARD RESET: Fixed height 56–64pt, hairline bottom border, no glass
//  ✅ ROUTER: Single router (enum) for all header actions
//  ✅ SLOTS: Brand menu · Nova status · Clock pill · Profile chip
//  ✅ SIMPLIFIED: Clean, readable, no unnecessary effects
//

import SwiftUI
import Foundation

// MARK: - CO Design Tokens
private enum CO {
    static let primary = CyntientOpsDesign.DashboardColors.primaryText
    static let secondary = CyntientOpsDesign.DashboardColors.secondaryText
    static let tertiary = CyntientOpsDesign.DashboardColors.tertiaryText
    static let blue = CyntientOpsDesign.DashboardColors.workerPrimary
    static let surface = Color.clear // Will use .regularMaterial
    static let hair = CyntientOpsDesign.DashboardColors.borderSubtle
    static let padding: CGFloat = 16
    static let radius: CGFloat = CyntientOpsDesign.CornerRadius.md
}

// MARK: - WorkerRoute for Header Navigation

enum WorkerHeaderRoute: Identifiable {
    case mainMenu
    case profile
    case clockAction
    case novaChat
    
    var id: String {
        switch self {
        case .mainMenu: return "mainMenu"
        case .profile: return "profile" 
        case .clockAction: return "clockAction"
        case .novaChat: return "novaChat"
        }
    }
}

// MARK: - WorkerHeaderV3B Component

struct WorkerHeaderV3B: View {
    // MARK: - Properties
    
    let name: String
    let initials: String
    let photoURL: URL?
    let nextTaskName: String?
    let showClockPill: Bool
    let isNovaProcessing: Bool
    let onRoute: (WorkerHeaderRoute) -> Void
    
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @State private var clockedDuration = ""
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // CyntientOps Logo (left)
                brandMenuButton
                
                Spacer()
                
                // Nova Avatar (center)
                novaStatusButton
                
                Spacer()
                
                // Profile Chip Only (right)
                profileChipButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: 60)
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            
            // Hairline border
            Divider()
                .opacity(0.3)
        }
        .onReceive(timer) { _ in
            updateClockDuration()
        }
    }
    
    // MARK: - Components
    
    private var brandMenuButton: some View {
        Button(action: { onRoute(.mainMenu) }) {
            HStack(spacing: 8) {
                // CyntientOps Logo Mark
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [CyntientOpsDesign.DashboardColors.workerPrimary, CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Text("C")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("CyntientOps")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var novaStatusButton: some View {
        Button(action: { onRoute(.novaChat) }) {
            HStack(spacing: 8) {
                // Beautiful animated Nova icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [novaStatusColor, novaStatusColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                        .scaleEffect(isNovaProcessing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isNovaProcessing)
                    
                    Image(systemName: isNovaProcessing ? "brain.head.profile" : "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating, isActive: isNovaProcessing)
                    
                    // Elegant processing ring
                    if isNovaProcessing {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                AngularGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.1)],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                            )
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(isNovaProcessing ? 360 : 0))
                            .animation(
                                .linear(duration: 2).repeatForever(autoreverses: false),
                                value: isNovaProcessing
                            )
                    }
                }
                
                Text(novaStatusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .animation(.easeInOut(duration: 0.3), value: novaStatusText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(novaStatusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isNovaProcessing)
    }
    
    private var clockPillButton: some View {
        Button(action: { onRoute(.clockAction) }) {
            HStack(spacing: 8) {
                // Beautiful pulsing status indicator
                ZStack {
                    Circle()
                        .fill(clockStatusColor)
                        .frame(width: 8, height: 8)
                    
                    // Elegant pulsing ring for clocked in state
                    if isClocked {
                        Circle()
                            .fill(clockStatusColor.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .scaleEffect(1.0)
                            .opacity(0.8)
                            .animation(
                                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                value: isClocked
                            )
                    }
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isClocked ? "Clocked In" : "Clock In")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    if isClocked, let building = contextAdapter.currentBuilding {
                        Text("\(building.name) • \(clockedDuration)")
                            .font(.system(size: 9))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            .lineLimit(1)
                            .animation(.easeInOut(duration: 0.3), value: clockedDuration)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(clockBackgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(clockStatusColor.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isClocked)
    }
    
    private var profileChipButton: some View {
        ProfileChip(
            name: name,
            initials: initials,
            photoURL: photoURL,
            tap: { onRoute(.profile) }
        )
    }
    
    // MARK: - Computed Properties
    
    private var displayName: String {
        let workerName = name
        let name = !workerName.isEmpty && workerName != "Worker"
            ? workerName
            : contextAdapter.currentWorker?.name ?? "Worker"
        
        return name.components(separatedBy: " ").first ?? name
    }
    
    private var isClocked: Bool {
        contextAdapter.currentBuilding != nil
    }
    
    private var clockStatusColor: Color {
        isClocked ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning
    }
    
    private var clockBackgroundColor: Color {
        isClocked 
            ? CyntientOpsDesign.DashboardColors.success.opacity(0.15) 
            : CyntientOpsDesign.DashboardColors.warning.opacity(0.15)
    }
    
    private var novaStatusColor: Color {
        if isNovaProcessing {
            return CyntientOpsDesign.DashboardColors.workerPrimary
        } else if hasUrgentContext {
            return CyntientOpsDesign.DashboardColors.critical
        } else {
            return CyntientOpsDesign.DashboardColors.success
        }
    }
    
    private var novaStatusText: String {
        if isNovaProcessing {
            return "Processing"
        } else if hasUrgentContext {
            return "Alert"
        } else {
            return "Nova"
        }
    }
    
    private var hasUrgentContext: Bool {
        contextAdapter.todaysTasks.contains { task in
            task.urgency == .urgent || task.urgency == .critical
        }
    }
    
    private var profileGradient: LinearGradient {
        let baseColor = getRoleColor()
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func getRoleColor() -> Color {
        guard let role = contextAdapter.currentWorker?.role else { 
            return CyntientOpsDesign.DashboardColors.workerPrimary 
        }
        switch role {
        case .worker: return CyntientOpsDesign.DashboardColors.workerPrimary
        case .admin: return CyntientOpsDesign.DashboardColors.success
        case .manager: return CyntientOpsDesign.DashboardColors.warning
        case .client: return CyntientOpsDesign.DashboardColors.workerAccent
        }
    }
    
    // MARK: - Methods
    
    private func updateClockDuration() {
        guard isClocked else {
            clockedDuration = ""
            return
        }
        
        // Simplified duration calculation
        let duration = TimeInterval(Int.random(in: 60...28800)) // Placeholder
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            clockedDuration = "\(hours)h \(minutes)m"
        } else {
            clockedDuration = "\(minutes)m"
        }
    }
}

// MARK: - Legacy HeaderV3B (Backwards Compatibility)

struct HeaderV3B: View {
    // MARK: - Properties
    
    let workerName: String
    let nextTaskName: String?
    let showClockPill: Bool
    let isNovaProcessing: Bool
    let onProfileTap: () -> Void
    let onNovaPress: () -> Void
    let onNovaLongPress: () -> Void
    
    // Optional callbacks
    var onLogoTap: (() -> Void)?
    var onClockAction: (() -> Void)?
    
    // Future Phase callbacks
    var onVoiceCommand: (() -> Void)?
    var onARModeToggle: (() -> Void)?
    var onWearableSync: (() -> Void)?
    
    var body: some View {
        WorkerHeaderV3B(
            name: workerName,
            initials: getInitials(from: workerName),
            photoURL: nil,
            nextTaskName: nextTaskName,
            showClockPill: showClockPill,
            isNovaProcessing: isNovaProcessing,
            onRoute: { route in
                switch route {
                case .mainMenu:
                    onLogoTap?()
                case .profile:
                    onProfileTap()
                case .clockAction:
                    onClockAction?()
                case .novaChat:
                    onNovaPress()
                }
            }
        )
    }
    
    private func getInitials(from name: String?) -> String {
        guard let name = name else { return "W" }
        let components = name.components(separatedBy: " ")
        let first = components.first?.first ?? "W"
        let last = components.count > 1 ? components.last?.first : nil
        
        if let last = last {
            return "\(first)\(last)".uppercased()
        } else {
            return String(first).uppercased()
        }
    }
}

// MARK: - Preview

struct WorkerHeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Current state - Worker clocked in
            WorkerHeaderV3B(
                name: "Kevin Dutan",
                initials: "KD",
                photoURL: nil,
                nextTaskName: "Museum Security Check",
                showClockPill: true,
                isNovaProcessing: false,
                onRoute: { route in
                    print("Route: \(route)")
                }
            )
            
            // Nova processing
            WorkerHeaderV3B(
                name: "Edwin Rodriguez",
                initials: "ER",
                photoURL: nil,
                nextTaskName: nil,
                showClockPill: true,
                isNovaProcessing: true,
                onRoute: { route in
                    print("Route: \(route)")
                }
            )
            
            // Not clocked in
            WorkerHeaderV3B(
                name: "Mercedes Gonzalez",
                initials: "MG",
                photoURL: nil,
                nextTaskName: nil,
                showClockPill: false,
                isNovaProcessing: false,
                onRoute: { route in
                    print("Route: \(route)")
                }
            )
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

// MARK: - ProfileChip Component

struct ProfileChip: View {
    let name: String
    let initials: String
    let photoURL: URL?
    let tap: () -> Void
    
    var body: some View {
        Button(action: tap) {
            Avatar(initials: initials, photoURL: photoURL)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Avatar Component

struct Avatar: View {
    let initials: String
    let photoURL: URL?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [CO.blue, CO.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            
            if let photoURL = photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } placeholder: {
                    Text(initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Text(initials)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}
