//
//  AdminDashboardHeader.swift
//  CyntientOps Phase 4
//
//  Admin Dashboard Header - Fixed height 80px
//  Shows admin name, key metrics, and system status
//

import SwiftUI

struct AdminDashboardHeader: View {
    let adminName: String
    let totalBuildings: Int
    let activeWorkers: Int
    let criticalAlerts: Int
    let syncStatus: CoreTypes.DashboardSyncStatus
    let onProfileTap: () -> Void
    let onNovaTap: () -> Void
    
    private var syncStatusColor: Color {
        switch syncStatus {
        case .syncing: return .orange
        case .synced: return .green
        case .error: return .red
        case .failed: return .red
        case .offline: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: CyntientOps logo
            CyntientOpsLogo(size: .compact)

            Spacer()

            // Center: Nova avatar (persistent)
            NovaAvatar(
                size: .persistent,
                isActive: false,
                hasUrgentInsights: false,
                isBusy: false,
                onTap: onNovaTap,
                onLongPress: { onNovaTap() }
            )

            Spacer()

            // Right: Admin pill
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                        .overlay(Text(initials(from: adminName)).font(.caption).foregroundColor(.white))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

private func initials(from name: String) -> String {
    let parts = name.split(separator: " ")
    let first = parts.first?.prefix(1) ?? "A"
    let last = parts.dropFirst().first?.prefix(1) ?? ""
    return String(first + last)
}
