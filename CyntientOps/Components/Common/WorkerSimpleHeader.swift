//
//  WorkerSimpleHeader.swift
//  CyntientOps v6.0
//
//  Simple header for WorkerDashboard refactor with user-requested layout:
//  CyntientOps Logo -- Nova Button -- WorkerProfile/ClockIn
//  Replaces complex HeaderV3B with clean, focused design
//

import SwiftUI
import CoreLocation

struct WorkerSimpleHeader: View {
    let workerName: String
    let workerId: String
    let isNovaProcessing: Bool
    let clockInStatus: ClockInStatus
    
    // Action callbacks
    let onLogoTap: () -> Void
    let onNovaPress: () -> Void
    let onProfileTap: () -> Void
    let onClockAction: () -> Void
    
    enum ClockInStatus {
        case notClockedIn
        case clockedIn(building: String, time: Date)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // CyntientOps Logo (Left)
            Button(action: onLogoTap) {
                CyntientOpsLogo(size: .compact)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Nova Button (Center) - Using persistent size for always-available assistant
            NovaAvatar(
                size: .persistent,  // Optimized for persistent assistant evolution
                isActive: false,
                hasUrgentInsights: false,
                isBusy: isNovaProcessing,
                onTap: onNovaPress,
                onLongPress: { /* Quick Nova actions could be added here */ }
            )
            
            Spacer()
            
            // WorkerProfile/ClockIn (Right)
            HStack(spacing: 12) {
                // Worker Profile
                Button(action: onProfileTap) {
                    HStack(spacing: 8) {
                        // Worker avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.8), .gray.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(workerName.prefix(1).uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(workerName.split(separator: " ").first?.description ?? workerName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                .lineLimit(1)
                            
                            switch clockInStatus {
                            case .notClockedIn:
                                Text("Ready")
                                    .font(.system(size: 10))
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.inactive)
                            case .clockedIn(let building, let time):
                                Text(timeWorked(from: time))
                                    .font(.system(size: 10))
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Clock In/Out Action
                Button(action: onClockAction) {
                    HStack(spacing: 6) {
                        Image(systemName: clockIcon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(clockColor)
                        
                        Text(clockText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(clockColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(clockColor.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(clockColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: 60)
        .background(
            CyntientOpsDesign.DashboardColors.cardBackground
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.borderColor.opacity(0.3)),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Clock Status Helpers
    
    private var clockIcon: String {
        switch clockInStatus {
        case .notClockedIn:
            return "clock"
        case .clockedIn:
            return "clock.fill"
        }
    }
    
    private var clockText: String {
        switch clockInStatus {
        case .notClockedIn:
            return "Clock In"
        case .clockedIn:
            return "Clock Out"
        }
    }
    
    private var clockColor: Color {
        switch clockInStatus {
        case .notClockedIn:
            return CyntientOpsDesign.DashboardColors.info
        case .clockedIn:
            return CyntientOpsDesign.DashboardColors.success
        }
    }
    
    private func timeWorked(from startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - CyntientOps Logo Component

struct CyntientOpsLogo: View {
    enum Size {
        case compact
        case standard
        
        var height: CGFloat {
            switch self {
            case .compact: return 32
            case .standard: return 40
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .compact: return 16
            case .standard: return 20
            }
        }
    }
    
    let size: Size
    
    var body: some View {
        HStack(spacing: 8) {
            // Logo mark
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.height, height: size.height)
                
                Text("C")
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Text
            Text("CyntientOps")
                .font(.system(size: size.fontSize - 2, weight: .semibold))
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct WorkerSimpleHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Not clocked in state
            WorkerSimpleHeader(
                workerName: "Kevin Dutan",
                workerId: "4",
                isNovaProcessing: false,
                clockInStatus: .notClockedIn,
                onLogoTap: { print("Logo tapped") },
                onNovaPress: { print("Nova pressed") },
                onProfileTap: { print("Profile tapped") },
                onClockAction: { print("Clock action") }
            )
            
            // Clocked in state
            WorkerSimpleHeader(
                workerName: "Mercedes Inamagua",
                workerId: "7",
                isNovaProcessing: true,
                clockInStatus: .clockedIn(building: "Rubin Museum", time: Date().addingTimeInterval(-7200)), // 2 hours ago
                onLogoTap: { print("Logo tapped") },
                onNovaPress: { print("Nova pressed") },
                onProfileTap: { print("Profile tapped") },
                onClockAction: { print("Clock action") }
            )
            
            Spacer()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
#endif